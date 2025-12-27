# 存储冲突检测

本文档介绍如何自动检测和防止存储布局冲突。

---

## 🎯 为什么需要检测？

存储冲突是可升级合约最危险的问题：

- 💥 **数据损坏** - 变量值错位
- 💥 **资金丢失** - 余额数据错误
- 💥 **功能失效** - 逻辑依赖错误数据

**自动化检测可以在部署前发现问题！**

---

## 🔍 检测机制

### 1. 状态变量检测

检测实现合约是否定义了状态变量：

```solidity
contract StorageLayoutTest is Test {
    function test_tokenV1_has_no_state_variables() public view {
        // 读取编译器输出
        string memory json = vm.readFile("out/TokenV1.sol/TokenV1.json");
        
        // 解析存储布局
        bytes memory layoutBytes = vm.parseJson(json, ".storageLayout.storage");
        
        // 空数组的 ABI 编码是 64 字节
        assertEq(layoutBytes.length, 64, "TokenV1 defines state variables");
    }
}
```

**工作原理**：
1. Solidity 编译器生成存储布局 JSON
2. `vm.parseJson` 读取 `.storageLayout.storage` 字段
3. 空数组编码为 64 字节（32 字节偏移 + 32 字节长度）
4. 如果有状态变量，编码会更长

### 2. Facet 状态检测

确保 Diamond facets 没有状态变量：

```solidity
contract FacetStorageCheckTest is Test {
    function test_facets_have_no_state_variables() public view {
        string[2] memory facets = ["ERC20Facet", "AccessFacet"];
        
        for (uint256 i = 0; i < facets.length; i++) {
            string memory json = vm.readFile(
                string.concat("out/", facets[i], ".sol/", facets[i], ".json")
            );
            
            bytes memory layoutBytes = vm.parseJson(
                json,
                ".storageLayout.storage"
            );
            
            assertEq(
                layoutBytes.length,
                64,
                string.concat(facets[i], " has state variables")
            );
        }
    }
}
```

### 3. 命名空间冲突检测

验证不同存储库使用不同的命名空间：

```solidity
contract NamespaceCollisionTest is Test {
    function test_unique_storage_namespaces() public {
        bytes32 diamond = keccak256("diamond.standard.diamond.storage");
        bytes32 erc20 = keccak256("diamond.erc20.storage");
        bytes32 access = keccak256("diamond.access.storage");
        
        assert(diamond != erc20);
        assert(diamond != access);
        assert(erc20 != access);
    }
}
```

---

## 📊 存储布局 JSON 结构

### 编译器输出

```json
{
  "storageLayout": {
    "storage": [
      {
        "astId": 123,
        "contract": "contracts/Token.sol:Token",
        "label": "owner",
        "offset": 0,
        "slot": "0",
        "type": "t_address"
      }
    ],
    "types": {
      "t_address": {
        "encoding": "inplace",
        "label": "address",
        "numberOfBytes": "20"
      }
    }
  }
}
```

### 解析示例

```solidity
// 读取完整布局
string memory json = vm.readFile("out/Token.sol/Token.json");
bytes memory fullLayout = vm.parseJson(json, ".storageLayout");

// 只读取 storage 数组
bytes memory storage = vm.parseJson(json, ".storageLayout.storage");

// 读取特定字段
bytes memory types = vm.parseJson(json, ".storageLayout.types");
```

---

## 🛠️ 实现自定义检测

### 检测存储槽位冲突

```solidity
contract StorageSlotTest is Test {
    function test_no_slot_collision() public {
        // 获取所有存储槽位
        bytes32 appStorage = keccak256("app.storage.v1");
        bytes32 eip1967Impl = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        
        // 确保不冲突
        assert(appStorage != eip1967Impl);
    }
}
```

### 检测存储布局变化

```solidity
contract StorageLayoutDiffTest is Test {
    function test_storage_layout_unchanged() public {
        // 读取当前布局
        string memory json = vm.readFile("out/TokenV1.sol/TokenV1.json");
        bytes memory currentLayout = vm.parseJson(json, ".storageLayout");
        
        // 读取基准布局（从文件）
        string memory baselineJson = vm.readFile("test/baseline/TokenV1.json");
        bytes memory baselineLayout = vm.parseJson(
            baselineJson,
            ".storageLayout"
        );
        
        // 比较
        assertEq(
            keccak256(currentLayout),
            keccak256(baselineLayout),
            "Storage layout changed"
        );
    }
}
```

---

## 🔄 CI/CD 集成

### GitHub Actions 工作流

```yaml
name: Storage Layout Check

on: [push, pull_request]

jobs:
  storage-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Run storage layout tests
        run: |
          forge test --match-contract StorageLayoutTest
          forge test --match-contract FacetStorageCheckTest
          forge test --match-contract NamespaceCollisionTest
      
      - name: Generate storage layout report
        run: |
          forge inspect TokenV1 storage-layout > storage-layout-v1.json
          forge inspect TokenV2 storage-layout > storage-layout-v2.json
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: storage-layouts
          path: storage-layout-*.json
```

### 自动化脚本

```bash
#!/bin/bash
# check-storage.sh

echo "Checking storage layouts..."

# 编译合约
forge build

# 运行存储布局测试
forge test --match-contract StorageLayoutTest || exit 1
forge test --match-contract FacetStorageCheckTest || exit 1
forge test --match-contract NamespaceCollisionTest || exit 1

# 生成布局报告
mkdir -p reports
forge inspect TokenV1 storage-layout > reports/TokenV1-layout.json
forge inspect TokenV2 storage-layout > reports/TokenV2-layout.json

echo "✅ All storage checks passed!"
```

---

## 📈 高级检测技术

### 1. 比较升级前后的布局

```solidity
contract UpgradeStorageTest is Test {
    function test_v2_extends_v1_storage() public {
        // 读取 V1 布局
        string memory v1Json = vm.readFile("out/TokenV1.sol/TokenV1.json");
        bytes memory v1Storage = vm.parseJson(v1Json, ".storageLayout.storage");
        
        // 读取 V2 布局
        string memory v2Json = vm.readFile("out/TokenV2.sol/TokenV2.json");
        bytes memory v2Storage = vm.parseJson(v2Json, ".storageLayout.storage");
        
        // V2 的存储应该 >= V1（只能添加，不能删除）
        // 注意：这里需要解析 JSON 数组长度
        // 实际实现会更复杂
    }
}
```

### 2. 检测槽位计算

```solidity
contract SlotCalculationTest is Test {
    function test_mapping_slot_calculation() public {
        bytes32 baseSlot = keccak256("app.storage.v1");
        address user = address(0xBEEF);
        
        // 计算 mapping 槽位
        // mapping(address => uint256) balances
        // balances 在 Layout 的 offset 2
        bytes32 balancesBaseSlot = bytes32(uint256(baseSlot) + 2);
        bytes32 userBalanceSlot = keccak256(
            abi.encode(user, balancesBaseSlot)
        );
        
        // 验证槽位计算正确
        // ...
    }
}
```

### 3. 使用 Foundry Cheatcodes 检查存储

```solidity
contract StorageInspectionTest is Test {
    function test_inspect_storage() public {
        ERC1967Proxy proxy = /* ... */;
        
        // 读取实现槽位
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 implData = vm.load(address(proxy), implSlot);
        address implementation = address(uint160(uint256(implData)));
        
        console.log("Implementation:", implementation);
        
        // 读取 AppStorage
        bytes32 appSlot = keccak256("app.storage.v1");
        bytes32 ownerData = vm.load(address(proxy), appSlot);
        address owner = address(uint160(uint256(ownerData)));
        
        console.log("Owner:", owner);
    }
}
```

---

## 🎯 最佳实践

### 1. 在 CI 中运行检测

```yaml
# .github/workflows/test.yml
- name: Storage Layout Tests
  run: forge test --match-contract Storage
```

### 2. 保存布局基准

```bash
# 在每次发布时保存布局
forge inspect TokenV1 storage-layout > baselines/TokenV1-v1.0.0.json
```

### 3. 升级前验证

```bash
# 升级前检查
./scripts/check-storage.sh
forge test --match-contract Upgrade
```

### 4. 文档化存储结构

```solidity
/**
 * @notice AppStorage 布局
 * @dev 槽位: keccak256("app.storage.v1")
 * 
 * 布局:
 * - offset 0: owner (address)
 * - offset 1: totalSupply (uint256)
 * - offset 2: balances (mapping(address => uint256))
 * 
 * 历史:
 * - v1.0.0: 初始布局
 * - v1.1.0: 添加 maxSupply (offset 3)
 */
```

---

## ⚠️ 常见问题

### Q: 为什么空数组是 64 字节？

A: ABI 编码规则：
- 前 32 字节：数组数据的偏移量（0x20）
- 后 32 字节：数组长度（0x00）

### Q: 如何检测 constant 变量？

A: Constant 变量不占用存储槽位，但某些情况下编译器仍会将其计入布局。解决方案是内联使用：

```solidity
// ❌ 可能被计入
bytes32 constant SLOT = 0x123...;

// ✅ 内联使用
assembly {
    sstore(0x123..., value)
}
```

### Q: 如何处理继承的存储？

A: 继承的合约会影响存储布局。确保：
1. 基类不定义状态变量
2. 使用存储库模式
3. 测试完整的继承链

---

## 🔗 相关资源

- [存储模式指南](../guides/storage-patterns.md)
- [测试指南](../guides/testing.md)
- [Foundry Cheatcodes](https://book.getfoundry.sh/cheatcodes/)
- [Solidity 存储布局](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
