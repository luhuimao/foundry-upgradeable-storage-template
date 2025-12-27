// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AppStorage.sol";
import "../proxy/UUPSUpgradeable.sol";

contract TokenV1 is UUPSUpgradeable {
    function initialize(address owner_) external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(s.owner == address(0), "already init");
        s.owner = owner_;
    }

    function mint(address to, uint256 amount) external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(msg.sender == s.owner, "not owner");
        s.totalSupply += amount;
        s.balances[to] += amount;
    }

    function balanceOf(address user) external view returns (uint256) {
        return AppStorage.layout().balances[user];
    }

    function _authorizeUpgrade() internal view override {
        require(msg.sender == AppStorage.layout().owner, "not owner");
    }
}
