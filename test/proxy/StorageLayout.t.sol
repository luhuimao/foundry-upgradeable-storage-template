// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract StorageLayoutTest is Test {
    function test_tokenV1_has_no_state_variables() public view {
        string memory json =
            vm.readFile("out/TokenV1.sol/TokenV1.json");

        bytes memory layoutBytes =
            vm.parseJson(json, ".storageLayout.storage");

        // 空数组的 ABI 编码是 64 字节（32 字节偏移 + 32 字节长度=0）
        // 如果有元素，编码会更长
        assertEq(
            layoutBytes.length,
            64,
            "TokenV1 defines state variables"
        );
    }
}
