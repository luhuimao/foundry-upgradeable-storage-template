// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibAccess {
    bytes32 internal constant STORAGE_POSITION =
        keccak256("diamond.access.storage");

    struct Layout {
        mapping(address => bool) admins;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 pos = STORAGE_POSITION;
        assembly {
            l.slot := pos
        }
    }
}
