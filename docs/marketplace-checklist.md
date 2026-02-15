# Marketplace Readiness Checklist

## Required

- [x] `action.yml` has `name`, `description`, `author`
- [x] `action.yml` has `branding` (icon: shield, color: green)
- [x] LICENSE file present (Apache-2.0)
- [x] README.md present
- [x] At least one release tag exists
- [x] CI passing on main branch

## Documentation

- [x] Inputs table in README
- [x] Outputs table in README
- [x] Basic usage example
- [x] Badges (CI, license, marketplace)
- [x] SHA pin guidance
- [x] `permissions` block in workflow examples
- [x] Failure modes / exit codes documented
- [x] Compatibility section (runner requirements)
- [x] Security model section
- [x] Advanced examples (matrix, outputs, explicit format)

## Security and Trust

- [x] SECURITY.md with disclosure policy
- [x] npm dependencies pinned via package.json / lockfile
- [x] Dependabot tracks npm ecosystem
- [ ] CODEOWNERS file
- [ ] CodeQL scanning

## CI / Release

- [x] `timeout-minutes` on all CI jobs
- [x] `concurrency` block to cancel stale runs
- [x] Test matrix covers valid and invalid fixtures
- [ ] Release automation workflow
- [ ] Test fixtures for all supported versions (missing: CycloneDX 1.4, 1.7; SPDX 2.2)

## Code Quality

- [x] ShellCheck in CI
- [x] Bash syntax check in CI
- [x] `set -euo pipefail` in validate.sh
- [x] Schemas vendored (no runtime network dependency)
- [x] Dead code removed (`strict` input)
- [x] `npm install` errors visible (no stderr suppression)
