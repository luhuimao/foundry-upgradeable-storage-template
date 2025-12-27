# Foundry Upgradeable Storage Template - Documentation

欢迎来到 **Foundry Upgradeable Storage Template** 文档！

本项目提供了生产级的可升级智能合约模板，支持 **UUPS Proxy (EIP-1967)** 和 **Diamond (EIP-2535)** 两种架构模式，并内置自动化存储冲突检测。

---

## 📚 文档导航

### 🏗️ 架构文档

1. [**架构概览**](01-architecture-overview.md) - 项目目标、架构对比、存储安全策略
2. [**Proxy 模式详解**](02-proxy-pattern.md) - UUPS/EIP-1967 实现细节
3. [**Diamond 模式详解**](03-diamond-pattern.md) - EIP-2535 Diamond 实现

### 📖 API 参考

- [**Proxy 合约 API**](api/proxy-contracts.md) - ERC1967Proxy, UUPSUpgradeable, TokenV1, AppStorage
- [**Diamond 合约 API**](api/diamond-contracts.md) - Diamond, Facets, Storage Libraries

### 🎓 开发指南

- [**快速开始**](guides/getting-started.md) - 安装、测试、部署
- [**存储模式**](guides/storage-patterns.md) - 命名存储槽、存储库模式、防止冲突
- [**合约升级**](guides/upgrading-contracts.md) - 如何安全地升级合约
- [**测试指南**](guides/testing.md) - 测试结构、存储布局测试

### 🔬 高级主题

- [**存储冲突检测**](advanced/storage-collision-detection.md) - 自动化检测机制
- [**安全考虑**](advanced/security-considerations.md) - 常见陷阱、审计清单

---

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/luhuimao/foundry-upgradeable-storage-template
cd foundry-upgradeable-storage-template

# 安装依赖
forge install

# 编译合约
forge build

# 运行测试
forge test
```

---

## 💡 核心特性

- ✅ **UUPS Proxy** - EIP-1967 标准实现
- ✅ **Diamond Pattern** - EIP-2535 多 facet 架构
- ✅ **命名存储** - 使用 keccak256 命名空间隔离存储
- ✅ **自动化检测** - CI 就绪的存储布局差异检测
- ✅ **Facet 状态检测** - 确保 facet 无状态变量
- ✅ **Foundry 原生** - 完全基于 Foundry 工作流
- ✅ **审计友好** - 清晰的代码结构和文档

---

## 🎯 为什么选择这个模板？

大多数可升级合约的失败**不是由重入或数学错误引起的**，而是由**升级过程中引入的存储布局冲突**导致的。

本模板通过设计强制执行存储安全：

- 🔒 **命名存储槽** - 避免存储冲突
- 🔍 **自动化测试** - 检测状态变量和布局变化
- 📐 **存储库模式** - 集中管理存储结构
- 🛡️ **Facet 隔离** - Diamond 模式中的存储隔离

---

## 📂 项目结构

```
foundry-upgradeable-storage-template/
├── src/
│   ├── proxy/              # UUPS Proxy 实现
│   │   ├── ERC1967Proxy.sol
│   │   └── UUPSUpgradeable.sol
│   ├── diamond/            # Diamond 实现
│   │   ├── Diamond.sol
│   │   ├── facets/         # Diamond facets
│   │   └── storage/        # 存储库
│   └── app/                # 应用层合约
│       ├── AppStorage.sol
│       └── TokenV1.sol
├── test/                   # 测试文件
│   ├── proxy/
│   └── diamond/
└── docs/                   # 文档（本目录）
```

---

## 🤝 贡献

欢迎贡献！请查看各个指南了解如何扩展此模板。

---

## 📄 许可证

MIT License - 详见 [LICENSE](../LICENSE)

---

## 🔗 相关资源

- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [EIP-2535: Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins/1.x/)
