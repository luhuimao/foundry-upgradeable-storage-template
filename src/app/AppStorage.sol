// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library AppStorage {
    // bytes32 internal constant STORAGE_SLOT =
    //     keccak256("app.storage.v1");
  bytes32 internal constant STORAGE_SLOT =0x192a690e50e93051469e068c8585461ed5b81a8b3e83921789c670a4401cf07e;
    struct Layout {
        address owner;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
