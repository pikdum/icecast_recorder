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

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
