# VEX Reports Repository

EVERTRUST shares its internal security team findings after qualifying and evaluating vulnerabilities impacts. This repository contains vulnerability exchange (VEX) reports for Evertrust products, alongside with common ignore file formats designed for easing usage with vulnerability scanners.

## Ignore files

Ignore files are published through releases named `vulns-YYYY-MM-DD`. Each release includes:

- CSV files for each product (e.g., `oci_horizon.csv`) that lists ignored vulnerabilities and the justification;
- Trivy ignore files for each product (e.g., `oci_horizon.trivyignore.yaml`) that can be used by Trivy:
  ```
  $ trivy image --ignorefile ./.trivyignore.yaml registry.evertrust.io/horizon:test
  ```
- Build metadata (`build_info.txt`)

[![Latest Release](https://img.shields.io/github/v/release/evertrust/vex?label=Latest%20VEX%20Reports)](https://github.com/evertrust/vex/releases/latest)

[Download Latest Reports](https://github.com/evertrust/vex/releases/latest)
