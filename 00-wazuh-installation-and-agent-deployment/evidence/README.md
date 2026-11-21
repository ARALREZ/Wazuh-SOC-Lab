# Evidence Collection

Store sanitized screenshots, terminal output and test notes here.

## Recorded evidence

- [SSH event-ingestion smoke test — 2026-11-21](ssh-event-ingestion-2026-11-21.md): one controlled Kali-to-Agent SSH authentication attempt, local journald records and the corresponding Manager alerts.
- [Historical FIM validation — 2026-11-10](fim-validation-2026-11-10.md): Manager-side create/modify/delete alert generation. Dashboard visibility was not verified in the captured evidence.

## Suggested screenshot evidence

- `server-services-healthy.png`
- `agent-active-in-manager.png`
- `ssh-failed-login-alert.png`
- `fim-file-modified-alert.png`
- `fim-file-created-deleted-alert.png`

Before committing evidence, remove passwords, API tokens, agent keys, private certificates, session cookies, unrelated personal information and secrets. Do not commit `client.keys`, `wazuh-install-files.tar`, or raw credential files.
