# 测试指南

本指南介绍如何为可升级合约编写全面的测试。

---

## 🎯 测试目标

可升级合约的测试应覆盖：

1. ✅ **功能测试** - 业务逻辑正确性
2. ✅ **存储布局测试** - 检测状态变量
3. ✅ **升级测试** - 升级流程和兼容性
4. ✅ **权限测试** - 访问控制
5. ✅ **命名空间测试** - 存储隔离

---

## 📂 测试结构

```
test/
├── proxy/
│   ├── TokenProxy.t.sol          # 功能测试
│   └── StorageLayout.t.sol       # 存储布局测试
└── diamond/
    ├── DiamondBasic.t.sol        # 基本功能测试
    ├── FacetStorageCheck.t.sol   # Facet 存储检测
    └── NamespaceCollision.t.sol  # 命名空间测试
```

---

## 🧪 功能测试

### Proxy 功能测试示例

**文件**: [test/proxy/TokenProxy.t.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/test/proxy/TokenProxy.t.sol)

```solidity
contract TokenProxyTest is Test {
    ERC1967Proxy proxy;
    TokenV1 token;
    
    address owner = address(0xCAFE);
    address user = address(0xBEEF);
    
    function setUp() public {
        // 部署实现
        TokenV1 implementation = new TokenV1();
        
        // 部署代理并初始化
        bytes memory initData = abi.encodeWithSelector(
            TokenV1.initialize.selector,
            owner
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        token = TokenV1(address(proxy));
    }
    
    function test_initialize_sets_owner() public {
        // 验证初始化成功
        assertEq(token.balanceOf(owner), 0);
    }
    
    function test_mint_works() public {
        vm.prank(owner);
        token.mint(user, 100);
        
        assertEq(token.balanceOf(user), 100);
    }
    
    function test_mint_reverts_if_not_owner() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        token.mint(user, 100);
    }
}
```

### Diamond 功能测试示例

**文件**: [test/diamond/DiamondBasic.t.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/test/diamond/DiamondBasic.t.sol)

```solidity
contract DiamondBasicTest is Test {
    Diamond diamond;
    ERC20Facet erc20Facet;
    
    address owner = address(0xCAFE);
    address user = address(0xBEEF);
    
    function setUp() public {
        diamond = new Diamond(owner);
        erc20Facet = new ERC20Facet();
        
        // 使用 vm.store 注册 facets
        bytes32 storagePosition = keccak256("diamond.standard.diamond.storage");
        bytes32 mintSlot = keccak256(abi.encode(
            ERC20Facet.mint.selector,
            storagePosition
        ));
        
        vm.store(
            address(diamond),
            mintSlot,
            bytes32(uint256(uint160(address(erc20Facet))))
        );
    }
    
    function test_mint_via_diamond() public {
        ERC20Facet d = ERC20Facet(address(diamond));
        
        vm.prank(owner);
        d.mint(user, 50);
        
        assertEq(d.balanceOf(user), 50);
    }
}
```

---

## 📐 存储布局测试

### 检测实现合约状态变量

**文件**: [test/proxy/StorageLayout.t.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/test/proxy/StorageLayout.t.sol)

```solidity
contract StorageLayoutTest is Test {
    function test_tokenV1_has_no_state_variables() public view {
        // 读取编译输出
        string memory json = vm.readFile("out/TokenV1.sol/TokenV1.json");
        
        // 解析存储布局
        bytes memory layoutBytes = vm.parseJson(json, ".storageLayout.storage");
        
        // 空数组的 ABI 编码是 64 字节（32 字节偏移 + 32 字节长度=0）
        assertEq(
            layoutBytes.length,
            64,
            "TokenV1 defines state variables"
        );
    }
}
```

### 检测 Facet 状态变量

**文件**: [test/diamond/FacetStorageCheck.t.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/test/diamond/FacetStorageCheck.t.sol)

```solidity
contract FacetStorageCheckTest is Test {
    function test_facets_have_no_state_variables() public view {
        string[2] memory facets = ["ERC20Facet", "AccessFacet"];
        
        for (uint256 i = 0; i < facets.length; i++) {
            string memory json = vm.readFile(
                string.concat(
                    "out/",
                    facets[i],
                    ".sol/",
                    facets[i],
                    ".json"
                )
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

---

## 🔄 升级测试

### 测试升级流程

```solidity
contract UpgradeTest is Test {
    ERC1967Proxy proxy;
    TokenV1 tokenV1;
    
    address owner = address(0xCAFE);
    
    function setUp() public {
        // 部署 V1
        TokenV1 impl1 = new TokenV1();
        bytes memory initData = abi.encodeWithSelector(
            TokenV1.initialize.selector,
            owner
        );
        proxy = new ERC1967Proxy(address(impl1), initData);
        tokenV1 = TokenV1(address(proxy));
    }
    
    function test_upgrade_requires_owner() public {
        TokenV2 impl2 = new TokenV2();
        
        // 非 owner 升级应该失败
        vm.prank(address(0xBEEF));
        vm.expectRevert("not owner");
        tokenV1.upgradeTo(address(impl2));
        
        // owner 升级应该成功
        vm.prank(owner);
        tokenV1.upgradeTo(address(impl2));
    }
    
    function test_upgrade_preserves_storage() public {
        // 在 V1 中设置数据
        vm.prank(owner);
        tokenV1.mint(address(0xBEEF), 1000);
        
        // 升级到 V2
        TokenV2 impl2 = new TokenV2();
        vm.prank(owner);
        tokenV1.upgradeTo(address(impl2));
        
        // 验证数据保留
        TokenV2 tokenV2 = TokenV2(address(proxy));
        assertEq(tokenV2.balanceOf(address(0xBEEF)), 1000);
    }
}
```

---

## 🔐 权限测试

### 测试访问控制

```solidity
contract AccessControlTest is Test {
    function test_only_owner_can_mint() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        token.mint(user, 100);
    }
    
    function test_only_owner_can_upgrade() public {
        TokenV2 newImpl = new TokenV2();
        
        vm.prank(user);
        vm.expectRevert("not owner");
        token.upgradeTo(address(newImpl));
    }
}
```

---

## 🎨 命名空间测试

### 验证命名空间唯一性

**文件**: [test/diamond/NamespaceCollision.t.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/test/diamond/NamespaceCollision.t.sol)

```solidity
contract NamespaceCollisionTest is Test {
    function test_unique_storage_namespaces() public {
        bytes32 diamond = keccak256("diamond.standard.diamond.storage");
        bytes32 erc20 = keccak256("diamond.erc20.storage");
        bytes32 access = keccak256("diamond.access.storage");
        
        // 确保所有命名空间不同
        assert(diamond != erc20);
        assert(diamond != access);
        assert(erc20 != access);
    }
}
```

---

## 🛠️ 高级测试技巧

### 使用 vm.store 操作存储

```solidity
function test_with_vm_store() public {
    // 直接设置存储槽位
    bytes32 slot = keccak256("app.storage.v1");
    
    // 设置 owner (slot + 0)
    vm.store(
        address(proxy),
        slot,
        bytes32(uint256(uint160(owner)))
    );
    
    // 设置 totalSupply (slot + 1)
    vm.store(
        address(proxy),
        bytes32(uint256(slot) + 1),
        bytes32(uint256(1000))
    );
}
```

### 使用 vm.load 读取存储

```solidity
function test_read_storage() public {
    bytes32 slot = keccak256("app.storage.v1");
    
    // 读取 owner
    bytes32 ownerData = vm.load(address(proxy), slot);
    address storedOwner = address(uint160(uint256(ownerData)));
    
    assertEq(storedOwner, owner);
}
```

### Fuzz 测试

```solidity
function testFuzz_mint(address to, uint256 amount) public {
    vm.assume(to != address(0));
    vm.assume(amount < type(uint128).max);
    
    vm.prank(owner);
    token.mint(to, amount);
    
    assertEq(token.balanceOf(to), amount);
}
```

---

## 📊 测试覆盖率

### 运行覆盖率报告

```bash
# 生成覆盖率报告
forge coverage

# 生成详细报告
forge coverage --report lcov

# 查看 HTML 报告
genhtml lcov.info -o coverage
open coverage/index.html
```

### 目标覆盖率

- 🎯 **行覆盖率**: > 90%
- 🎯 **分支覆盖率**: > 80%
- 🎯 **函数覆盖率**: 100%

---

## 🎯 测试最佳实践

### 1. 使用描述性测试名称

```solidity
// ✅ 好的命名
function test_mint_reverts_if_not_owner() public {}
function test_upgrade_preserves_storage() public {}

// ❌ 不好的命名
function test1() public {}
function testMint() public {}
```

### 2. 每个测试只测试一件事

```solidity
// ✅ 好的测试
function test_mint_increases_balance() public {
    vm.prank(owner);
    token.mint(user, 100);
    assertEq(token.balanceOf(user), 100);
}

function test_mint_increases_total_supply() public {
    vm.prank(owner);
    token.mint(user, 100);
    assertEq(token.totalSupply(), 100);
}

// ❌ 不好的测试 - 测试太多
function test_mint() public {
    vm.prank(owner);
    token.mint(user, 100);
    assertEq(token.balanceOf(user), 100);
    assertEq(token.totalSupply(), 100);
    // ... 更多断言
}
```

### 3. 使用 setUp 减少重复

```solidity
contract MyTest is Test {
    Token token;
    address owner = address(0xCAFE);
    
    function setUp() public {
        // 所有测试共享的设置
        token = new Token();
        token.initialize(owner);
    }
    
    function test_something() public {
        // 直接使用 token
    }
}
```

### 4. 测试边界条件

```solidity
function test_mint_zero_amount() public {
    vm.prank(owner);
    token.mint(user, 0);
    assertEq(token.balanceOf(user), 0);
}

function test_mint_max_amount() public {
    vm.prank(owner);
    token.mint(user, type(uint256).max);
    assertEq(token.balanceOf(user), type(uint256).max);
}
```

### 5. 使用 expectRevert 测试错误

```solidity
function test_mint_reverts_if_not_owner() public {
    vm.prank(user);
    vm.expectRevert("not owner");
    token.mint(user, 100);
}

// 使用自定义错误
function test_mint_reverts_with_custom_error() public {
    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, user));
    token.mint(user, 100);
}
```

---

## 🐛 调试技巧

### 使用 console.log

```solidity
import "forge-std/console.sol";

function test_debug() public {
    console.log("Balance before:", token.balanceOf(user));
    
    vm.prank(owner);
    token.mint(user, 100);
    
    console.log("Balance after:", token.balanceOf(user));
}
```

### 使用详细输出

```bash
# 显示所有日志
forge test -vvvv

# 只显示失败的测试
forge test -vvv --fail-fast
```

### 使用 gas 快照

```bash
# 生成 gas 快照
forge snapshot

# 比较 gas 变化
forge snapshot --diff
```

---

## 📝 CI/CD 集成

### GitHub Actions 示例

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Run tests
        run: forge test
      
      - name: Check coverage
        run: forge coverage --report lcov
```

---

## 🔗 相关资源

- [Foundry Testing](https://book.getfoundry.sh/forge/tests)
- [Foundry Cheatcodes](https://book.getfoundry.sh/cheatcodes/)
- [存储模式指南](storage-patterns.md)
- [升级指南](upgrading-contracts.md)
