# AWS Security Automation — Foundation / Bootstrap

Before scanning and fixing security issues, there is a more fundamental problem to solve:

**standardization.**

This repository defines a shared foundation for AWS security automation, providing a consistent execution model, versioned outputs, and a reusable repository structure for scanners and remediation scripts.

> **Important:** This is a GitHub template.  
> Each security automation module is created as its own repository using this template, and each repository contains the full directory structure inside itself.

Without a common foundation, security automation quickly becomes a collection of disconnected scripts. This project turns those scripts into a cohesive, auditable framework.

---

## Project Goals

This foundational release focuses on:

* **Establishing a single execution contract** for all scripts.
* **Producing versioned, auditable outputs** to maintain an immutable history of events.
* **Enabling reuse across scaling environments:**
  * Multi-account environments
  * CI/CD pipelines
  * Athena analytics and reporting workflows
  * Remediation-as-Code (RaC) architectures
* **Creating a scalable base** for future security automation releases.

This framework serves as the definitive cornerstone for the entire automation series.

---

## Execution Contract (Scan / Plan / Remediate)

All projects created from this template follow a predictable, three-phase contract:

* **Scan (Read-Only)**  
  Produces granular findings and cryptographic evidence. It never mutates state or environment configurations.
* **Plan (Optional, Non-Mutating)**  
  Transforms raw scanner findings into proposed operational actions, acting as a preview of impact and changes.
* **Remediate (State-Changing, Controlled)**  
  Applies engineering changes explicitly and **strictly supports dry-run mode**. Produces precise remediation evidence (**planned vs. applied**).

> **Key Rule:** No remediation happens accidentally — every single control plane execution supports and encourages **dry-run validation first**.

---

## Automated Verification & Control Plane Testing

To guarantee that each security control behaves exactly as designed, this template introduces an automated testing layer driven by the `test-control-plane.sh` script.

This script acts as the core verification engine for the module, validating the entire lifecycle of each security control against live or simulated environments using a 4-step sequence:

1. **Deploying the Insecure State:** It coordinates with the `lab_insecure/` directory to deploy intentionally vulnerable resources, simulating a real-world drift or compliance failure.
2. **Validating Detection (Scan):** It triggers the `scanner/` scripts to verify that the control plane accurately flags the vulnerability and logs the findings properly.
3. **Evaluating the Strategy (Plan):** It tests the `plan` phase to ensure the proposed mitigation matches your architectural guardrails without mutating resources.
4. **Applying and Verifying Remediation (Remediate):** It executes the `remediate/` scripts (first in `dry-run`, then in enforcement mode) and verifies that the vulnerable state has been successfully corrected.

By running `test-control-plane.sh`, you ensure a reliable, rapid feedback loop for developing, testing, and auditing security guardrails locally before promoting them to production pipelines.

---

## Deployment & Replication via AWS CloudShell

AWS CloudShell provides a pre-authenticated, browser-based shell that already has the AWS CLI and Git installed, making it the ideal environment to replicate your entire control plane ecosystem.

Instead of cloning repositories individually, you can use the GitHub CLI (`gh`) already built-in or authenticated inside CloudShell to replicate all related control plane repositories in batch, and then execute the local verification suite.

### Step-by-Step Environment Replication

* **Step 1: Authenticate and Clone in Batch**  
  Authenticate your GitHub session if required, and execute the discovery loop to automatically clone all security control plane repositories matching your ecosystem profile:
  ```bash
  # Bulk clone all ecosystem control planes at once
  for repo in $(gh repo list -L 100 --json nameWithOwner -q '.[].nameWithOwner' | grep -E 'AWS|Plane'); do
      gh repo clone "$repo"
  done
  ```

* **Step 2: Navigate and Configure Target Module**  
  Enter the specific control plane folder you intend to test and grant execution permissions to the core testing orchestrator:
  ```bash
  cd Security-Control-Plane
  chmod +x test-control-plane.sh
  ```

* **Step 3: Execute Verification Suite**  
  Run the test automation engine to deploy the laboratory infrastructure, validate detection metrics, and perform dry-run remediation:
  ```bash
  ./test-control-plane.sh
  ```

---

## Output Strategy

All executions generate **immutable, timestamped outputs**:

* Outputs are never overwritten, ensuring historical integrity.
* Each execution sequence is independently auditable.
* Machine-readable by default to simplify aggregation.

**Recommended formats include:**
* **JSON** — The definitive source of truth for raw execution data.
* **CSV** — Structured data optimal for analytical ingestion and Athena queries.
* **Markdown** — Clean, human-readable summaries designed for quick engineering triage.

Outputs integrate natively with **Amazon Athena**, **CI/CD deployment gates**, **SIEM/SOAR platforms**, and engineering **audit workflows**.

---

## How This Template Is Used

1. Click **Use this template** on the upstream GitHub repository.
2. Create a new repository tailored to a specific security domain.
3. Implement your custom infrastructure domain logic under:
   * `scanner/`
   * `remediate/`
   * `lab_insecure/`
4. Run `./test-control-plane.sh` (locally or via bulk execution in **AWS CloudShell**) to validate your control plane implementations end-to-end.
5. Keep the execution contract and immutable output structure intact.

Each module remains completely **self-contained**, but all modules across your landing zone **behave consistently**.

---

## Reference Implementations

The following repositories form the core ecosystem created using this foundation and demonstrate how the template applies across distinct security pillars:

* **AWS Security Scripts** — [Link](https://github.com/wagnermazevedo/AWS-Security-Scripts)
* **Security Hub as Control Plane** — [Link](https://github.com/wagnermazevedo/Security-Control-Plane)
* **IAM & Identity as Control Plane** *(Includes CIEM / Privilege Management)* — [Link](https://github.com/wagnermazevedo/IAM-Identity-as-Control-Plane)
* **AWS Governance as Control Plane** — [Link](https://github.com/wagnermazevedo/AWS-Governance-as-Control-Plane)
* **Software Defined Perimeter as Control Plane** — [Link](https://github.com/wagnermazevedo/Software-Defined-Perimeter-as-Control-Plane)
* **PaaS & Managed Services Permissions Control Plane** *(CodeBuild, CodeDeploy, SageMaker, RDS)* — [Link](https://github.com/wagnermazevedo/PaaS-Managed-Services-Permissions-Control-Plane)
* **AWS Network Traffic as Control Plane** *(VPC routing, Security Groups, NACLs, exposed ports)* — [Link](https://github.com/wagnermazevedo/AWS-Network-Traffic-as-Control-Plane)
* **Credentials & Exposure Monitoring Control Plane** *(HIBP, access key validation & remediation)* — [Link](https://github.com/wagnermazevedo/Credential-Exposure-Control-Plane)

> **Strategic Note:** Each repository follows the same execution contract (`scan` → `plan` → `remediate`), leverages `test-control-plane.sh` for reliable regression testing of every control, and produces versioned outputs. They can be used **independently** or as part of a **unified Security Control Plane ecosystem**.

---

## Repository Structure

Every repository created from this template includes this exact structure inside itself:

```text
aws-security-automation-<module>/
├── test-control-plane.sh  # Test orchestration engine for security controls
├── scanner/               # Detection scripts (read-only)
├── remediate/             # Remediation scripts (supports dry-run)
├── lab_insecure/          # Intentionally insecure resources for testing
├── reports/               # Consolidated reports and summaries
├── outputs/               # Versioned execution outputs (immutable)
├── lib/                   # Shared helpers (CLI, AWS clients, writers, validators)
└── docs/                  # Documentation, architectural diagrams, and guides
```