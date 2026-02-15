# validate-sbom-action

Validate SBOM files against official CycloneDX and SPDX JSON schemas. Offline. No network calls at validation time.

[![CI](https://github.com/thomasvincent/validate-sbom-action/actions/workflows/ci.yml/badge.svg)](https://github.com/thomasvincent/validate-sbom-action/actions/workflows/ci.yml)
[![GitHub Marketplace](https://img.shields.io/badge/marketplace-validate--sbom--action-blue?logo=github)](https://github.com/marketplace/actions/validate-sbom)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Usage

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  with:
    input-file: sbom.json
```

The action auto-detects format (CycloneDX or SPDX) and spec version from the file. It exits non-zero if validation fails.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `input-file` | yes | -- | Path to the SBOM JSON file |
| `format` | no | `auto` | `cyclonedx`, `spdx`, or `auto` (detect from file) |
| `version` | no | `auto` | Spec version (e.g., `1.6`, `2.3`) or `auto` (detect from file) |

## Outputs

| Output | Description |
|--------|-------------|
| `valid` | `true` if the SBOM passes schema validation, `false` otherwise |
| `format` | Detected format: `cyclonedx` or `spdx` |
| `spec-version` | Detected spec version (e.g., `1.6`, `2.3`) |
| `error-count` | Approximate number of validation errors (0 when valid) |

## Supported Formats

| Format | Versions |
|--------|----------|
| CycloneDX | 1.4, 1.5, 1.6, 1.7 |
| SPDX | 2.2, 2.3 |

JSON only. XML SBOMs are not supported.

## Failure Modes

The action exits with code 1 and sets `valid=false` in these cases:

| Condition | Error message |
|-----------|---------------|
| File does not exist | `Input file not found: <path>` |
| File is not valid JSON | `Input file is not valid JSON: <path>` |
| Format cannot be detected | `Unable to detect SBOM format` |
| Version cannot be detected | `Unable to detect CycloneDX specVersion` / `Unable to detect SPDX version` |
| No schema for detected version | `Schema file not found for <format> <version>` |
| Schema validation fails | ajv-cli error output with details |

All failure paths write outputs (`valid=false`, `error-count=1`) before exiting, so downstream steps can read them even on failure with `continue-on-error: true`.

## Examples

### Explicit format and version

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  with:
    input-file: cyclonedx-sbom.json
    format: cyclonedx
    version: '1.6'
```

### Read outputs

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  id: sbom
  with:
    input-file: sbom.json
  continue-on-error: true

- run: |
    echo "Valid: ${{ steps.sbom.outputs.valid }}"
    echo "Format: ${{ steps.sbom.outputs.format }}"
    echo "Version: ${{ steps.sbom.outputs.spec-version }}"
    echo "Errors: ${{ steps.sbom.outputs.error-count }}"
```

### Validate multiple files

```yaml
strategy:
  fail-fast: false
  matrix:
    sbom:
      - path: sbom-backend.json
        format: cyclonedx
      - path: sbom-frontend.json
        format: spdx
steps:
  - uses: actions/checkout@v4
  - uses: thomasvincent/validate-sbom-action@v1
    with:
      input-file: ${{ matrix.sbom.path }}
      format: ${{ matrix.sbom.format }}
```

### PR gating

```yaml
name: SBOM Gate

on:
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  validate-sbom:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: thomasvincent/validate-sbom-action@v1
        id: sbom
        with:
          input-file: sbom.json
      - name: Summary
        if: always()
        run: |
          echo "### SBOM Validation" >> "$GITHUB_STEP_SUMMARY"
          echo "- **Valid:** ${{ steps.sbom.outputs.valid }}" >> "$GITHUB_STEP_SUMMARY"
          echo "- **Format:** ${{ steps.sbom.outputs.format }}" >> "$GITHUB_STEP_SUMMARY"
          echo "- **Version:** ${{ steps.sbom.outputs.spec-version }}" >> "$GITHUB_STEP_SUMMARY"
```

## Security Model

- **No network calls at validation time.** Schemas are vendored in the repository. The only network call is `npm install ajv-cli ajv-formats` during setup.
- **No telemetry.** The action does not phone home or collect data.
- **Runs in the job container.** No Docker pull, no external services.
- **Least privilege.** Requires only `contents: read`.

For higher assurance, pin to a full commit SHA:

```yaml
- uses: thomasvincent/validate-sbom-action@46e800d6e8da6a10d3dc8ab21baabb8f6e8320a0 # v1
```

## Compatibility

- Runs on `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-24.04`.
- Requires Node.js (pre-installed on all GitHub-hosted runners).
- Requires `jq` (pre-installed on all GitHub-hosted runners).
- Self-hosted runners need Node.js >= 18 and jq in PATH.

## Schema Updates

To refresh vendored schemas from upstream:

```bash
./scripts/update-schemas.sh
```

## License

Apache-2.0 -- see [LICENSE](LICENSE).
