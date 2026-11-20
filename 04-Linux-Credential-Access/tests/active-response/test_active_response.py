#!/usr/bin/env python3
# Mock-based tests: command shims ensure no real account or password is touched.
from __future__ import annotations
import json, os, subprocess, tempfile
from pathlib import Path
PROJECT = Path(__file__).resolve().parents[2]
SCRIPT = PROJECT / 'scripts/response/p04-lock-test-account.sh'
JQ = r'''#!/usr/bin/env python3
import json, sys
args=sys.argv[1:]
try: obj=json.loads(sys.stdin.read())
except Exception: sys.exit(4)
if args == ['-e','.']: sys.exit(0)
if len(args)!=2 or args[0]!='-r': sys.exit(2)
expr=args[1]
for path in [p.strip() for p in expr.replace('// empty','').split('//')]:
    value=obj
    for key in path[1:].split('.'):
        if not path.startswith('.') or not isinstance(value,dict) or key not in value:
            value=None; break
        value=value[key]
    if value is not None:
        print(value); sys.exit(0)
sys.exit(0)
'''
ID = r'''#!/usr/bin/env bash
[[ "$#" == 1 && "$1" == p04-labuser ]] && exit 0
[[ "$#" == 2 && "$1" == -u && "$2" == p04-labuser ]] && { echo 1008; exit 0; }
exit 1
'''
PASSWD = r'''#!/usr/bin/env bash
set -euo pipefail
[[ "$2" == p04-labuser ]] || exit 2
case "$1" in
 -S) printf 'p04-labuser %s 2026-11-20 0 99999 7 -1\n' "$(cat "$P04_TEST_STATE")" ;;
 -l) printf L > "$P04_TEST_STATE" ;;
 *) exit 2 ;;
esac
'''
def alert(command='add', rule='100042', agent='001', auid='1008'):
    audit={} if auid is None else {'auid':auid}
    return {'command':command,'parameters':{'alert':{'rule':{'id':rule},'agent':{'id':agent},'data':{'audit':audit}}}}
def run_case(name, payload, initial, expected, log_fragment, rc=0):
    with tempfile.TemporaryDirectory(prefix='p04-ar-') as tmp:
        root=Path(tmp); bind=root/'bin'; bind.mkdir()
        for name_, body in [('jq',JQ),('id',ID),('passwd',PASSWD)]:
            p=bind/name_; p.write_text(body); p.chmod(0o755)
        state=root/'state'; state.write_text(initial); log=root/'response.log'
        env=os.environ.copy(); env.update({'PATH':str(bind)+':'+env.get('PATH',''),'P04_TEST_STATE':str(state),'P04_LOG_FILE':str(log)})
        proc=subprocess.run([str(SCRIPT)],input=payload,text=True,capture_output=True,env=env,timeout=10)
        actual_state=state.read_text(); actual_log=log.read_text() if log.exists() else ''
        ok=proc.returncode==rc and actual_state==expected and log_fragment in actual_log
        print(f"[{'PASS' if ok else 'FAIL'}] {name}: rc={proc.returncode}, state={actual_state}")
        if not ok: print(proc.stdout,proc.stderr,actual_log)
        return ok
def main():
    if not SCRIPT.is_file(): print(f'Missing script: {SCRIPT}'); return 2
    valid=json.dumps(alert())+'\n'
    cases=[
      ('valid add',valid,'P','L','LOCKED password authentication',0),
      ('wrong rule',json.dumps(alert(rule='100041'))+'\n','P','P','unexpected rule ID',0),
      ('wrong agent',json.dumps(alert(agent='002'))+'\n','P','P','unexpected Agent ID',0),
      ('wrong AUID',json.dumps(alert(auid='1000'))+'\n','P','P','does not match',0),
      ('missing AUID',json.dumps(alert(auid=None))+'\n','P','P','missing or invalid audit.auid',0),
      ('already locked',valid,'L','L','already locked',0),
      ('invalid JSON','{bad-json}\n','P','P','invalid JSON',1),
      ('delete action',json.dumps(alert(command='delete'))+'\n','P','P','unsupported command',0),
    ]
    outcomes=[run_case(*c) for c in cases]
    passed=sum(outcomes); failed=len(outcomes)-passed
    print(f'\nSummary: {passed}/{len(outcomes)} PASS, {failed} FAIL')
    return 0 if failed==0 else 1
if __name__=='__main__': raise SystemExit(main())
