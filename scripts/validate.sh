#!/usr/bin/env bash
set -euo pipefail

# Write failure outputs and exit — ensures GITHUB_OUTPUT is populated
# even when validation cannot proceed (missing file, bad version, etc.)
fail_with_output() {
  local msg="$1"
  local fmt="${FORMAT:-unknown}"
  local ver="${VERSION:-unknown}"
  echo "Error: ${msg}" >&2
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "valid=false"
      echo "format=${fmt}"
      echo "spec-version=${ver}"
      echo "error-count=1"
    } >> "${GITHUB_OUTPUT}"
  fi
  exit 1
}

# Resolve action path for both GitHub Actions and local execution
if [[ -n "${GITHUB_ACTION_PATH:-}" ]]; then
  ACTION_PATH="${GITHUB_ACTION_PATH}"
else
  ACTION_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Verify input file exists
if [[ ! -f "${INPUT_FILE}" ]]; then
  fail_with_output "Input file not found: ${INPUT_FILE}"
fi

# Verify file is valid JSON
if ! jq empty "${INPUT_FILE}" 2>/dev/null; then
  fail_with_output "Input file is not valid JSON: ${INPUT_FILE}"
fi

# Auto-detect format if needed
if [[ "${INPUT_FORMAT}" == "auto" ]]; then
  if [[ "$(jq -r '.bomFormat // empty' "${INPUT_FILE}")" == "CycloneDX" ]]; then
    FORMAT="cyclonedx"
  elif jq -e '.spdxVersion' "${INPUT_FILE}" >/dev/null 2>&1; then
    FORMAT="spdx"
  else
    fail_with_output "Unable to detect SBOM format. Specify format explicitly."
  fi
else
  FORMAT="${INPUT_FORMAT}"
fi

# Auto-detect version if needed
if [[ "${INPUT_VERSION}" == "auto" ]]; then
  if [[ "${FORMAT}" == "cyclonedx" ]]; then
    VERSION="$(jq -r '.specVersion // empty' "${INPUT_FILE}")"
    if [[ -z "${VERSION}" ]]; then
      fail_with_output "Unable to detect CycloneDX specVersion"
    fi
  elif [[ "${FORMAT}" == "spdx" ]]; then
    SPDX_VERSION="$(jq -r '.spdxVersion // empty' "${INPUT_FILE}")"
    if [[ -z "${SPDX_VERSION}" ]]; then
      fail_with_output "Unable to detect SPDX version"
    fi
    VERSION="${SPDX_VERSION#SPDX-}"
  else
    fail_with_output "Unsupported format: ${FORMAT}"
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
  fail_with_output "Unsupported format: ${FORMAT}"
fi

# Verify schema file exists
if [[ ! -f "${SCHEMA_PATH}" ]]; then
  fail_with_output "Schema file not found for ${FORMAT} ${VERSION}"
fi

# Detect JSON Schema draft from the schema's $schema field
SCHEMA_DRAFT=$(jq -r '.["$schema"] // empty' "${SCHEMA_PATH}")
case "${SCHEMA_DRAFT}" in
  *draft-07*|*draft-7*)  AJV_SPEC="draft7" ;;
  *draft/2019-09*)       AJV_SPEC="draft2019" ;;
  *draft/2020-12*)       AJV_SPEC="draft2020" ;;
  *)                     AJV_SPEC="draft7" ;;
esac

# Build ajv command — -c ajv-formats loads standard format validators
# (date-time, uri, email, etc.) that schemas reference
AJV_ARGS=(
  validate
  -s "${SCHEMA_PATH}"
  -d "${INPUT_FILE}"
  -c ajv-formats
  "--spec=${AJV_SPEC}"
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
