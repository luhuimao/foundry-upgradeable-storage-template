// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract UUPSUpgradeable {
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade();
        assembly {
            // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, newImplementation)
        }
    }

    function _authorizeUpgrade() internal virtual;
}
