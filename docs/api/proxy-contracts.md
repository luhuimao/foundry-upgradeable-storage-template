# Proxy 合约 API 参考

本文档提供 UUPS Proxy 模式相关合约的完整 API 参考。

---

## ERC1967Proxy

**文件**: [src/proxy/ERC1967Proxy.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/proxy/ERC1967Proxy.sol)

符合 EIP-1967 标准的代理合约。

### Constructor

```solidity
constructor(address implementation_, bytes memory data_)
```

部署代理并可选地初始化实现合约。

**参数**:
- `implementation_` - 初始实现合约地址
- `data_` - 初始化调用数据（可为空）

**行为**:
1. 设置实现合约地址到 EIP-1967 标准槽位
2. 如果 `data_` 非空，使用 `delegatecall` 调用实现合约
3. 如果初始化失败，回滚交易

**示例**:
```solidity
// 不带初始化
ERC1967Proxy proxy = new ERC1967Proxy(implementation, "");

// 带初始化
bytes memory initData = abi.encodeWithSelector(
    TokenV1.initialize.selector,
    owner
);
ERC1967Proxy proxy = new ERC1967Proxy(implementation, initData);
```

### fallback()

```solidity
fallback() external payable
```

接收所有函数调用并委托给实现合约。

**行为**:
1. 从存储槽读取实现合约地址
2. 使用 `delegatecall` 转发调用
3. 返回实现合约的返回值或回滚

### receive()

```solidity
receive() external payable
```

接收 ETH 转账并委托给实现合约。

---

## UUPSUpgradeable

**文件**: [src/proxy/UUPSUpgradeable.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/proxy/UUPSUpgradeable.sol)

提供 UUPS 升级功能的抽象合约。

### upgradeTo()

```solidity
function upgradeTo(address newImplementation) external virtual
```

升级到新的实现合约。

**参数**:
- `newImplementation` - 新实现合约地址

**行为**:
1. 调用 `_authorizeUpgrade()` 进行授权检查
2. 更新 EIP-1967 实现槽位

**权限**: 由子类的 `_authorizeUpgrade()` 实现决定

**示例**:
```solidity
TokenV1 token = TokenV1(address(proxy));
token.upgradeTo(address(newImplementation));
```

### _authorizeUpgrade()

```solidity
function _authorizeUpgrade() internal virtual
```

授权检查函数，必须由子类实现。

**实现示例**:
```solidity
function _authorizeUpgrade() internal view override {
    require(msg.sender == AppStorage.layout().owner, "not owner");
}
```

---

## TokenV1

**文件**: [src/app/TokenV1.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/app/TokenV1.sol)

UUPS 可升级代币实现示例。

### initialize()

```solidity
function initialize(address owner_) external
```

初始化代币合约（仅可调用一次）。

**参数**:
- `owner_` - 代币所有者地址

**要求**:
- 只能调用一次（owner 必须为 address(0)）

**示例**:
```solidity
TokenV1 token = TokenV1(address(proxy));
token.initialize(msg.sender);
```

### mint()

```solidity
function mint(address to, uint256 amount) external
```

铸造新代币。

**参数**:
- `to` - 接收地址
- `amount` - 铸造数量

**要求**:
- 调用者必须是 owner

**示例**:
```solidity
token.mint(user, 1000 ether);
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
uint256 balance = token.balanceOf(user);
```

---

## AppStorage

**文件**: [src/app/AppStorage.sol](file:///Users/benjamin/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/github/foundry-upgradeable-storage-template/src/app/AppStorage.sol)

应用层存储库。

### Layout

```solidity
struct Layout {
    address owner;
    uint256 totalSupply;
    mapping(address => uint256) balances;
}
```

应用存储结构。

**字段**:
- `owner` - 合约所有者
- `totalSupply` - 代币总供应量
- `balances` - 账户余额映射

### layout()

```solidity
function layout() internal pure returns (Layout storage l)
```

获取存储引用。

**返回**:
- 存储结构引用

**使用示例**:
```solidity
AppStorage.Layout storage s = AppStorage.layout();
s.owner = newOwner;
```

### STORAGE_SLOT

```solidity
bytes32 internal constant STORAGE_SLOT = 
    keccak256("app.storage.v1");
```

存储槽位标识符。

**值**: `0x192a690e50e93051469e068c8585461ed5b81a8b3e83921789c670a4401cf07e`

---

## 使用示例

### 完整部署流程

```solidity
// 1. 部署实现合约
TokenV1 implementation = new TokenV1();

// 2. 准备初始化数据
bytes memory initData = abi.encodeWithSelector(
    TokenV1.initialize.selector,
    owner
);

// 3. 部署代理
ERC1967Proxy proxy = new ERC1967Proxy(
    address(implementation),
    initData
);

// 4. 获取代理接口
TokenV1 token = TokenV1(address(proxy));

// 5. 使用代币
token.mint(user, 1000 ether);
uint256 balance = token.balanceOf(user);
```

### 升级流程

```solidity
// 1. 部署新实现
TokenV2 newImplementation = new TokenV2();

// 2. 升级（需要 owner 权限）
TokenV1 token = TokenV1(address(proxy));
token.upgradeTo(address(newImplementation));

// 3. 使用新功能
TokenV2 tokenV2 = TokenV2(address(proxy));
tokenV2.newFunction();
```

---

## 存储槽位参考

| 名称 | 值 | 用途 |
|------|-----|------|
| `IMPLEMENTATION_SLOT` | `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` | EIP-1967 实现地址 |
| `STORAGE_SLOT` | `keccak256("app.storage.v1")` | AppStorage 位置 |

---

## 事件

当前实现不包含事件。在生产环境中，建议添加：

```solidity
event Upgraded(address indexed implementation);
event Initialized(address indexed owner);
event Minted(address indexed to, uint256 amount);
```

---

## 错误处理

### 常见错误

| 错误消息 | 原因 | 解决方案 |
|---------|------|---------|
| `"already init"` | 尝试重复初始化 | 确保只调用一次 initialize |
| `"not owner"` | 非 owner 调用受限函数 | 使用 owner 账户调用 |
| `"init failed"` | 初始化调用失败 | 检查初始化逻辑 |

---

## 安全考虑

### ⚠️ 初始化保护

```solidity
// ✅ 正确 - 有初始化保护
function initialize(address owner_) external {
    require(s.owner == address(0), "already init");
    s.owner = owner_;
}

// ❌ 错误 - 没有保护
function initialize(address owner_) external {
    s.owner = owner_; // 可以被重复调用！
}
```

### ⚠️ 升级授权

```solidity
// ✅ 正确 - 有授权检查
function _authorizeUpgrade() internal view override {
    require(msg.sender == AppStorage.layout().owner, "not owner");
}

// ❌ 错误 - 没有检查
function _authorizeUpgrade() internal view override {
    // 任何人都可以升级！
}
```

---

## 相关文档

- [Proxy 模式详解](../02-proxy-pattern.md)
- [存储模式指南](../guides/storage-patterns.md)
- [升级指南](../guides/upgrading-contracts.md)
