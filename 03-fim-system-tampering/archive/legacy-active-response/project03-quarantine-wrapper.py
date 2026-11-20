#!/usr/bin/python3

import json
import os
import re
import stat
import sys
import subprocess
from pathlib import Path
from datetime import datetime, timezone

WATCH_ROOT = "/opt/wazuh-fim-lab/watch"
QUARANTINE_TOOL = "/usr/local/sbin/wazuh-project03-quarantine"
LOG_FILE = "/var/log/wazuh-project03-active-response.log"

EXPECTED_RULE = "100038"
EXPECTED_AGENT = "001"

MAX_INPUT = 4 * 1024 * 1024
TIMEOUT = 90

FILENAME_PATTERN = re.compile(
    r"^p03-ar-quarantine-[A-Za-z0-9][A-Za-z0-9._-]{0,100}\.txt$"
)


class Rejected(Exception):
    pass


def audit(action, **fields):
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "component": "project03-quarantine",
        "action": action,
        **fields,
    }

    data = (
        json.dumps(record, ensure_ascii=True, separators=(",", ":")) + "\n"
    ).encode("utf-8")

    flags = os.O_WRONLY | os.O_APPEND | os.O_CREAT
    flags |= getattr(os, "O_NOFOLLOW", 0)

    fd = os.open(LOG_FILE, flags, 0o600)

    try:
        info = os.fstat(fd)

        if not stat.S_ISREG(info.st_mode) or info.st_uid != 0:
            raise RuntimeError("Audit log must be a root-owned regular file")

        os.fchmod(fd, 0o600)

        written = 0
        while written < len(data):
            count = os.write(fd, data[written:])
            if count <= 0:
                raise RuntimeError("Incomplete audit log write")
            written += count

        os.fsync(fd)
    finally:
        os.close(fd)


def reject(reason, **fields):
    audit("rejected", reason=reason, **fields)
    raise Rejected(reason)


def load_message():
    raw = sys.stdin.buffer.readline(MAX_INPUT + 1)

    if not raw:
        raise Rejected("Empty Active Response input")

    if len(raw) > MAX_INPUT:
        raise Rejected("Active Response input exceeds size limit")

    try:
        message = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise Rejected("Invalid UTF-8 JSON input")

    if not isinstance(message, dict):
        raise Rejected("JSON root must be an object")

    return message


def validate_message(message):
    if type(message.get("version")) is not int:
        reject("Invalid protocol version")

    if message["version"] != 1:
        reject("Unsupported protocol version")

    if message.get("command") != "add":
        reject("Only stateless add command is supported")

    parameters = message.get("parameters")

    if not isinstance(parameters, dict):
        reject("Missing parameters object")

    extra_args = parameters.get("extra_args", [])

    if not isinstance(extra_args, list) or extra_args:
        reject("Unexpected extra arguments")

    alert = parameters.get("alert")

    if not isinstance(alert, dict):
        reject("Missing alert object")

    rule = alert.get("rule")
    agent = alert.get("agent")
    syscheck = alert.get("syscheck")

    if not isinstance(rule, dict):
        reject("Missing rule object")

    if not isinstance(agent, dict):
        reject("Missing agent object")

    if not isinstance(syscheck, dict):
        reject("Missing syscheck object")

    rule_id = str(rule.get("id", ""))
    agent_id = str(agent.get("id", ""))

    if rule_id != EXPECTED_RULE:
        reject("Unexpected rule ID", rule_id=rule_id)

    if agent_id != EXPECTED_AGENT:
        reject("Unexpected agent ID", agent_id=agent_id)

    if syscheck.get("event") != "added":
        reject("Only newly added files are accepted")

    source = syscheck.get("path")

    if not isinstance(source, str) or not source:
        reject("Missing FIM file path")

    if "\n" in source or "\r" in source or "\x00" in source:
        reject("Invalid characters in file path")

    if not source.startswith(WATCH_ROOT + "/"):
        reject("File is outside permitted watch directory", path=source)

    if os.path.abspath(source) != source:
        reject("Non-canonical file path", path=source)

    if os.path.realpath(WATCH_ROOT) != WATCH_ROOT:
        reject("Watch root is not canonical")

    try:
        root_info = os.lstat(WATCH_ROOT)
        source_info = os.lstat(source)
    except OSError as error:
        reject("Cannot inspect source file", error=str(error))

    if not stat.S_ISDIR(root_info.st_mode):
        reject("Watch root is not a directory")

    if not stat.S_ISREG(source_info.st_mode):
        reject("Source is not a regular file", path=source)

    if source_info.st_nlink != 1:
        reject("Hard-linked files are refused", path=source)

    if os.path.dirname(source) != WATCH_ROOT:
        reject("Nested paths are not permitted", path=source)

    if os.path.realpath(source) != source:
        reject("Symlink or non-canonical source path", path=source)

    filename = os.path.basename(source)

    if not FILENAME_PATTERN.fullmatch(filename):
        reject("Filename does not match quarantine test pattern",
               filename=filename)

    if os.geteuid() != 0:
        reject("Wrapper must run as root")

    if not os.path.isfile(QUARANTINE_TOOL):
        reject("Quarantine utility is missing")

    if not os.access(QUARANTINE_TOOL, os.X_OK):
        reject("Quarantine utility is not executable")

    return rule_id, agent_id, source


def execute_quarantine(rule_id, agent_id, source):
    audit(
        "accepted",
        rule_id=rule_id,
        agent_id=agent_id,
        path=source,
    )

    result = subprocess.run(
        [
            QUARANTINE_TOOL,
            "quarantine",
            source,
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=TIMEOUT,
        check=False,
        shell=False,
        env={
            "PATH": "/usr/sbin:/usr/bin:/sbin:/bin",
            "LANG": "C.UTF-8",
        },
    )

    audit(
        "quarantine_succeeded" if result.returncode == 0
        else "quarantine_failed",
        rule_id=rule_id,
        agent_id=agent_id,
        path=source,
        return_code=result.returncode,
        output=result.stdout[:3000],
        error=result.stderr[:3000],
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"Quarantine utility returned {result.returncode}"
        )


def main():
    try:
        message = load_message()

        rule_id, agent_id, source = validate_message(message)

        execute_quarantine(rule_id, agent_id, source)

        return 0

    except Rejected as error:
        print(f"[REJECTED] {error}", file=sys.stderr)
        return 1

    except subprocess.TimeoutExpired:
        try:
            audit("timeout", reason="Quarantine utility exceeded timeout")
        except Exception:
            pass

        print("[ERROR] Quarantine utility timed out", file=sys.stderr)
        return 1

    except Exception as error:
        try:
            audit("error", reason=str(error))
        except Exception as log_error:
            print(
                f"[AUDIT ERROR] {log_error}",
                file=sys.stderr,
            )

        print(f"[ERROR] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
