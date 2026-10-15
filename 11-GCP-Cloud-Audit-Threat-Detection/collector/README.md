# GCP Pub/Sub Collector

The Wazuh Manager is configured to collect messages from Google Cloud Pub/Sub.

Configured values:
- Project: `project-f2f7b861-fe1c-4052-ad8`
- Subscription: `wazuh-gcp-topic-sub`
- Polling interval: `1m`
- Credentials path: `/var/ossec/wodles/gcp-pubsub/credentials.json`

The credentials file must not be committed to this repository.

## Current validation
- The subscription exists and is active.
- Manual execution of the Wazuh GCP script successfully retrieved a test message.
- Background module delivery and end-to-end alert generation remain to be verified.

## Troubleshooting checklist
1. Confirm the Wazuh Manager is active.
2. Check the GCP Pub/Sub module logs for authentication or polling errors.
3. Verify the subscription receives actual Cloud Audit Log JSON events.
4. Verify event fields and rule matching with `wazuh-logtest`.
5. Search `alerts.json` for rule ID `100110` after an end-to-end test.
