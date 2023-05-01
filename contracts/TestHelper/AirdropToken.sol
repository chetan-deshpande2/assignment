// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropERC20 is Ownable {
    address public token;

    function connectToOtherContracts(address _token) external onlyOwner {
        token = _token;
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(token != address(0), "Token have not been set");
        require(
            recipients.length == amounts.length,
            "Arrays must have the same length"
        );

        unchecked {
            for (uint256 i = 0; i < recipients.length; ++i) {
                IERC20(token).transferFrom({
                    from: msg.sender,
                    to: recipients[i],
                    amount: amounts[i]
                });
            }
        }
    }

    function retrieveTokens(uint256 amount) external onlyOwner {
        require(token != address(0), "Token have not been set");

        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Amount you wish to retrieve is bigger then actual balance"
        );

        IERC20(token).transfer(msg.sender, amount);
    }
}
