// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./storage/LibDiamond.sol";

contract Diamond {
    constructor(address owner_) {
        LibDiamond.setOwner(owner_);
    }

    fallback() external payable {
        address facet = LibDiamond.facetOf(msg.sig);
        require(facet != address(0), "facet not found");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                facet,
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

    receive() external payable {}
}
