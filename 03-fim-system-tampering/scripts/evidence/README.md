# Quarantine Screenshot Capture

These evidence capture scripts run on `my-agent` as root and create only uniquely named lab fixtures under `/opt/wazuh-fim-lab/watch`.

Copy the scripts to the Agent or make the repository available there, then run:

```bash
sudo bash capture-quarantine-05.sh
sudo bash capture-quarantine-06.sh
```

Capture the terminal output in PNGs named:
- `quarantine-05-symlink-and-overwrite-protection.png`
- `quarantine-06-audit-log.png`

The scripts attempt to recover their own quarantine item on exit. If restore fails, the payload is intentionally retained for manual recovery; never delete it as a shortcut.
