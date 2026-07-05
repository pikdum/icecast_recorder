# icecast recorder

daemon to record icecast streams

## requirements

```
sudo apt-get install -y curl wget jq
```

## nix

The flake exposes:

- `packages.<system>.default`
- `apps.<system>.default`

Run it directly in any directory where you want recordings to be written:

```bash
ICECAST_NAME=example-station \
ICECAST_API=https://radio.example.com/status-json.xsl \
nix run github:pikdum/icecast_recorder
```

Service wiring (systemd units, users, working directories) is intentionally
left to the consumer: run `packages.<system>.default` under systemd with
`ICECAST_NAME`/`ICECAST_API` set and `WorkingDirectory` pointed at the
recording directory.
