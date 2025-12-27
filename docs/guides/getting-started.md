# 快速开始

本指南将帮助你快速上手 Foundry Upgradeable Storage Template。

---

## 📋 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation) 已安装
- 基本的 Solidity 知识
- 了解代理模式概念（推荐但非必需）

---

## 🚀 安装

### 1. 克隆项目

```bash
git clone https://github.com/luhuimao/foundry-upgradeable-storage-template
cd foundry-upgradeable-storage-template
```

### 2. 安装依赖

```bash
forge install
```

这将安装项目依赖（主要是 forge-std 测试库）。

### 3. 编译合约

```bash
forge build
```

编译成功后，你会看到：

```
[⠊] Compiling...
[⠒] Compiling 35 files with Solc 0.8.20
[⠢] Solc 0.8.20 finished in 1.75s
Compiler run successful!
```

### 4. 运行测试

```bash
forge test
```

所有测试应该通过：

```
Ran 5 test suites: 9 tests passed, 0 failed, 0 skipped
```

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
│   │   ├── facets/
│   │   │   ├── ERC20Facet.sol
│   │   │   ├── AccessFacet.sol
│   │   │   └── DiamondManagementFacet.sol
│   │   └── storage/
│   │       ├── LibDiamond.sol
│   │       ├── LibERC20.sol
│   │       └── LibAccess.sol
│   └── app/                # 应用层合约
│       ├── AppStorage.sol
│       └── TokenV1.sol
├── test/                   # 测试文件
│   ├── proxy/
│   │   ├── TokenProxy.t.sol
│   │   └── StorageLayout.t.sol
│   └── diamond/
│       ├── DiamondBasic.t.sol
│       ├── FacetStorageCheck.t.sol
│       └── NamespaceCollision.t.sol
├── docs/                   # 文档
├── foundry.toml            # Foundry 配置
└── README.md
```

---

## 🎯 快速示例

### 示例 1: 使用 UUPS Proxy

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/proxy/ERC1967Proxy.sol";
import "../src/app/TokenV1.sol";

contract DeployProxy is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. 部署实现合约
        TokenV1 implementation = new TokenV1();
        
        // 2. 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            TokenV1.initialize.selector,
            msg.sender  // owner
        );
        
        // 3. 部署代理
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        // 4. 获取代理接口
        TokenV1 token = TokenV1(address(proxy));
        
        // 5. 使用代币
        token.mint(msg.sender, 1000 ether);
        
        vm.stopBroadcast();
        
        console.log("Proxy deployed at:", address(proxy));
        console.log("Implementation:", address(implementation));
    }
}
```

运行脚本：

```bash
forge script script/DeployProxy.s.sol --rpc-url $RPC_URL --broadcast
```

### 示例 2: 使用 Diamond

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/diamond/Diamond.sol";
import "../src/diamond/facets/ERC20Facet.sol";
import "../src/diamond/facets/AccessFacet.sol";

contract DeployDiamond is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. 部署 Diamond
        Diamond diamond = new Diamond(msg.sender);
        
        // 2. 部署 facets
        ERC20Facet erc20Facet = new ERC20Facet();
        AccessFacet accessFacet = new AccessFacet();
        
        // 3. 注册 facets (需要先注册管理 facet)
        // ... (参见完整示例)
        
        vm.stopBroadcast();
        
        console.log("Diamond deployed at:", address(diamond));
    }
}
```

---

## 🧪 运行测试

### 运行所有测试

```bash
forge test
```

### 运行特定测试文件

```bash
forge test --match-path test/proxy/TokenProxy.t.sol
```

### 运行特定测试函数

```bash
forge test --match-test test_mint_works
```

### 查看详细输出

```bash
forge test -vvv
```

### 查看 Gas 报告

```bash
forge test --gas-report
```

---

## 📊 测试覆盖率

查看测试覆盖率：

```bash
forge coverage
```

生成详细报告：

```bash
forge coverage --report lcov
```

---

## 🔍 常用命令

### 编译

```bash
# 编译所有合约
forge build

# 清理并重新编译
forge clean && forge build

# 查看编译输出大小
forge build --sizes
```

### 测试

```bash
# 运行所有测试
forge test

# 运行特定测试
forge test --match-contract TokenProxyTest

# 查看详细日志
forge test -vvvv

# 运行失败的测试
forge test --fail-fast
```

### 格式化

```bash
# 格式化代码
forge fmt

# 检查格式（不修改）
forge fmt --check
```

### 文档

```bash
# 生成 NatSpec 文档
forge doc

# 启动文档服务器
forge doc --serve
```

---

## 🛠️ 开发工作流

### 1. 创建新功能

```bash
# 1. 创建新的实现合约
touch src/app/TokenV2.sol

# 2. 编写代码
# ...

# 3. 编译
forge build

# 4. 编写测试
touch test/proxy/TokenV2.t.sol

# 5. 运行测试
forge test
```

### 2. 添加新 Facet

```bash
# 1. 创建存储库
touch src/diamond/storage/LibNewFeature.sol

# 2. 创建 facet
touch src/diamond/facets/NewFeatureFacet.sol

# 3. 编译和测试
forge build
forge test
```

---

## 🐛 调试技巧

### 使用 console.log

```solidity
import "forge-std/console.sol";

function test_debug() public {
    console.log("Value:", someValue);
    console.log("Address:", someAddress);
}
```

### 使用 vm.trace

```bash
forge test --match-test test_name -vvvv
```

### 检查存储布局

```bash
forge inspect TokenV1 storage-layout
```

---

## 📝 配置文件

### foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.20"

[profile.default.fuzz]
runs = 256

[profile.ci]
fuzz = { runs = 5000 }
```

---

## 🔗 下一步

现在你已经完成了基本设置，可以：

1. 📖 阅读 [架构概览](../01-architecture-overview.md) 了解设计理念
2. 🏗️ 学习 [Proxy 模式](../02-proxy-pattern.md) 或 [Diamond 模式](../03-diamond-pattern.md)
3. 💾 深入了解 [存储模式](storage-patterns.md)
4. 🔄 学习如何 [升级合约](upgrading-contracts.md)
5. 🧪 查看 [测试指南](testing.md) 编写更好的测试

---

## ❓ 常见问题

### Q: 为什么编译失败？

A: 确保你已经运行 `forge install` 安装依赖。

### Q: 测试失败怎么办？

A: 运行 `forge clean && forge build && forge test` 清理并重新编译。

### Q: 如何部署到测试网？

A: 参考 [部署指南](deploying.md)（待创建）。

---

## 💬 获取帮助

- 查看 [Foundry Book](https://book.getfoundry.sh/)
- 阅读项目文档
- 提交 GitHub Issue
