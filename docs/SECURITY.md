# Security Model

This document defines the **explicit security assumptions and guarantees**
of this repository.

---

## 1. Threat Model

### In Scope

- Storage collisions
- Unauthorized upgrades
- Facet selector hijacking
- Delegatecall corruption

### Out of Scope

- Economic attacks
- Governance attacks
- Oracle manipulation
- Business logic flaws

---

## 2. Security Guarantees

This system guarantees:

- Deterministic storage ownership
- Upgrade-safe storage layout
- Facet isolation via namespaces
- CI-detected storage regressions

---

## 3. Known High-Risk Areas

### Storage Bugs

- Silent
- Irreversible after deployment
- Often discovered too late

### Upgrade Authority

- Owner key compromise = full control
- Multisig recommended

---

## 4. Real-World Failure Patterns

### Proxy Collision

- Implementation added variable
- Owner slot overwritten
- Protocol taken over

### Diamond Collision

- Two facets reused namespace
- Mapping overwritten
- Funds frozen permanently

---

## 5. Defensive Measures Implemented

- No implicit storage
- No inheritance-based layouts
- storageLayout enforced tests
- Namespace collision checks

---

## 6. Security Rules (Non-Negotiable)

1. Facets are stateless
2. Implementations are stateless
3. Storage is explicit
4. Tests are authoritative

Breaking any rule invalidates security assumptions.

---

## 7. Responsible Usage

This repository provides **infrastructure safety**, not protocol safety.

Security is a process, not a template.
