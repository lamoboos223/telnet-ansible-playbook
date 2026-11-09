# Connectivity Check (DR test preparation)

Tests TCP connectivity (telnet-style, no data sent, 5 s timeout) from the
source servers to the destination:port pairs listed in the stream CSV files.

Sources can be Windows or Linux; you do not need to know which. Each source is
first tried over WinRM (PowerShell check). Sources WinRM cannot reach are
retried over SSH (bash `/dev/tcp` check). If both fail, every row for that
source is reported `False` with both reasons.

## Layout

```
streams/
  core/
    ruh/connectivity.csv
    jed/connectivity.csv
  comm/
    ruh/connectivity.csv
    jed/connectivity.csv
  sc/
    ruh/...
  gov/
    ruh/...
```

One CSV per stream per site. Missing files are skipped. The report tags every
row with its stream and site.

## Run

```bash
make              # everything
make comm         # one stream, both sites
make comm ruh     # one stream, one site (scoped DR run)
make ruh          # one site, all streams
make comm ruh INVENTORY=other.ini # for auth credentials
```

Streams: `core comm sc gov`. Sites: `ruh jed`. Or call the playbook directly:

```bash
ansible-playbook -i inventory.ini connectivity-check.yml -e stream=comm -e site=ruh
```

Sources run in parallel (Ansible forks, default 5; raise with `-f 10` if you
have more sources). The checks for one source run sequentially on that host.

## Requirements

- Ansible collections: `ansible.windows`, `community.general`
  (`ansible-galaxy collection install ansible.windows community.general`)
- `pywinrm` on the control node (`pip install pywinrm`)

## Inventory / connection variables

The playbook takes the source hostnames from the CSVs; they do not need to be
listed in the inventory. The connection type is forced per attempt (WinRM then
SSH), so do not set `ansible_connection` yourself; put credentials under
`[all:vars]` (or pass with `-e`):

```ini
# inventory.ini
[all:vars]
ansible_user=DOMAIN\svc-account
ansible_password=secret
ansible_port=5985
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```

`ansible_port` here is the WinRM port; the SSH attempt always uses port 22
(override with `-e ssh_port=2222`). The same user/password is used for both
attempts; SSH password auth needs `sshpass` on the control node, or use SSH
keys. Per-host vars in an existing inventory are reused as-is.

If neither WinRM nor SSH reaches a source, every row for that source is
reported `Reachable: False` and both failure reasons are printed after the
table. Other sources still run. The WinRM attempt gives up after 10 s per
unreachable source before SSH is tried.

## CSV format

Header exactly:

```csv
source,destination,port
j-comm-app01,REDIS01,6379
j-comm-app01,REDIS01,26379
```

One row per check. A source may appear in many rows and in many streams; a
destination may appear for many sources.

## Output

One table, sorted by Stream, Site, Source, Destination, Port (numeric), then a
count of True and False rows:

```
Stream   Site   Source                 Destination                            Port   Reachable
comm     ruh    j-comm-app01        REDIS01                             6379   True
...

True: 4
False: 2
```
