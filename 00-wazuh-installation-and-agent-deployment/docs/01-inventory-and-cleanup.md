# Inventory and Clean Reinstallation

## Hosts

Both Wazuh VMs run Ubuntu 24.04.5 LTS on x86-64:

- `my-server`: `192.168.122.178`
- `my-agent`: `192.168.122.208`

## Previous installation

The previous Wazuh installation was `4.9.2-1`. The old agent was purged from `my-agent`. The old Manager, Indexer, Dashboard, and Filebeat packages were purged from `my-server`.

## Cleanup verification

The clean-state check found no remaining Wazuh packages, Wazuh/Filebeat services or processes, Wazuh listener ports, or old SSH test files. The only name match intentionally preserved was:

`/opt/tracecat/docs/tools/wazuh.mdx`

This file is Tracecat documentation, not an installed Wazuh component.

## Preserved services

Tracecat, Temporal, PostgreSQL, Redis, MinIO, Caddy, Docker networks, and Docker volumes were preserved. They are outside the Wazuh cleanup scope.

## Sensitive data handling

The former `haslo` file was deleted from the server home directory. Deleting a password file does not revoke credentials; rotate any credential that may have been exposed or reused. Never place credentials or enrollment keys in the repository.
