# Agent Configuration Notes

Host: `my-agent` (`192.168.122.208`).

Installed package: `wazuh-agent` `4.14.10-1`.

Manager endpoint: `192.168.122.178:1514/TCP`.

The agent is enrolled as ID `001` and name `my-agent`; the Manager reported it as `Active` in the captured validation output.

The relevant client configuration is documented in `docs/03-agent-installation.md`. Keep the real `/var/ossec/etc/client.keys` file on the endpoint only. Never copy it into this repository.
