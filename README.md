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
- `nixosModules.default`

Run it directly in any directory where you want recordings to be written:

```bash
ICECAST_NAME=example-station \
ICECAST_API=https://radio.example.com/status-json.xsl \
nix run github:pikdum/icecast_recorder
```

Use it from a NixOS flake like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    icecast-recorder.url = "github:pikdum/icecast_recorder";
  };

  outputs = { nixpkgs, icecast-recorder, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        icecast-recorder.nixosModules.default
        {
          services.icecast-recorders.example-station = {
            workingDirectory = "/srv/icecast/example-station";
            icecastName = "example-station";
            icecastApi = "https://radio.example.com/status-json.xsl";
          };

          services.icecast-recorders.another-station = {
            icecastName = "another-station";
            icecastApi = "https://another.example.com/status-json.xsl";
          };
        }
      ];
    };
  };
}
```

Each instance creates a systemd unit named `icecast-recorder-<instance>.service`.

If `workingDirectory` is omitted, it defaults to `/var/lib/icecast-recorder/<instance-name>`.
