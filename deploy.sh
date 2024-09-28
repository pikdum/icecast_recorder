#!/usr/bin/env bash
set -euxo pipefail

scp record-stream.sh root@files.usagi.zone:/usr/local/bin/record-shamiradio.sh
scp record-stream.service root@files.usagi.zone:/etc/systemd/system/record-shamiradio.service
ssh root@files.usagi.zone 'systemctl daemon-reload && systemctl restart record-shamiradio'
