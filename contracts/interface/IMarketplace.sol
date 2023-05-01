// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IMarketplace {
    struct Listing {
        uint256 tokenId;
        uint256 value;
        address seller;
        uint256 nftCount;
        uint256 tokenType;
        uint256 expireTimestamp;
    }

    struct TrikonMarket {
        EnumerableSet.UintSet tokenIdWithListing;
        mapping(uint256 => Listing) listings;
    }

    event TokenListed(
        address indexed contractAddress,
        uint256 indexed tokenId,
        Listing listing
    );

    event TokenDelisted(
        address indexed contractAddress,
        uint256 indexed tokenId,
        Listing listing
    );

    event TokenBought(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        Listing listing
    );

    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     * @param expireTimestamp when would this listing expire
     */
    function listToken(
        address contractAddress,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        uint256 nftAmount,
        uint8 tokenType
    ) external;

    /**
     * @dev Delist token for sale
     * @param tokenId erc721 token Id
     */
    function delistToken(address contractAddress, uint256 tokenId) external;

    /**
     * @dev Buy token
     * @param tokenId erc721 token Id
     */
    function buyToken(
        address contractAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 tokenType,
        uint256 paymentToken
    ) external;

    /**
     * @dev get current listing of a token
     * @param tokenId contract token Id
     * @return current valid listing or empty listing struct
     */
    // function getTokenListing(
    //     address contractAddress,
    //     uint256 tokenId
    // ) external view returns (Listing memory);

    /**
     * @dev Surface minimum listing and bid time range
     */
    function actionTimeOutRangeMin() external view returns (uint256);

    /**
     * @dev Surface maximum listing and bid time range
     */
    function actionTimeOutRangeMax() external view returns (uint256);

    /**
     * @dev Payment token address
     */
    function paymentToken() external view returns (address);
}
