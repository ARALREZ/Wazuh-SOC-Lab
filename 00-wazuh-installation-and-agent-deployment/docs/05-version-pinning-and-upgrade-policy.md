# Wazuh Version Pinning and Upgrade Policy

## Current version baseline

| Component | Host | Version |
|---|---|---:|
| Wazuh Manager | `my-server` | `4.14.10-1` |
| Wazuh Indexer | `my-server` | `4.14.10-1` |
| Wazuh Dashboard | `my-server` | `4.14.10-1` |
| Wazuh Agent | `my-agent` | `4.14.10-1` |
| Filebeat | `my-server` | `7.10.2-2` |

All central Wazuh components must use identical version numbers, including the patch level. The Manager must be the same version as or newer than its agents. This lab deliberately keeps the Manager and Agent at the exact same version to make testing repeatable. Filebeat uses a separate version scheme; Wazuh documents Filebeat OSS 7.10.2 as compatible with Wazuh Indexer 4.14.10.

## Lock packages on `my-server`

Run from the project root:

```bash
sudo bash scripts/hold-wazuh-packages.sh server
```

This holds `wazuh-manager`, `wazuh-indexer`, `wazuh-dashboard`, and `filebeat`, and comments out active Wazuh APT repository entries in `/etc/apt/sources.list.d/wazuh.list`.

## Lock packages on `my-agent`

Run from the project root:

```bash
sudo bash scripts/hold-wazuh-packages.sh agent
```

This holds `wazuh-agent` and comments out active Wazuh APT repository entries in `/etc/apt/sources.list.d/wazuh.list`.

The scripts must be run separately on the host matching the selected role. Do not run the `server` role on the agent or vice versa.

## Verify the lock

On `my-server`:

```bash
apt-mark showhold | sort
bash scripts/verify-wazuh-versions.sh server
```

Expected holds:

```text
filebeat
wazuh-dashboard
wazuh-indexer
wazuh-manager
```

On `my-agent`:

```bash
apt-mark showhold | sort
EXPECTED_WAZUH_VERSION=4.14.10-1 bash scripts/verify-wazuh-versions.sh agent
```

Expected hold:

```text
wazuh-agent
```

Expected package versions on both hosts are `4.14.10-1` for the Wazuh components installed there.

## What the lock does

- `apt-mark hold` prevents routine APT package operations from automatically installing, upgrading, or removing the held packages.
- Disabling the Wazuh repository entry prevents routine APT refreshes from fetching new Wazuh package metadata from that source.
- The lock does not prevent a privileged administrator from intentionally overriding the hold or manually installing a chosen package version.
- The lock does not manage Wazuh's remote agent-upgrade feature. Do not initiate remote upgrades during this lab baseline.


## Planned upgrade procedure

Only upgrade during a planned maintenance window.

1. Read the target release notes and compatibility requirements.
2. Back up Wazuh configuration, certificates, and required index data.
3. Re-enable the Wazuh repository and refresh APT metadata on the required hosts.
4. Remove package holds for the packages being upgraded.
5. Upgrade the Wazuh Indexer.
6. Upgrade the Wazuh Manager and apply any required Filebeat configuration changes.
7. Upgrade the Wazuh Dashboard.
8. Upgrade the Agents, ensuring the Manager is not older than the Agents.
9. Confirm component versions, service health, agent connectivity, and alert ingestion.
10. Reapply package holds and disable the Wazuh repository again.

Follow the official upgrade guide for the exact commands and any release-specific migration requirements.

Do not attempt an unsupported downgrade, especially for Wazuh Indexer releases using newer Apache Lucene versions.
