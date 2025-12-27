// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/LibAccess.sol";
import "../storage/LibDiamond.sol";

contract AccessFacet {
    function setAdmin(address user, bool ok) external {
        require(msg.sender == LibDiamond.owner(), "not owner");
        LibAccess.layout().admins[user] = ok;
    }

    function isAdmin(address user) external view returns (bool) {
        return LibAccess.layout().admins[user];
    }
}
