# Scenario 11: GCP Cloud Audit & IAM Threat Detection

## 📌 Executive Summary

This project demonstrates a cloud security monitoring scenario using Wazuh SIEM and Google Cloud Audit Logs. It focuses on detecting Google Cloud IAM policy changes through a custom Wazuh detection rule that identifies the `SetIamPolicy` API method.

The lab includes custom detection engineering, positive and negative test cases, and regression validation using `wazuh-logtest`. Google Cloud Pub/Sub is configured as the intended log ingestion path. End-to-end ingestion of live Google Cloud events remains to be verified.

## 📐 Network & Lab Architecture

```text
Cloud Audit Source: Google Cloud Audit Logs
Message Transport: Google Cloud Pub/Sub
SIEM / XDR Manager: Wazuh Manager 4.14.7 (Ubuntu Server)
Detection Engine: Wazuh JSON decoder + custom rule 100110
Test Environment: Synthetic Cloud Audit Log events
```

**Expected event flow:**

```text
Google Cloud Audit Logs
        |
        v
Google Cloud Pub/Sub
        |
        v
Wazuh GCP Integration
        |
        v
Wazuh JSON Decoder
        |
        v
Custom Detection Rule 100110
        |
        v
Wazuh Alert
```

## 🔍 MITRE ATT&CK Mapping

```text
Potentially relevant technique:
Account Manipulation: Additional Cloud Roles (T1098.003)

Applicability:
Context-dependent. A SetIamPolicy event can represent a legitimate
administrative change or a security-relevant modification. The API
method alone does not prove malicious activity.
```

## ⚙️ Custom Detection Rules & Validation

```text
Custom Rule Configuration:
/var/ossec/etc/rules/local_rules.xml

Rule 100110 (Level 5 - MEDIUM):
Detects Google Cloud Audit Log events where
protoPayload.methodName equals SetIamPolicy.

Decoder:
Built-in Wazuh JSON decoder

Detection Field:
protoPayload.methodName

Matching Value:
SetIamPolicy

Rule Description:
Google Cloud Audit: IAM policy change detected
```

The rule identifies IAM policy changes for investigation. It does not independently determine whether the change was authorized or malicious.

## 🧪 Detection Test Results

| Test Case | Input | Expected Result | Status |
|---|---|---|---|
| Positive | `SetIamPolicy` | Rule 100110 matches | PASS |
| Negative | `GetIamPolicy` | Rule 100110 does not match | PASS |
| Regression | Repeat positive and negative tests | Results remain consistent | PASS |

Tests were performed with `wazuh-logtest` on Wazuh Manager 4.14.7. The rule configuration passed `wazuh-analysisd -t`.

**Validation limitation:** These tests use synthetic events. They validate rule matching, not the delivery of real Google Cloud events, alert indexing, or Dashboard visibility.

## ☁️ Google Cloud Integration

```text
Integration Type: Google Cloud Pub/Sub
Subscription: wazuh-gcp-topic-sub
Wazuh Component: GCP Pub/Sub integration
Credentials: Service-account credentials file on the Wazuh Manager
```

The Pub/Sub integration is configured on the manager. Successful receipt and detection of real Google Cloud Audit Logs must be confirmed separately.

Sensitive credentials must not be committed to this repository or included in screenshots, logs, or reports.

## 📁 Repository Structure

```text
11-GCP-Cloud-Audit-Threat-Detection/
├── architecture/                 # Architecture and event-flow documentation
├── collector/                    # Collection and integration materials
├── wazuh/
│   ├── decoders/                 # Custom decoder files, if required
│   └── rules/
│       └── gcp_cloud_audit_rules.xml
├── tests/
│   ├── positive/
│   │   └── iam-policy-change.json
│   ├── negative/
│   │   └── iam-policy-read.json
│   └── regression/               # Regression test materials
├── sample-logs/                  # Example Cloud Audit Log events
├── evidence/                     # Test evidence and screenshots
├── reports/
│   └── test-results.md           # Detection test results
└── README.md                     # Scenario documentation and playbook
```

## ⚠️ Limitations

- Live Google Cloud event ingestion has not yet been confirmed.
- Synthetic test events do not prove end-to-end integration functionality.
- The rule detects an API method, not malicious intent.
- Alert indexing and visibility in the Wazuh Dashboard have not yet been validated.
- Credentials and other secrets must remain outside version control.

## 🚀 Next Steps

1. Verify that the Wazuh GCP integration receives messages from Pub/Sub.
2. Confirm that a real Cloud Audit Log event reaches the Wazuh analysis engine.
3. Validate the resulting alert in `alerts.json` or the Wazuh Dashboard.
4. Expand coverage with additional IAM-related test cases.
5. Save sanitized evidence and update the test report.
