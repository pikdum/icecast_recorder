{
  description = "Icecast recorder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f pkgs
        );
      mkPackage =
        pkgs:
        pkgs.writeShellApplication {
          name = "icecast-recorder";
          runtimeInputs = with pkgs; [
            coreutils
            curl
            jq
            procps
            wget
          ];
          text = builtins.readFile ./record-stream.sh;
          meta = {
            description = "Daemon to record an Icecast stream";
            mainProgram = "icecast-recorder";
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: {
        default = mkPackage pkgs;
      });

      apps = forAllSystems (
        pkgs:
        let
          package = mkPackage pkgs;
        in
        {
          default = {
            type = "app";
            program = "${package}/bin/icecast-recorder";
            meta.description = package.meta.description;
          };
        }
      );

      checks = forAllSystems (pkgs: {
        default = mkPackage pkgs;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.icecast-recorders;
          user = "icecast-recorder";
          group = user;
          hasInstances = builtins.length (builtins.attrNames cfg) > 0;
        in
        {
          options.services.icecast-recorders = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                {
                  name,
                  ...
                }:
                {
                  options = {
                    workingDirectory = lib.mkOption {
                      type = lib.types.strMatching "^/.*";
                      default = "/var/lib/icecast-recorder/${name}";
                      example = "/srv/icecast/example-station";
                      description = "Directory where recordings and logs are written.";
                    };

                    icecastName = lib.mkOption {
                      type = lib.types.str;
                      example = "example-station";
                      description = "Value exported as ICECAST_NAME.";
                    };

                    icecastApi = lib.mkOption {
                      type = lib.types.strMatching "^https?://.+";
                      example = "https://radio.example.com/status-json.xsl";
                      description = "Icecast status endpoint exported as ICECAST_API.";
                    };
                  };
                }
              )
            );
            default = { };
            description = "Icecast recorder service instances keyed by instance name.";
          };

          config = lib.mkIf hasInstances {
            users.groups.${group} = { };

            users.users.${user} = {
              isSystemUser = true;
              group = group;
              description = "icecast recorder service user";
              home = "/var/lib/icecast-recorder";
              createHome = false;
            };

            systemd.tmpfiles.rules = lib.mapAttrsToList (
              _name: instance: "d ${instance.workingDirectory} 0755 ${user} ${group} -"
            ) cfg;

            systemd.services = lib.mapAttrs' (
              name: instance:
              lib.nameValuePair "icecast-recorder-${name}" {
                description = "Record the ${name} Icecast stream";
                wantedBy = [ "multi-user.target" ];
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];

                serviceConfig = {
                  Type = "simple";
                  ExecStart = "${mkPackage pkgs}/bin/icecast-recorder";
                  User = user;
                  Group = group;
                  WorkingDirectory = instance.workingDirectory;
                  Restart = "always";
                  RestartSec = 30;
                  UMask = "0022";
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  ReadWritePaths = [ instance.workingDirectory ];
                };

                environment = {
                  ICECAST_NAME = instance.icecastName;
                  ICECAST_API = instance.icecastApi;
                };
              }
            ) cfg;
          };
        };
    };
}
