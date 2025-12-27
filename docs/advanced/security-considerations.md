# 安全考虑

本文档涵盖可升级合约的安全最佳实践和常见陷阱。

---

## 🎯 核心安全原则

1. 🔒 **最小权限** - 限制升级权限
2. 🔒 **时间锁** - 延迟关键操作
3. 🔒 **多签控制** - 分散权力
4. 🔒 **透明度** - 公开升级计划
5. 🔒 **审计** - 专业安全审查

---

## ⚠️ 常见陷阱

### 1. 存储冲突

#### 问题

```solidity
// V1
contract TokenV1 {
    address owner;      // slot 0
    uint256 totalSupply; // slot 1
}

// V2 - 危险！
contract TokenV2 {
    uint256 totalSupply; // slot 0 ⚠️ 数据错位
    address owner;       // slot 1 ⚠️ 数据错位
}
```

#### 解决方案

使用命名存储模式：

```solidity
library AppStorage {
    bytes32 constant SLOT = keccak256("app.storage.v1");
    
    struct Layout {
        address owner;
        uint256 totalSupply;
    }
}
```

---

### 2. 未初始化的实现合约

#### 问题

```solidity
// 实现合约未初始化，可能被攻击者初始化
contract TokenV1 is UUPSUpgradeable {
    function initialize(address owner) external {
        AppStorage.layout().owner = owner;
    }
}
```

#### 解决方案

在部署时立即初始化或使用构造函数禁用：

```solidity
contract TokenV1 is UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address owner) external initializer {
        AppStorage.layout().owner = owner;
    }
}
```

---

### 3. 选择器冲突（Diamond）

#### 问题

```solidity
// 两个 facets 有相同的函数签名
contract FacetA {
    function transfer(address to, uint256 amount) external {}
}

contract FacetB {
    function transfer(address to, uint256 amount) external {}
}
```

#### 解决方案

- 使用唯一的函数名
- 在注册时检查冲突
- 文档化所有 selector 映射

---

### 4. 缺少升级授权

#### 问题

```solidity
// ❌ 任何人都可以升级
function _authorizeUpgrade() internal view override {
    // 空实现
}
```

#### 解决方案

```solidity
// ✅ 只有 owner 可以升级
function _authorizeUpgrade() internal view override {
    require(msg.sender == AppStorage.layout().owner, "not owner");
}
```

---

### 5. 使用 selfdestruct

#### 问题

```solidity
// ❌ 在实现合约中使用 selfdestruct
contract TokenV1 {
    function destroy() external {
        selfdestruct(payable(msg.sender)); // 危险！
    }
}
```

#### 影响

- 实现合约被销毁
- 代理变成僵尸合约
- 所有资金丢失

#### 解决方案

**永远不要在实现合约中使用 `selfdestruct`！**

---

### 6. 使用 delegatecall 到不可信合约

#### 问题

```solidity
// ❌ 允许调用任意合约
function execute(address target, bytes calldata data) external {
    (bool success,) = target.delegatecall(data);
    require(success);
}
```

#### 影响

- 攻击者可以修改存储
- 可以窃取资金
- 可以破坏合约

#### 解决方案

- 只 delegatecall 到已知的可信合约
- 使用白名单
- 添加严格的权限检查

---

## 🛡️ 安全最佳实践

### 1. 使用多签钱包

```solidity
// 使用 Gnosis Safe 作为 owner
address constant MULTISIG = 0x...;

function _authorizeUpgrade() internal view override {
    require(msg.sender == MULTISIG, "not multisig");
}
```

**优势**：
- 分散权力
- 防止单点故障
- 增加透明度

---

### 2. 实现时间锁

```solidity
library AppStorage {
    struct Layout {
        address owner;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        
        // 时间锁
        address pendingImplementation;
        uint256 upgradeTimestamp;
    }
}

contract TokenV2 is UUPSUpgradeable {
    uint256 constant TIMELOCK_DURATION = 2 days;
    
    event UpgradeProposed(address indexed implementation, uint256 executeTime);
    event UpgradeExecuted(address indexed implementation);
    
    function proposeUpgrade(address newImpl) external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(msg.sender == s.owner, "not owner");
        
        s.pendingImplementation = newImpl;
        s.upgradeTimestamp = block.timestamp + TIMELOCK_DURATION;
        
        emit UpgradeProposed(newImpl, s.upgradeTimestamp);
    }
    
    function executeUpgrade() external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(msg.sender == s.owner, "not owner");
        require(block.timestamp >= s.upgradeTimestamp, "timelock");
        require(s.pendingImplementation != address(0), "no pending");
        
        address impl = s.pendingImplementation;
        s.pendingImplementation = address(0);
        
        _upgradeTo(impl);
        
        emit UpgradeExecuted(impl);
    }
    
    function cancelUpgrade() external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(msg.sender == s.owner, "not owner");
        
        s.pendingImplementation = address(0);
        s.upgradeTimestamp = 0;
    }
}
```

---

### 3. 添加紧急暂停

```solidity
library AppStorage {
    struct Layout {
        address owner;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        bool paused;
    }
}

contract TokenV2 {
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    
    modifier whenNotPaused() {
        require(!AppStorage.layout().paused, "paused");
        _;
    }
    
    function pause() external {
        require(msg.sender == AppStorage.layout().owner, "not owner");
        AppStorage.layout().paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() external {
        require(msg.sender == AppStorage.layout().owner, "not owner");
        AppStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
    
    function mint(address to, uint256 amount) external whenNotPaused {
        // ...
    }
}
```

---

### 4. 事件日志

```solidity
contract TokenV2 is UUPSUpgradeable {
    event Upgraded(address indexed implementation);
    event OwnershipTransferred(address indexed from, address indexed to);
    event Minted(address indexed to, uint256 amount);
    
    function upgradeTo(address newImplementation) external override {
        _authorizeUpgrade();
        _upgradeTo(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    function transferOwnership(address newOwner) external {
        AppStorage.Layout storage s = AppStorage.layout();
        require(msg.sender == s.owner, "not owner");
        
        address oldOwner = s.owner;
        s.owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
```

---

### 5. 输入验证

```solidity
function mint(address to, uint256 amount) external {
    require(to != address(0), "mint to zero address");
    require(amount > 0, "mint zero amount");
    require(amount <= type(uint128).max, "amount too large");
    
    AppStorage.Layout storage s = AppStorage.layout();
    require(msg.sender == s.owner, "not owner");
    
    s.totalSupply += amount;
    s.balances[to] += amount;
}
```

---

## 📋 审计清单

### 部署前检查

- [ ] 所有状态变量都在存储库中
- [ ] 实现合约没有状态变量
- [ ] 升级授权已正确实现
- [ ] 初始化函数有保护
- [ ] 没有使用 selfdestruct
- [ ] 没有不安全的 delegatecall
- [ ] 所有公共函数有权限检查
- [ ] 事件日志完整
- [ ] 输入验证充分
- [ ] 测试覆盖率 > 90%

### 升级前检查

- [ ] 存储布局兼容
- [ ] 新字段只在末尾添加
- [ ] 没有修改现有字段
- [ ] 存储布局测试通过
- [ ] 升级测试通过
- [ ] 数据迁移脚本（如需要）
- [ ] 回滚计划
- [ ] 在测试网验证

### 安全审计

- [ ] 代码审查
- [ ] 静态分析
- [ ] 动态测试
- [ ] 形式化验证（关键合约）
- [ ] 第三方审计（生产环境）

---

## 🔍 安全工具

### 静态分析

```bash
# Slither
slither src/

# Mythril
myth analyze src/app/TokenV1.sol
```

### 测试覆盖率

```bash
# Foundry 覆盖率
forge coverage

# 详细报告
forge coverage --report lcov
genhtml lcov.info -o coverage
```

### Gas 优化

```bash
# Gas 报告
forge test --gas-report

# Gas 快照
forge snapshot
```

---

## 🚨 应急响应

### 发现漏洞时

1. **立即暂停合约**（如果有暂停功能）
2. **评估影响范围**
3. **通知用户**
4. **准备修复**
5. **部署补丁**
6. **事后分析**

### 暂停模板

```solidity
function emergencyPause() external {
    require(msg.sender == EMERGENCY_ADMIN, "not admin");
    AppStorage.layout().paused = true;
    emit EmergencyPause(msg.sender, block.timestamp);
}
```

---

## 📚 参考资源

### 官方文档

- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins/)
- [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967)
- [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)

### 安全指南

- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)

### 审计公司

- Trail of Bits
- OpenZeppelin
- Consensys Diligence
- Certora

---

## 🔗 相关文档

- [存储模式指南](../guides/storage-patterns.md)
- [升级指南](../guides/upgrading-contracts.md)
- [存储冲突检测](storage-collision-detection.md)
