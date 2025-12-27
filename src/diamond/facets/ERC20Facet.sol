// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/LibERC20.sol";
import "../storage/LibDiamond.sol";

contract ERC20Facet {
    function mint(address to, uint256 amount) external {
        require(msg.sender == LibDiamond.owner(), "not owner");

        LibERC20.Layout storage s = LibERC20.layout();
        s.totalSupply += amount;
        s.balanceOf[to] += amount;
    }

    function balanceOf(address user) external view returns (uint256) {
        return LibERC20.layout().balanceOf[user];
    }
}
