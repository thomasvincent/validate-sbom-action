# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.x | Yes |

## Reporting a Vulnerability

To report a security vulnerability, please use [GitHub Security Advisories](https://github.com/thomasvincent/validate-sbom-action/security/advisories/new).

Do not open a public issue for security vulnerabilities.

## Security Model

This action validates SBOM files against vendored JSON schemas using ajv-cli.

- Schemas are vendored in-repo. No network calls during validation.
- The only network call is `npm install` during setup (fetches ajv-cli and ajv-formats from the npm registry).
- No telemetry, no data exfiltration, no external service calls.
- Requires only `contents: read` permission.
- Runs entirely within the GitHub Actions job container.
