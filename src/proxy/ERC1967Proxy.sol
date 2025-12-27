// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC1967Proxy {
    // bytes32 internal constant IMPLEMENTATION_SLOT =
    //     bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    constructor(address implementation_, bytes memory data_) {
        _setImplementation(implementation_);
        if (data_.length > 0) {
            (bool ok, ) = implementation_.delegatecall(data_);
            require(ok, "init failed");
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                impl,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _implementation() internal view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    function _setImplementation(address newImpl) internal {
        assembly {
            sstore(IMPLEMENTATION_SLOT, newImpl)
        }
    }
}
