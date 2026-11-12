# SSH Brute Force — Expected Regression Results

**Target release:** Wazuh 4.14.10-1  
**Manager:** `192.168.122.178`  
**Agent:** `192.168.122.208`  
**Attacker:** `192.168.122.112`  
**Trusted source:** `192.168.122.1`

This file describes expected behavior. It is not a record of
completed test execution. Actual results belong in
`reports/test-results.md`.

## Expected custom rule levels

| Rule | Level |
|---|---:|
| 100001 | 6 |
| 100002 | 10 |
| 100003 | 6 |
| 100004 | 10 |
| 100005 | 14 |
| 100010 | 3 |

## Positive scenarios

| Scenario | Expected custom rule |
|---|---|
| 3 failed passwords from one source | 100001 |
| 5 failed passwords within 120 s | 100001, 100002 |
| 10 failed passwords | 100001, 100002 |
| Failed public-key authentication | 100003 |
| 5 different usernames from one source within 300 s | 100004 |
| 3 failures followed by successful login | 100001, 100005 |
| 5 failures followed by successful login | 100001, 100002, 100005 |
| 8 failures followed by successful login | 100001, 100002, 100005 |
| Trusted source failed authentication | 100010 only |

## Five failures followed by successful login

Expected event-by-event results:

| Event | Expected rule | Level |
|---:|---:|---:|
| 1 | 5760 | 5 |
| 2 | 5760 | 5 |
| 3 | 100001 | 6 |
| 4 | 5760 | 5 |
| 5 | 100002 | 10 |
| 6 | 100005 | 14 |

Rule 100005 must appear on the successful authentication event.
Its correlation uses earlier `authentication_failed` events with
the same source IP and username within 300 seconds. It is not a
direct `if_matched_sid=100001` dependency.

## Negative and boundary scenarios

| Scenario | Expected custom rule behavior |
|---|---|
| 2 failed passwords | No custom rule |
| 4 failed passwords | 100001 only |
| 5 failures outside the 120-second window | No 100002 |
| 4 different usernames | No 100004 |
| 5 failures for one username | No 100004 |
| Mixed source IP addresses | No cross-source correlation |
| Success for a different username | No 100005 |
| Success from a different source IP | No 100005 |
| Success after 300 seconds | No 100005 |
| Trusted source failures | 100010 only |

## Regression inventory

The current runner defines:

- 17 fast cases.
- 6 slow cases requiring real delays.

The slow cases are:

1. Five-user password spraying.
2. Five failures outside 120 seconds.
3. Four-user spraying boundary.
4. One user is not password spraying.
5. Slow failed logins outside 120 seconds.
6. Success after 300 seconds.

The slow runner deliberately waits between events. Do not remove
the delays merely to shorten the test; doing so would invalidate
the time-window test.

## Active Response policy

| Rule | Command | Timeout |
|---|---|---:|
| 100002 | `firewall-drop` | 600 seconds |
| 100005 | `firewall-drop` | 600 seconds |

All other custom rules must not trigger automatic blocking.

A regression result does not prove Active Response execution.
Live firewall verification is documented separately.
