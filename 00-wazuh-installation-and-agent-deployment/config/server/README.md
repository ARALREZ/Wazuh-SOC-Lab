# Server Configuration Notes

Host: `my-server` (`192.168.122.178`).

Installed packages:

- `wazuh-manager` `4.14.10-1`
- `wazuh-indexer` `4.14.10-1`
- `wazuh-dashboard` `4.14.10-1`
- `filebeat` `7.10.2-2`

The three central Wazuh packages must remain on the same exact version. Filebeat has an independent version scheme; `7.10.2-2` is the deployed compatible package for this Wazuh Indexer baseline.

Useful checks:

```bash
sudo systemctl is-active wazuh-manager wazuh-indexer wazuh-dashboard filebeat
sudo /var/ossec/bin/agent_control -l
sudo /var/ossec/bin/agent_control -lc
```

Do not store Dashboard passwords, API credentials, private keys, certificates, or `wazuh-install-files.tar` here.
