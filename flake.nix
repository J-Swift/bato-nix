{
  description = "Bato-nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixinate = {
      # url = "github:MatthewCroughan/nixinate";
      url = "github:J-Swift/nixinate/feature/allow-ssh-config-hostnames";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators, nixinate }:
    flake-utils.lib.eachDefaultSystem
      (eachSystem:
        let
          pkgs = nixpkgs.legacyPackages.${eachSystem};
        in
        {
          apps = nixinate.nixinate.${eachSystem} self;
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
            in nixpkgs.lib.nixosSystem
              rec {
                system = bato-system;

                pkgs = import nixpkgs {
                  inherit system;

                  config.allowUnfree = true;
                };

                modules = [
                  {
                    system.stateVersion = stateVersion;
                    boot.kernelPackages = pkgs.linuxPackages_6_10;

                    users.users.root.password = "linux";

                    time.timeZone = "America/New_York";
                    services.openssh = {
                      enable = true;
                      settings.PermitRootLogin = "yes";
                    };
                    networking.hostName = "bato-nix";

                    i18n.defaultLocale = "en_US.UTF-8";

                    i18n.extraLocaleSettings = {
                      LC_ADDRESS = "en_US.UTF-8";
                      LC_IDENTIFICATION = "en_US.UTF-8";
                      LC_MEASUREMENT = "en_US.UTF-8";
                      LC_MONETARY = "en_US.UTF-8";
                      LC_NAME = "en_US.UTF-8";
                      LC_NUMERIC = "en_US.UTF-8";
                      LC_PAPER = "en_US.UTF-8";
                      LC_TELEPHONE = "en_US.UTF-8";
                      LC_TIME = "en_US.UTF-8";
                    };
                  }

                  {
                    imports = [
                      "${toString nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
                    ];

                    services.qemuGuest.enable = true;
                    services.spice-vdagentd.enable = true;
                    services.spice-webdavd.enable = true;
                    networking.firewall.enable = false;

                    environment.etc."davfs2/secrets" = {
                      mode = "0600";
                      text = ''
                        http://localhost:9843  guest  ""
                      '';
                    };

                    systemd.mounts = [
                      {
                        what = "http://localhost:9843";
                        where = "/mnt/utm-shared";

                        wantedBy = [ "multi-user.target" ];

                        type = "davfs";
                        # options = "noauto,_netdev,x-systemd.automount,cache=none,credentials=/etc/davfs${secretsPath}/cifs-credentials.txt";
                        options = "noauto,x-systemd.automount";

                        mountConfig = {
                          DirectoryMode = "0777";
                          TimeoutSec = "15";
                        };
                      }
                    ];

                    systemd.automounts = [
                      {
                        where = "/mnt/utm-shared";

                        after = [ "remote-fs-pre.target" ];
                        wants = [ "remote-fs-pre.target" ];
                        conflicts = [ "umount.target" ];
                        before = [ "umount.target" ];
                        wantedBy = [ "remote-fs.target" ];

                        unitConfig = {
                          DefaultDependencies = "no";
                        };

                        automountConfig = {
                          DirectoryMode = "0777";
                          TimeoutIdleSec = "0";
                        };
                      }
                    ];
                  }

                  {
                    imports = [
                      nixos-generators.nixosModules.all-formats
                    ];

                    formatConfigs.qcow = { config, lib, ... }: { };
                  }

                  {
                    services.displayManager.autoLogin = {
                      enable = true;
                      user = "root";
                    };

                    services.xserver = {
                      enable = true;

                      desktopManager.mate.enable = true;
                      displayManager.lightdm.enable = true;
                    };
                  }

                  {
                    systemd.tmpfiles.rules = map
                      (mountPath: "d /userdata/${mountPath} 0777")
                      [
                        "bios"
                        "system"
                        "cheats"
                        "saves"
                        "roms"
                      ];
                  }

                  {
                    imports = [
                      ./profiles/systems/psx
                    ];

                    bato.systems.psx.enable = true;
                  }
                ];
              };
        };
    };
}
