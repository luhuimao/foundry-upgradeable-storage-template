# Diamond 合约 API 参考

本文档提供 Diamond 模式相关合约的完整 API 参考。

---

## Diamond

**文件**: [src/diamond/Diamond.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/Diamond.sol)

Diamond 主合约，作为所有 facet 的统一入口点。

### Constructor

```solidity
constructor(address owner_)
```

部署 Diamond 并设置所有者。

**参数**:
- `owner_` - Diamond 所有者地址

**示例**:
```solidity
Diamond diamond = new Diamond(msg.sender);
```

### fallback()

```solidity
fallback() external payable
```

接收所有函数调用并路由到对应的 facet。

**行为**:
1. 根据 `msg.sig` 查找对应的 facet 地址
2. 如果未找到，回滚并提示 "facet not found"
3. 使用 `delegatecall` 调用 facet
4. 返回 facet 的返回值或回滚

### receive()

```solidity
receive() external payable
```

接收 ETH 转账。

---

## DiamondManagementFacet

**文件**: [src/diamond/facets/DiamondManagementFacet.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/facets/DiamondManagementFacet.sol)

管理 facet 注册和查询。

### setFacet()

```solidity
function setFacet(bytes4 selector, address facet) external
```

注册或更新 function selector 到 facet 的映射。

**参数**:
- `selector` - 函数选择器（4 字节）
- `facet` - facet 合约地址

**要求**:
- 调用者必须是 owner

**示例**:
```solidity
DiamondManagementFacet(diamond).setFacet(
    ERC20Facet.mint.selector,
    address(erc20Facet)
);
```

### getFacet()

```solidity
function getFacet(bytes4 selector) external view returns (address)
```

查询 selector 对应的 facet 地址。

**参数**:
- `selector` - 函数选择器

**返回**:
- facet 地址（如果未注册则返回 address(0)）

**示例**:
```solidity
address facet = DiamondManagementFacet(diamond).getFacet(
    ERC20Facet.mint.selector
);
```

### getOwner()

```solidity
function getOwner() external view returns (address)
```

获取 Diamond 所有者地址。

**返回**:
- 所有者地址

---

## ERC20Facet

**文件**: [src/diamond/facets/ERC20Facet.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/facets/ERC20Facet.sol)

ERC20 代币功能 facet。

### mint()

```solidity
function mint(address to, uint256 amount) external
```

铸造新代币。

**参数**:
- `to` - 接收地址
- `amount` - 铸造数量

**要求**:
- 调用者必须是 Diamond owner

**示例**:
```solidity
ERC20Facet(address(diamond)).mint(user, 1000 ether);
```

### balanceOf()

```solidity
function balanceOf(address user) external view returns (uint256)
```

查询账户余额。

**参数**:
- `user` - 查询地址

**返回**:
- 账户余额

**示例**:
```solidity
uint256 balance = ERC20Facet(address(diamond)).balanceOf(user);
```

---

## AccessFacet

**文件**: [src/diamond/facets/AccessFacet.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/facets/AccessFacet.sol)

访问控制 facet。

### setAdmin()

```solidity
function setAdmin(address user, bool ok) external
```

设置或撤销管理员权限。

**参数**:
- `user` - 用户地址
- `ok` - true 授予权限，false 撤销权限

**要求**:
- 调用者必须是 Diamond owner

**示例**:
```solidity
AccessFacet(address(diamond)).setAdmin(admin, true);
```

### isAdmin()

```solidity
function isAdmin(address user) external view returns (bool)
```

检查用户是否是管理员。

**参数**:
- `user` - 查询地址

**返回**:
- true 如果是管理员，否则 false

**示例**:
```solidity
bool admin = AccessFacet(address(diamond)).isAdmin(user);
```

---

## Storage Libraries

### LibDiamond

**文件**: [src/diamond/storage/LibDiamond.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/storage/LibDiamond.sol)

Diamond 核心存储库。

#### DiamondStorage

```solidity
struct DiamondStorage {
    mapping(bytes4 => address) selectorToFacet;
    address owner;
}
```

**字段**:
- `selectorToFacet` - selector 到 facet 地址的映射
- `owner` - Diamond 所有者

#### diamondStorage()

```solidity
function diamondStorage() internal pure returns (DiamondStorage storage ds)
```

获取 Diamond 存储引用。

#### setOwner()

```solidity
function setOwner(address newOwner) internal
```

设置 Diamond 所有者（内部函数）。

#### owner()

```solidity
function owner() internal view returns (address)
```

获取 Diamond 所有者（内部函数）。

#### setFacet()

```solidity
function setFacet(bytes4 selector, address facet) internal
```

注册 selector 到 facet 映射（内部函数）。

#### facetOf()

```solidity
function facetOf(bytes4 selector) internal view returns (address)
```

查询 selector 对应的 facet（内部函数）。

#### DIAMOND_STORAGE_POSITION

```solidity
bytes32 internal constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.diamond.storage");
```

Diamond 存储槽位标识符。

---

### LibERC20

**文件**: [src/diamond/storage/LibERC20.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/storage/LibERC20.sol)

ERC20 存储库。

#### Layout

```solidity
struct Layout {
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
}
```

**字段**:
- `totalSupply` - 代币总供应量
- `balanceOf` - 账户余额映射

#### layout()

```solidity
function layout() internal pure returns (Layout storage l)
```

获取 ERC20 存储引用。

**使用示例**:
```solidity
LibERC20.Layout storage s = LibERC20.layout();
s.totalSupply += amount;
```

#### STORAGE_POSITION

```solidity
bytes32 internal constant STORAGE_POSITION =
    keccak256("diamond.erc20.storage");
```

ERC20 存储槽位标识符。

---

### LibAccess

**文件**: [src/diamond/storage/LibAccess.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/diamond/storage/LibAccess.sol)

访问控制存储库。

#### Layout

```solidity
struct Layout {
    mapping(address => bool) admins;
}
```

**字段**:
- `admins` - 管理员映射

#### layout()

```solidity
function layout() internal pure returns (Layout storage l)
```

获取访问控制存储引用。

#### STORAGE_POSITION

```solidity
bytes32 internal constant STORAGE_POSITION =
    keccak256("diamond.access.storage");
```

访问控制存储槽位标识符。

---

## 使用示例

### 完整部署流程

```solidity
// 1. 部署 Diamond
Diamond diamond = new Diamond(owner);

// 2. 部署 facets
ERC20Facet erc20Facet = new ERC20Facet();
AccessFacet accessFacet = new AccessFacet();
DiamondManagementFacet mgmtFacet = new DiamondManagementFacet();

// 3. 注册管理 facet
// (需要使用 vm.store 或其他方式初始化)

// 4. 注册其他 facets
DiamondManagementFacet(address(diamond)).setFacet(
    ERC20Facet.mint.selector,
    address(erc20Facet)
);

DiamondManagementFacet(address(diamond)).setFacet(
    ERC20Facet.balanceOf.selector,
    address(erc20Facet)
);

DiamondManagementFacet(address(diamond)).setFacet(
    AccessFacet.setAdmin.selector,
    address(accessFacet)
);

// 5. 使用 Diamond
ERC20Facet(address(diamond)).mint(user, 1000 ether);
AccessFacet(address(diamond)).setAdmin(admin, true);
```

### 升级 Facet

```solidity
// 1. 部署新版本 facet
ERC20FacetV2 newERC20Facet = new ERC20FacetV2();

// 2. 更新映射
DiamondManagementFacet(address(diamond)).setFacet(
    ERC20Facet.mint.selector,
    address(newERC20Facet)
);

// 3. 如果有新函数，也要注册
DiamondManagementFacet(address(diamond)).setFacet(
    ERC20FacetV2.burn.selector,
    address(newERC20Facet)
);
```

---

## Selector 参考

### ERC20Facet

| 函数 | Selector |
|------|----------|
| `mint(address,uint256)` | `0x40c10f19` |
| `balanceOf(address)` | `0x70a08231` |

### AccessFacet

| 函数 | Selector |
|------|----------|
| `setAdmin(address,bool)` | `0x4b0bddd2` |
| `isAdmin(address)` | `0x24d7806c` |

### DiamondManagementFacet

| 函数 | Selector |
|------|----------|
| `setFacet(bytes4,address)` | `0x01ffc9a7` |
| `getFacet(bytes4)` | `0xcdffacc6` |
| `getOwner()` | `0x893d20e8` |

---

## 存储槽位参考

| 库 | 槽位标识符 | 用途 |
|----|-----------|------|
| `LibDiamond` | `keccak256("diamond.standard.diamond.storage")` | Diamond 核心存储 |
| `LibERC20` | `keccak256("diamond.erc20.storage")` | ERC20 数据 |
| `LibAccess` | `keccak256("diamond.access.storage")` | 访问控制 |

---

## 错误处理

### 常见错误

| 错误消息 | 原因 | 解决方案 |
|---------|------|---------|
| `"facet not found"` | selector 未注册 | 使用 setFacet 注册 |
| `"not owner"` | 非 owner 调用受限函数 | 使用 owner 账户 |

---

## 安全考虑

### ⚠️ Facet 授权

所有修改操作都应检查权限：

```solidity
// ✅ 正确
function mint(address to, uint256 amount) external {
    require(msg.sender == LibDiamond.owner(), "not owner");
    // ...
}

// ❌ 错误
function mint(address to, uint256 amount) external {
    // 任何人都可以调用！
}
```

### ⚠️ Selector 冲突

避免不同 facets 使用相同的 selector：

```solidity
// ❌ 错误 - 两个 facets 有相同函数签名
contract FacetA {
    function transfer(address,uint256) external {}
}
contract FacetB {
    function transfer(address,uint256) external {} // 冲突！
}
```

---

## 相关文档

- [Diamond 模式详解](../03-diamond-pattern.md)
- [存储模式指南](../guides/storage-patterns.md)
- [升级指南](../guides/upgrading-contracts.md)
