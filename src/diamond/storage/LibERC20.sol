// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibERC20 {
    bytes32 internal constant STORAGE_POSITION =
        keccak256("diamond.erc20.storage");

    struct Layout {
        uint256 totalSupply;
        mapping(address => uint256) balanceOf;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 pos = STORAGE_POSITION;
        assembly {
            l.slot := pos
        }
    }
}
