#!/usr/bin/env bash
set -euo pipefail

# Resolve action path for both GitHub Actions and local execution
if [[ -n "${GITHUB_ACTION_PATH:-}" ]]; then
  ACTION_PATH="${GITHUB_ACTION_PATH}"
else
  ACTION_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Verify input file exists
if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Error: Input file not found: ${INPUT_FILE}" >&2
  exit 1
fi

# Verify file is valid JSON
if ! jq empty "${INPUT_FILE}" 2>/dev/null; then
  echo "Error: Input file is not valid JSON: ${INPUT_FILE}" >&2
  exit 1
fi

# Auto-detect format if needed
if [[ "${INPUT_FORMAT}" == "auto" ]]; then
  if [[ "$(jq -r '.bomFormat // empty' "${INPUT_FILE}")" == "CycloneDX" ]]; then
    FORMAT="cyclonedx"
  elif jq -e '.spdxVersion' "${INPUT_FILE}" >/dev/null 2>&1; then
    FORMAT="spdx"
  else
    echo "Error: Unable to detect SBOM format. Specify format explicitly." >&2
    exit 1
  fi
else
  FORMAT="${INPUT_FORMAT}"
fi

# Auto-detect version if needed
if [[ "${INPUT_VERSION}" == "auto" ]]; then
  if [[ "${FORMAT}" == "cyclonedx" ]]; then
    VERSION="$(jq -r '.specVersion // empty' "${INPUT_FILE}")"
    if [[ -z "${VERSION}" ]]; then
      echo "Error: Unable to detect CycloneDX specVersion" >&2
      exit 1
    fi
  elif [[ "${FORMAT}" == "spdx" ]]; then
    SPDX_VERSION="$(jq -r '.spdxVersion // empty' "${INPUT_FILE}")"
    if [[ -z "${SPDX_VERSION}" ]]; then
      echo "Error: Unable to detect SPDX version" >&2
      exit 1
    fi
    VERSION="${SPDX_VERSION#SPDX-}"
  else
    echo "Error: Unsupported format: ${FORMAT}" >&2
    exit 1
  fi
else
  VERSION="${INPUT_VERSION}"
fi

# Resolve schema path
if [[ "${FORMAT}" == "cyclonedx" ]]; then
  SCHEMA_PATH="${ACTION_PATH}/schemas/cyclonedx/bom-${VERSION}.schema.json"
elif [[ "${FORMAT}" == "spdx" ]]; then
  SCHEMA_PATH="${ACTION_PATH}/schemas/spdx/spdx-${VERSION}.schema.json"
else
  echo "Error: Unsupported format: ${FORMAT}" >&2
  exit 1
fi

# Verify schema file exists
if [[ ! -f "${SCHEMA_PATH}" ]]; then
  echo "Error: Schema file not found: ${SCHEMA_PATH}" >&2
  echo "Format: ${FORMAT}, Version: ${VERSION}" >&2
  exit 1
fi

# Build ajv command
AJV_ARGS=(
  validate
  -s "${SCHEMA_PATH}"
  -d "${INPUT_FILE}"
  --spec=draft2020
  --all-errors
)

# Apply strict mode setting
if [[ "${INPUT_STRICT}" == "true" ]]; then
  AJV_ARGS+=(--strict=true)
else
  AJV_ARGS+=(--strict=false)
fi

# Run validation and capture output
VALIDATION_OUTPUT=$(npx ajv-cli "${AJV_ARGS[@]}" 2>&1) || VALIDATION_EXIT_CODE=$?
VALIDATION_EXIT_CODE=${VALIDATION_EXIT_CODE:-0}

# Parse results
if [[ ${VALIDATION_EXIT_CODE} -eq 0 ]]; then
  VALID="true"
  ERROR_COUNT="0"
else
  VALID="false"
  ERROR_COUNT=$(echo "${VALIDATION_OUTPUT}" | grep -c 'error' || echo 0)
fi

# Write outputs
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "valid=${VALID}"
    echo "format=${FORMAT}"
    echo "spec-version=${VERSION}"
    echo "error-count=${ERROR_COUNT}"
  } >> "${GITHUB_OUTPUT}"
fi

# Print summary
echo "========================================="
echo "SBOM Validation Summary"
echo "========================================="
echo "File:         ${INPUT_FILE}"
echo "Format:       ${FORMAT}"
echo "Version:      ${VERSION}"
echo "Valid:        ${VALID}"
echo "Error Count:  ${ERROR_COUNT}"
echo "========================================="

if [[ "${VALID}" == "false" ]]; then
  echo ""
  echo "Validation Errors:"
  echo "${VALIDATION_OUTPUT}"
  exit 1
fi

exit 0
