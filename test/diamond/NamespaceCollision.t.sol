// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract NamespaceCollisionTest is Test {
    function test_unique_storage_namespaces() public {
        bytes32[3] memory slots;

        slots[0] = keccak256("diamond.standard.diamond.storage");
        slots[1] = keccak256("diamond.erc20.storage");
        slots[2] = keccak256("diamond.access.storage");

        for (uint256 i = 0; i < slots.length; i++) {
            for (uint256 j = i + 1; j < slots.length; j++) {
                assertTrue(
                    slots[i] != slots[j],
                    "storage namespace collision"
                );
            }
        }
    }
}
