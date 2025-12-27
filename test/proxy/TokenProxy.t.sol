// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../../src/proxy/ERC1967Proxy.sol";
import "../../src/app/TokenV1.sol";

contract TokenProxyTest is Test {
    address owner = address(0xA11CE);
    address user  = address(0xB0B);

    TokenV1 impl;
    ERC1967Proxy proxy;
    TokenV1 token; // proxy as TokenV1

    function setUp() public {
        impl = new TokenV1();

        bytes memory initData =
            abi.encodeWithSignature("initialize(address)", owner);

        proxy = new ERC1967Proxy(address(impl), initData);
        token = TokenV1(address(proxy));
    }

    function test_initialize_sets_owner() public view{
        assertEq(token.balanceOf(owner), 0);
    }

    function test_mint_works() public {
        vm.prank(owner);
        token.mint(user, 100);

        assertEq(token.balanceOf(user), 100);
    }

    function test_mint_reverts_if_not_owner() public {
        vm.expectRevert("not owner");
        token.mint(user, 100);
    }

    function test_upgrade_requires_owner() public {
        TokenV1 newImpl = new TokenV1();

        vm.expectRevert("not owner");
        token.upgradeTo(address(newImpl));

        vm.prank(owner);
        token.upgradeTo(address(newImpl));
    }
}
