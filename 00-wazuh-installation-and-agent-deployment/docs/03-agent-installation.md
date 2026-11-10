# Wazuh Agent Installation

## Target endpoint

- Host: `my-agent`
- OS: Ubuntu 24.04.5 LTS, x86-64
- IP address: `192.168.122.208`
- Manager address: `192.168.122.178`
- Installed Wazuh Agent version: `4.14.10-1`

## Repository setup performed

The official Wazuh signing key was imported into `/usr/share/keyrings/wazuh.gpg`, and the Wazuh APT source was added at `/etc/apt/sources.list.d/wazuh.list`.

## Installation command used

```bash
sudo env \\
  WAZUH_MANAGER="192.168.122.178" \\
  WAZUH_AGENT_NAME="my-agent" \\
  apt-get install -y wazuh-agent
```

The package manager installed `wazuh-agent` version `4.14.10-1`.

## Service activation

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
sudo systemctl status wazuh-agent --no-pager
```

The captured status was `active (running)` and the service was enabled at boot.

## Configuration check

The agent configuration contains:

```xml
<client>
  <server>
    <address>192.168.122.178</address>
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</client>
```

The installed enrollment key file `/var/ossec/etc/client.keys` exists. Never print, copy, or commit its contents.

## Important

`agent_control` is a Manager-side utility. Run it on `my-server`, not on `my-agent`.
