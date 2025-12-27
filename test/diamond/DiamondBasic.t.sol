// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../../src/diamond/Diamond.sol";
import "../../src/diamond/storage/LibDiamond.sol";
import "../../src/diamond/facets/ERC20Facet.sol";

contract DiamondBasicTest is Test {
    Diamond diamond;
    ERC20Facet erc20Facet;

    address owner = address(0xCAFE);
    address user  = address(0xBEEF);

    function setUp() public {
        diamond = new Diamond(owner);
        erc20Facet = new ERC20Facet();

        // 直接在 Diamond 存储中注册 facets
        // DiamondStorage 的位置
        bytes32 storagePosition = keccak256("diamond.standard.diamond.storage");
        
        // 计算 selectorToFacet mapping 的 slot
        // mapping 的第一个元素在 storagePosition + 0
        bytes32 mintSlot = keccak256(abi.encode(ERC20Facet.mint.selector, storagePosition));
        bytes32 balanceOfSlot = keccak256(abi.encode(ERC20Facet.balanceOf.selector, storagePosition));
        
        // 设置 facet 地址
        vm.store(address(diamond), mintSlot, bytes32(uint256(uint160(address(erc20Facet)))));
        vm.store(address(diamond), balanceOfSlot, bytes32(uint256(uint160(address(erc20Facet)))));
    }

    function test_mint_via_diamond() public {
        ERC20Facet d = ERC20Facet(address(diamond));

        vm.prank(owner);
        d.mint(user, 50);

        assertEq(d.balanceOf(user), 50);
    }

    function test_mint_reverts_if_not_owner() public {
        ERC20Facet d = ERC20Facet(address(diamond));

        vm.expectRevert("not owner");
        d.mint(user, 50);
    }
}
