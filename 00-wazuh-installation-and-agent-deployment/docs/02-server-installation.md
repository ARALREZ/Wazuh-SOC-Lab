# Wazuh Server Installation

## Deployment type

All-in-one deployment on `my-server` (`192.168.122.178`), Ubuntu 24.04.5 LTS, x86-64.

## Installed components

| Package | Installed version | Service |
|---|---:|---|
| `wazuh-manager` | `4.14.10-1` | `wazuh-manager.service` |
| `wazuh-indexer` | `4.14.10-1` | `wazuh-indexer.service` |
| `wazuh-dashboard` | `4.14.10-1` | `wazuh-dashboard.service` |
| `filebeat` | `7.10.2-2` | `filebeat.service` |

Filebeat has its own version numbering. It is not expected to have the same version string as Wazuh. Wazuh documentation identifies Filebeat OSS 7.10.2 as compatible with Wazuh Indexer 4.14.10.

## Installation health evidence

The captured output showed all three central services as `active (running)`. The Dashboard reported listening on `https://0.0.0.0:443`. The Manager exposed ports `1514`, `1515`, and `55000`. The Indexer listened on loopback ports `9200` and `9300`.

## Validation commands

```bash
sudo systemctl status wazuh-manager --no-pager
sudo systemctl status wazuh-indexer --no-pager
sudo systemctl status wazuh-dashboard --no-pager
sudo systemctl status filebeat --no-pager

sudo ss -lntup | grep -E ':(443|1514|1515|55000|9200|9300)\\b'

dpkg-query -W -f='${binary:Package} ${Version}\\n' \\
  wazuh-manager wazuh-indexer wazuh-dashboard filebeat
```

Dashboard URL: `https://192.168.122.178`.

Store generated credentials securely. Do not commit installer archives containing credentials, password files, private keys, or certificates to Git.
