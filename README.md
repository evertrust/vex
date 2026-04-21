# VEX Reports Repository

EVERTRUST shares its internal security team findings after qualifying and evaluating vulnerabilities impacts. This repository contains vulnerability exchange (VEX) reports for Evertrust products, alongside with common ignore file formats designed for easing usage with vulnerability scanners.

## Release reports

Reports are published through releases named `vulns-YYYY-MM-DD`. Each release includes:

- a standalone OpenVEX document (`openvex.json`) that merges every package document;
- CSV files for each product (e.g., `oci_horizon.csv`) that lists ignored vulnerabilities and the justification;
- Trivy ignore files for each product (e.g., `oci_horizon.trivyignore.yaml`) that can be used by Trivy:
  ```
  $ trivy image --ignorefile ./.trivyignore.yaml registry.evertrust.io/horizon:test
  ```
- Generation metadata (`build_info.txt`)

[![Latest Release](https://img.shields.io/github/v/release/evertrust/vex?label=Latest%20VEX%20Reports)](https://github.com/evertrust/vex/releases/latest)

[Download Latest Reports](https://github.com/evertrust/vex/releases/latest)

## Maintainer workflow

This repository uses [mise](https://mise.jdx.dev/) to pin maintainer tools. Install the
configured tools from the repository root:

```sh
mise install
```

This installs `vexctl` and `jq` from the versions pinned in `mise.toml`.

Generate the release reports from every OpenVEX document under `pkg/`:

```sh
mise run generate-reports
```

You can also regenerate one report type at a time:

```sh
mise run generate-standalone-json
mise run generate-csv-reports
mise run generate-trivyignore-files
```

## Qualify a CVE

Use the interactive task when qualifying a CVE in an existing OpenVEX document:

```sh
mise run qualify-cve
```

The task prompts for:

- the OpenVEX document to update;
- the product package URL;
- the CVE identifier;
- the VEX status;
- the justification when the status is `not_affected`;
- optional impact statement, status note, and subcomponents;
- final confirmation before writing the document.

You can also pass the required values directly:

```sh
mise run qualify-cve -- \
  pkg/golang/toolbox/openvex.json \
  pkg:golang/toolbox \
  CVE-2025-27144 \
  not_affected \
  vulnerable_code_not_present
```

Valid statuses are:

- `not_affected`
- `affected`
- `fixed`
- `under_investigation`

Valid `not_affected` justifications are:

- `component_not_present`
- `vulnerable_code_not_present`
- `vulnerable_code_not_in_execute_path`
- `vulnerable_code_cannot_be_controlled_by_adversary`
- `inline_mitigations_already_exist`

The task updates the selected OpenVEX document in place using `vexctl add`.

## Trivy VEX matching before image push

Trivy applies OpenVEX statements by matching product PURLs from the VEX document
against PURLs discovered during the scan.

For pushed container images, use the OCI product PURL and list vulnerable packages
as subcomponents:

```json
{
  "@id": "pkg:oci/horizon?repository_url=quay.io%2Fevertrust%2Fhorizon",
  "subcomponents": [
    {
      "@id": "pkg:maven/tools.jackson.core/jackson-core@3.0.1"
    }
  ]
}
```

This works when Trivy scans the image from the registry, for example:

```sh
trivy image --vex pkg/oci/horizon/openvex.json quay.io/evertrust/horizon:tag
```

Before the image is pushed, local scans can use a different target identity even
if the Docker image is tagged with the final registry name. In that case, Trivy
may not match a VEX statement scoped only to the OCI product PURL, and a
`not_affected` vulnerability can still appear in local scan output.

For pre-push local scans, also add the vulnerable package PURL as a direct
product in the same statement:

```json
{
  "products": [
    {
      "@id": "pkg:oci/horizon?repository_url=quay.io%2Fevertrust%2Fhorizon",
      "subcomponents": [
        {
          "@id": "pkg:maven/tools.jackson.core/jackson-core@3.0.1"
        }
      ]
    },
    {
      "@id": "pkg:maven/tools.jackson.core/jackson-core@3.0.1"
    }
  ],
  "status": "not_affected",
  "justification": "vulnerable_code_not_in_execute_path"
}
```

Use the package PURL exactly as Trivy reports it in JSON output:

```sh
trivy image --input ./image.tar --format json \
  | jq -r '.. | objects | select(.VulnerabilityID? == "CVE-2026-29062") | .PkgIdentifier.PURL'
```

Do not use `--show-suppressed` for pass/fail checks. That flag intentionally
prints vulnerabilities that VEX filtered out, and is only useful for debugging.

## Add a package to an existing document

If the package does not already exist in a document, use the same task and type the
new package URL when prompted for the product:

```sh
mise run qualify-cve
```

Or pass the new package URL directly:

```sh
mise run qualify-cve -- \
  pkg/golang/toolbox/openvex.json \
  pkg:golang/new-package \
  CVE-2026-12345 \
  not_affected \
  vulnerable_code_not_present
```

## Add a new OpenVEX document

Create a directory for the package and seed the first statement with `vexctl create`:

```sh
mkdir -p pkg/golang/new-package

mise exec -- vexctl create \
  --file pkg/golang/new-package/openvex.json \
  --author "Evertrust Security Team" \
  --product "pkg:golang/new-package" \
  --vuln "CVE-2026-12345" \
  --status "not_affected" \
  --justification "vulnerable_code_not_present" \
  --impact-statement "Explain why the package is not affected"
```

Then register the document in `index.json`:

```json
{
  "id": "pkg:golang/new-package",
  "location": "pkg/golang/new-package/openvex.json"
}
```

Finally, validate the JSON files and regenerate the release reports:

```sh
jq . index.json >/dev/null
mise run generate-reports
```
