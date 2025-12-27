// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/LibDiamond.sol";

contract DiamondManagementFacet {
    function setFacet(bytes4 selector, address facet) external {
        require(msg.sender == LibDiamond.owner(), "not owner");
        LibDiamond.setFacet(selector, facet);
    }

    function getFacet(bytes4 selector) external view returns (address) {
        return LibDiamond.facetOf(selector);
    }

    function getOwner() external view returns (address) {
        return LibDiamond.owner();
    }
}
