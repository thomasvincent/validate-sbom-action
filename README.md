# validate-sbom-action

GitHub Action to validate SBOM files against official CycloneDX and SPDX JSON schemas using ajv-cli.

## Supported Formats

| Format | Versions |
|--------|----------|
| CycloneDX | 1.4, 1.5, 1.6, 1.7 |
| SPDX | 2.2, 2.3 |

## Usage

### Basic validation with auto-detection

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  with:
    input-file: sbom.json
```

### Explicit format and version

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  with:
    input-file: cyclonedx-sbom.json
    format: cyclonedx
    version: 1.6
```

### With outputs

```yaml
- uses: thomasvincent/validate-sbom-action@v1
  id: validate
  with:
    input-file: sbom.json

- name: Check result
  run: |
    echo "Valid: ${{ steps.validate.outputs.valid }}"
    echo "Format: ${{ steps.validate.outputs.format }}"
    echo "Version: ${{ steps.validate.outputs.spec-version }}"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `input-file` | yes | — | Path to SBOM file |
| `format` | no | `auto` | `cyclonedx`, `spdx`, or `auto` |
| `version` | no | `auto` | Spec version or `auto` |
| `strict` | no | `true` | Strict schema validation |

## Outputs

| Output | Description |
|--------|-------------|
| `valid` | `true` or `false` |
| `format` | Detected format |
| `spec-version` | Detected spec version |
| `error-count` | Number of validation errors |

## How It Works

Schemas are vendored in-repo from official CycloneDX/specification and spdx/spdx-spec repositories. Validation runs locally via ajv-cli with no network calls at validation time.

## Schema Updates

To update vendored schemas:

```bash
./scripts/update-schemas.sh
```

This fetches the latest schemas from upstream and stores them in `schemas/`.

## License

Apache-2.0
