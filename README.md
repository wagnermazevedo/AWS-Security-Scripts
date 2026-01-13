AWS Security Automation — Foundation / Bootstrap
Overview

Before scanning and fixing security issues, there is a more fundamental problem to solve:

standardization.

Security automation often starts as a set of isolated scripts — each with its own execution model, output format, and assumptions. Over time, this leads to fragile tooling, limited auditability, and poor scalability.

This repository defines a shared foundation and reference model for AWS security automation.

It does not centralize all scanners and remediations in a single codebase.
Instead, it establishes a repeatable project template that is implemented inside each security automation repository.

Without a common foundation, automation becomes difficult to govern and unsafe to scale.
This project turns individual scripts into cohesive, auditable, and enterprise-ready security automation projects.

This is Release 0 — the base layer for all upcoming security automation releases.

Design Principles

This foundation is built on the following principles:

Consistency over convenience

Auditability by default

Clear separation between detection and mutation

Dry-run first, apply explicitly

Evidence-first automation

Security at scale starts with discipline.

Project Goals

This foundational release focuses on:

Defining a standard project layout to be reused across repositories

Establishing a single execution contract for all security scripts

Enforcing clear separation of concerns:

Scan (detect)

Plan (optional, non-mutating)

Remediate (state-changing)

Producing versioned, timestamped outputs for every execution

Enabling reuse across:

Multi-account AWS Organizations

CI/CD pipelines

Athena-based reporting

Remediation-as-Code workflows

Creating a scalable and composable base for future security automation modules

This repository is the cornerstone template of the entire series.

Execution Model (Contract)

Every security automation project that adopts this foundation follows the same execution contract:

Scanner

Read-only

No state mutation

Produces structured, machine-readable output

Planner (optional)

Transforms findings into proposed actions

Always non-mutating

Used to preview impact and decision paths

Remediator

Applies changes explicitly

Supports dry-run execution

Requires explicit confirmation or flags to enforce changes

Produces remediation evidence (planned vs applied)

This model guarantees that no change happens accidentally, even at the remediation stage.

Standard Project Structure (Replicated per Repository)

Each security automation module (for example: Security Hub, IAM & Identity, Network, Data) is implemented as an independent repository.

Each repository replicates the same internal structure defined by this foundation:

aws-security-automation-<module>/
├── scanner/          # Detection scripts (read-only)
├── remediate/        # Remediation scripts (supports dry-run and apply)
├── lab_insecure/     # Intentionally insecure resources for validation
├── outputs/          # Versioned, immutable execution outputs
│   ├── scanner/
│   │   └── YYYY/MM/DD/
│   ├── plan/
│   │   └── YYYY/MM/DD/
│   └── remediate/
│       └── YYYY/MM/DD/
├── reports/          # Aggregated and human-readable reports
├── lib/              # Shared helpers (CLI, AWS clients, writers, validators)
├── docs/             # Module-specific documentation and diagrams
└── README.md


This guarantees that every module looks, behaves, and reports in the same way, regardless of the security domain.

Output Strategy

Every execution generates immutable, timestamped outputs inside the project repository:

Outputs are never overwritten

Each run is independently auditable

Data is safe for forensics and compliance reviews

Primary output formats:

JSON (source of truth)

CSV (analytics and Athena)

Markdown (human-readable summaries)

Outputs are designed to integrate naturally with:

Amazon Athena

SIEM / SOAR platforms

CI/CD pipelines

Governance, risk, and compliance tooling

What Comes Next

With this foundation in place, future releases become predictable and composable:

Security Hub as Control Plane

IAM & Identity as Control Plane

Network, Data, and Application Security Modules

Each release is a self-contained repository that inherits this foundation — no divergence, no reinvention.

Final Note

This foundation intentionally favors boring structure and strict discipline.

That discipline is what makes security automation safe, scalable, and enterprise-ready.
