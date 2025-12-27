// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) selectorToFacet;
        address owner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 pos = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := pos
        }
    }

    function setOwner(address newOwner) internal {
        diamondStorage().owner = newOwner;
    }

    function owner() internal view returns (address) {
        return diamondStorage().owner;
    }

    function setFacet(bytes4 selector, address facet) internal {
        diamondStorage().selectorToFacet[selector] = facet;
    }

    function facetOf(bytes4 selector) internal view returns (address) {
        return diamondStorage().selectorToFacet[selector];
    }
}
