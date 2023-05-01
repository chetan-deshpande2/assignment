// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IMarketplace.sol";

contract BuyNFT is IMarketplace, Ownable, ReentrancyGuard {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    constructor(address _paymentTokenAddress) {
        _paymentToken = IERC20(_paymentTokenAddress);
    }

    IERC20 private immutable _paymentToken;

    bool private _isTradingEnabled = true;
    uint8 private _serviceFeeFraction = 20;
    uint256 private _actionTimeOutRangeMin = 1800; // 30 mins
    uint256 private _actionTimeOutRangeMax = 31536000; // One year - This can extend by owner is contract is working smoothly

    mapping(address => TrikonMarket) private _trikonMarket;

    /**
     * @dev only if listing and bid is enabled
     * This is to help contract migration in case of upgrading contract
     */
    modifier onlyTradingOpen() {
        require(_isTradingEnabled, "Listing and bid are not enabled");
        _;
    }

    /**
     * @dev only if the entered timestamp is within the allowed range
     * This helps to not list or bid for too short or too long period of time
     */
    modifier onlyAllowedExpireTimestamp(uint256 expireTimestamp) {
        require(
            expireTimestamp - block.timestamp >= _actionTimeOutRangeMin,
            "Please enter a longer period of time"
        );
        require(
            expireTimestamp - block.timestamp <= _actionTimeOutRangeMax,
            "Please enter a shorter period of time"
        );
        _;
    }

    /**
     * @dev See {TheeNFTMarketplace-listToken}.
     * The timestamp set needs to be in the allowed range
     * Listing must be valid
     */
    function listToken(
        address contractAddress,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        uint256 nftAmount,
        uint8 tokenType
    )
        external
        override
        onlyTradingOpen
        onlyAllowedExpireTimestamp(expireTimestamp)
    {
        Listing memory listing = Listing({
            tokenId: tokenId,
            value: value,
            seller: msg.sender,
            nftCount: nftAmount,
            tokenType: tokenType,
            expireTimestamp: expireTimestamp
        });

        // require(
        //     _isListingValid(contractAddress, listing),
        //     "Listing is not valid"
        // );

        _trikonMarket[contractAddress].listings[tokenId] = listing;
        _trikonMarket[contractAddress].tokenIdWithListing.add(tokenId);

        emit TokenListed(contractAddress, tokenId, listing);
    }

    /**
     * @dev See {TheeNFTMarketplace-delistToken}.
     * msg.sender must be the seller of the listing record
     */
    function delistToken(
        address contractAddress,
        uint256 tokenId
    ) external override {
        require(
            _trikonMarket[contractAddress].listings[tokenId].seller ==
                msg.sender,
            "Only token seller can delist token"
        );

        emit TokenDelisted(
            contractAddress,
            tokenId,
            _trikonMarket[contractAddress].listings[tokenId]
        );

        _delistToken(contractAddress, tokenId);
    }

    /**
     * @dev See {TheeNFTMarketplace-buyToken}.
     * Must have a valid listing
     * msg.sender must not the owner of token
     * msg.value must be at least sell price plus fees
     */
    function buyToken(
        address contractAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 tokenType,
        uint256 paymentTokenType
    ) external override nonReentrant {
        Listing memory listing = _trikonMarket[contractAddress].listings[
            tokenId
        ];
        require(
            _isListingValid(contractAddress, listing),
            "Token is not for sale"
        );
        require(
            !_isTokenOwner(contractAddress, tokenId, msg.sender, tokenType),
            "Token owner can't buy their own token"
        );

        _paymentToken.safeTransferFrom({
            from: msg.sender,
            to: listing.seller,
            value: listing.value
        });

        // Send token to buyer
        emit TokenBought({
            contractAddress: contractAddress,
            tokenId: tokenId,
            buyer: msg.sender,
            listing: listing
        });

        if (tokenType == 1) {
            IERC721(contractAddress).safeTransferFrom(
                listing.seller,
                msg.sender,
                tokenId
            );
        } else {
            IERC1155(contractAddress).safeTransferFrom(
                listing.seller,
                msg.sender,
                tokenId,
                listing.nftCount,
                "0x00"
            );
        }
        // Remove token listing
        _delistToken(contractAddress, tokenId);
    }

    /**
     * @dev delist a token - remove token id record and remove listing from mapping
     * @param tokenId erc721 token Id
     */
    function _delistToken(address contractAddress, uint256 tokenId) private {
        if (
            _trikonMarket[contractAddress].tokenIdWithListing.contains(tokenId)
        ) {
            delete _trikonMarket[contractAddress].listings[tokenId];
            _trikonMarket[contractAddress].tokenIdWithListing.remove(tokenId);
        }
    }

    /**
     * @dev Check if a listing is valid or not
     * The seller must be the owner
     * The seller must have give this contract allowance
     * The sell price must be more than 0
     * The listing mustn't be expired
     */
    function _isListingValid(
        address contractAddress,
        Listing memory listing
    ) private view returns (bool isValid) {
        if (
            _isTokenOwner(
                contractAddress,
                listing.tokenId,
                listing.seller,
                listing.tokenType
            ) &&
            _isAllTokenApproved(
                contractAddress,
                listing.seller,
                listing.tokenType
            ) &&
            listing.value > 0 &&
            listing.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    /**
     * @dev check if the account is the owner of this erc721 or erc1155 token
     */
    function _isTokenOwner(
        address contractAddress,
        uint256 tokenId,
        address account,
        uint256 tokenType
    ) private view returns (bool) {
        if (tokenType == 1) {
            IERC721 _erc721 = IERC721(contractAddress);
            try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
                return tokenOwner == account;
            } catch {
                return false;
            }
        } else {
            IERC1155 _erc1155 = IERC1155(contractAddress);
            // _erc1155.balanceOf(account,tokenId);

            try _erc1155.balanceOf(account, tokenId) returns (uint256) {
                return true;
            } catch {
                return false;
            }
        }
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721/erc1155 tokens
     */
    function _isAllTokenApproved(
        address contractAddress,
        address owner,
        uint256 tokenType
    ) private view returns (bool) {
        if (tokenType == 1) {
            IERC721 _erc721 = IERC721(contractAddress);
            return _erc721.isApprovedForAll(owner, address(this));
        } else {
            IERC1155 _erc1155 = IERC1155(contractAddress);
            return _erc1155.isApprovedForAll(owner, address(this));
        }
    }

    /**
     * @dev Enable to disable Bids and Listing
     */
    function changeMarketplaceStatus(bool enabled) external onlyOwner {
        _isTradingEnabled = enabled;
    }

    /**
     * @dev See {TheeNFTMarketplace-actionTimeOutRangeMin}.
     */
    function actionTimeOutRangeMin() external view override returns (uint256) {
        return _actionTimeOutRangeMin;
    }

    /**
     * @dev See {TheeNFTMarketplace-actionTimeOutRangeMax}.
     */
    function actionTimeOutRangeMax() external view override returns (uint256) {
        return _actionTimeOutRangeMax;
    }

    /**
     * @dev See {TheeNFTMarketplace-paymentToken}.
     */
    function paymentToken() external view override returns (address) {
        return address(_paymentToken);
    }

    /**
     * @dev Change minimum listing and bid time range
     */
    function changeMinActionTimeLimit(uint256 timeInSec) external onlyOwner {
        _actionTimeOutRangeMin = timeInSec;
    }

    /**
     * @dev Change maximum listing and bid time range
     */
    function changeMaxActionTimeLimit(uint256 timeInSec) external onlyOwner {
        _actionTimeOutRangeMax = timeInSec;
    }

    /**
     * @dev See {TheeNFTMarketplace-serviceFee}.
     */
    function serviceFee() external view returns (uint8) {
        return _serviceFeeFraction;
    }

    /**
     * @dev Change withdrawal fee percentage.
     * @param serviceFeeFraction_ Fraction of withdrawal fee based on 1000
     */
    function changeSeriveFee(uint8 serviceFeeFraction_) external onlyOwner {
        require(
            serviceFeeFraction_ <= 25,
            "Attempt to set percentage higher than 2.5%."
        );

        _serviceFeeFraction = serviceFeeFraction_;
    }
}
