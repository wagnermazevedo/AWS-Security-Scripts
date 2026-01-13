# AWS Security Automation — Foundation / Bootstrap

Before scanning and fixing security issues, there is a more fundamental problem to solve:

**standardization.**

This repository defines a shared foundation for AWS security automation, providing a consistent execution model, versioned outputs, and a reusable repository structure for scanners and remediation scripts.

> **Important:** this is a GitHub template.  
> Each security automation module is created as its own repository using this template, and each repository contains the full directory structure inside itself.

Without a common foundation, security automation quickly becomes a collection of disconnected scripts.  
This project turns those scripts into a cohesive, auditable framework.

---

## Project Goals

This foundational release focuses on:

- Establishing a single execution contract for all scripts
- Producing versioned, auditable outputs
- Enabling reuse across:
  - Multi-account environments
  - CI/CD pipelines
  - Athena and reporting workflows
  - Remediation-as-Code
- Creating a scalable base for future security automation releases

This is the cornerstone of the entire series.

---

## Execution Contract (Scan / Plan / Remediate)

All projects created from this template follow the same contract:

- **Scan (read-only)**  
  Produces findings and evidence. Never mutates state.

- **Plan (optional, non-mutating)**  
  Transforms findings into proposed actions (preview of impact and changes).

- **Remediate (state-changing, controlled)**  
  Applies changes explicitly and **supports dry-run**.  
  Produces remediation evidence (**planned vs applied**).

**Key rule:** no remediation happens accidentally — even remediation supports **dry-run first**.

---

## Repository Structure

Every repository created from this template includes this structure **inside the repository itself**:

```text
aws-security-automation-<module>/
├── scanner/        # Detection scripts (read-only)
├── remediate/      # Remediation scripts (supports dry-run)
├── lab_insecure/   # Intentionally insecure resources for testing
├── reports/        # Consolidated reports and summaries
├── outputs/        # Versioned execution outputs (immutable)
├── lib/            # Shared helpers (CLI, AWS clients, writers, validators)
└── docs/           # Documentation, diagrams, and guides
