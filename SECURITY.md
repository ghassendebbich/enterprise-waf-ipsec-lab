# Security Policy and Safe Lab Use

## Credentials and secrets

- No working IPsec pre-shared key is intentionally included in this repository.
- The FortiGate reference files use `REPLACE_WITH_YOUR_OWN_PSK`. Replace it locally with a
  unique secret on both VPN endpoints before a future deployment.
- Never commit passwords, API tokens, private keys, license files, session data,
  or other credentials. Use placeholders in documentation and configuration
  examples.
- If a credential is accidentally committed, treat it as compromised, rotate it
  wherever it is used, and remove it from Git history. A new commit deleting the
  value is not sufficient.

## Lab safety

- DVWA is deliberately vulnerable. Run it only in an isolated, authorized lab.
- The direct-to-backend bypass path (port 10445) intentionally skips WAF
  inspection and exists only as a controlled comparison baseline. Never expose
  it outside the lab.
- Do not upload vendor appliance images, private licenses, or real organization
  configuration backups.

## Scope and validation limitations

- This repository documents an educational EVE-NG lab, not a production design.
- The original EVE-NG environment has been decommissioned. Configurations and
  test procedures have not been revalidated on running appliances since then.
- Validate every command against the exact appliance/software version before
  reuse. The original IPsec proposals include legacy algorithms and must not be
  treated as production-hardened settings.
