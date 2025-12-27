# Foundry Upgradeable Storage Template

A production-grade Foundry template for building **upgradeable Solidity contracts**
using **Proxy (EIP-1967 / UUPS)** and **Diamond (EIP-2535)** architectures,
with **automated storage collision detection**.

This repository focuses on one core problem:

> **Preventing storage layout corruption in upgradeable smart contracts.**

---

## Features

- ✅ Proxy (UUPS / EIP-1967) reference implementation
- ✅ Diamond (EIP-2535) with facet-level storage isolation
- ✅ Named storage (keccak256 namespace)
- ✅ Automated storage layout diff (CI-ready)
- ✅ Facet state-variable detection
- ✅ Foundry-native workflow
- ✅ Audit-friendly structure

---

## Why This Repo Exists

Most upgradeable contract failures are **not caused by reentrancy or math bugs**,
but by **storage layout collisions introduced during upgrades**.

This template enforces storage safety by design.

---

## Getting Started

```bash
git clone https://github.com/luhuimao/foundry-upgradeable-storage-template
cd foundry-upgradeable-storage-template
forge install
forge build
forge test
