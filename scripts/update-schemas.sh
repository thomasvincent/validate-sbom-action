#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CYCLONEDX_DIR="${REPO_ROOT}/schemas/cyclonedx"
SPDX_DIR="${REPO_ROOT}/schemas/spdx"

download_and_verify() {
    local url="$1"
    local output_path="$2"
    local filename
    filename="$(basename "${output_path}")"

    echo "Downloading ${filename}..."
    if curl -fsSL -o "${output_path}" "${url}"; then
        if jq . "${output_path}" > /dev/null 2>&1; then
            echo "  ✓ ${filename} downloaded and verified"
            return 0
        else
            echo "  ✗ ${filename} is not valid JSON"
            rm -f "${output_path}"
            return 1
        fi
    else
        echo "  ✗ Failed to download ${filename}"
        return 1
    fi
}

mkdir -p "${CYCLONEDX_DIR}" "${SPDX_DIR}"

echo "=== Downloading CycloneDX schemas ==="
download_and_verify \
    "https://raw.githubusercontent.com/CycloneDX/specification/1.4/schema/bom-1.4.schema.json" \
    "${CYCLONEDX_DIR}/bom-1.4.schema.json"

download_and_verify \
    "https://raw.githubusercontent.com/CycloneDX/specification/1.5/schema/bom-1.5.schema.json" \
    "${CYCLONEDX_DIR}/bom-1.5.schema.json"

download_and_verify \
    "https://raw.githubusercontent.com/CycloneDX/specification/1.6/schema/bom-1.6.schema.json" \
    "${CYCLONEDX_DIR}/bom-1.6.schema.json"

download_and_verify \
    "https://raw.githubusercontent.com/CycloneDX/specification/master/schema/bom-1.7.schema.json" \
    "${CYCLONEDX_DIR}/bom-1.7.schema.json"

echo ""
echo "=== Downloading SPDX schemas ==="
download_and_verify \
    "https://raw.githubusercontent.com/spdx/spdx-spec/development/v2.2.2/schemas/spdx-schema.json" \
    "${SPDX_DIR}/spdx-2.2.schema.json"

download_and_verify \
    "https://raw.githubusercontent.com/spdx/spdx-spec/v2.3/schemas/spdx-schema.json" \
    "${SPDX_DIR}/spdx-2.3.schema.json"

echo ""
echo "=== Schema update complete ==="
