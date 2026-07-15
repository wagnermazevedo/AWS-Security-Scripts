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

## Output Strategy

All executions generate **immutable, timestamped outputs**:

- Outputs are never overwritten
- Each execution is independently auditable
- Machine-readable by default

**Recommended formats include:**

- **JSON** — source of truth
- **CSV** — analytics and Athena queries
- **Markdown** — human-readable summaries

Outputs are designed to integrate with **Athena**, **CI/CD pipelines**, **SIEM/SOAR platforms**, and **audit workflows**.

---

## How This Template Is Used

1. Click **Use this template** on GitHub
2. Create a new repository for a specific security domain
3. Implement logic under:
   - `scanner/`
   - `remediate/`
   - `lab_insecure/`
4. Keep the execution contract and output structure intact

Each module is **self-contained**, but all modules **behave consistently**.

---

## **Reference Implementations**

The following repositories were created using this foundation and demonstrate how the template is applied in real security automation projects:

- **Security Hub as Control Plane**  
  https://github.com/wagnermazevedo/Security-Control-Plane *(planned)*

- **IAM & Identity as Control Plane**  
  https://github.com/wagnermazevedo/IAM-Identity-as-Control-Plane  *(planned)*
  **(Includes CIEM / Privilege Management capabilities)**

- **AWS Governance as Control Plane**  
  https://github.com/wagnermazevedo/AWS-Governance-Control-Plane *(planned)*

- **Software Defined Perimeter as Control Plane**  
  https://github.com/wagnermazevedo/Software-Defined-Perimeter-as-Control-Plane *(planned)*

- **PaaS & Managed Services Permissions Control Plane**  
  *(CodeBuild, CodeDeploy, SageMaker, RDS)*  
  https://github.com/wagnermazevedo/PaaS-Permissions-Control-Plane *(planned)*

- **Network Traffic & Security Policy Analysis Control Plane**  
  *(VPC routing, Security Groups, NACLs, exposed ports)*  
  https://github.com/wagnermazevedo/Network-Security-Control-Plane *(planned)*

- **Leaked Credentials & Exposure Monitoring Control Plane**  
  *(HIBP, dark web sources, access key validation & remediation)*  
  https://github.com/wagnermazevedo/Credential-Exposure-Control-Plane *(planned)*

---

### **Strategic Note**
Each repository:
- follows the same **execution contract** (**scan → plan → remediate**)
- produces **versioned outputs**
- can be used **independently** or as part of a **unified Security Control Plane ecosystem**
-

## Next Releases

This foundation enables future security automation modules, including:

- **Security Hub as Control Plane**
- **IAM & Identity as Control Plane**
- Network and data security automation
- Identity, permission, and governance guardrails

Each release is implemented as an **independent repository** built from this same template.

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
