{
  description = "Bato-nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators }:
    flake-utils.lib.eachDefaultSystem
      (eachSystem:
        let
          pkgs = nixpkgs.legacyPackages.${eachSystem};
        in
        {
          devShell = import ./shell.nix { inherit pkgs; };
        }
      ) // {
      nixosConfigurations =
        let
          bato-system = "x86_64-linux";
          stateVersion = "23.11";
        in
        {
          bato-nix =
            let
            in nixpkgs.lib.nixosSystem rec {
              system = bato-system;

              pkgs = import nixpkgs {
                inherit system;

                config.allowUnfree = true;
              };

              modules = [
                {
                  system.stateVersion = stateVersion;
                  boot.kernelPackages = pkgs.linuxPackages_6_6;
                  users.users.root.password = "linux";

                  time.timeZone = "UTC";
                }

                {
                  imports = [
                    nixos-generators.nixosModules.all-formats
                  ];

                  formatConfigs.qcow = { config, lib, ... }: { };
                }

                {
                  imports = [
                    ./profiles/systems/psx.nix
                  ];

                  bato.systems.psx.enable = true;
                }
              ];
            };
        };
    };
}
