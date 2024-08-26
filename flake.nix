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
      url = "github:J-Swift/nixinate/fix/macos-shm";
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
      ) //
    {
      nixosConfigurations =
        let
          bato-system = "x86_64-linux";
          hostname = "bato-nix";
          stateVersion = "24.11";
        in
        {
          ${hostname} =
            let
            in nixpkgs.lib.nixosSystem
              rec {
                system = bato-system;

                pkgs = import nixpkgs {
                  inherit system;

                  config.allowUnfree = true;
                  # emulationstation-batocera dependency
                  config.permittedInsecurePackages = [
                    "freeimage-unstable-2021-11-01"
                  ];

                  overlays = [
                    (final: prev: {
                      emulationstation-batocera = pkgs.callPackage ./overlays/emulationstation-batocera { };
                    })
                  ];
                };

                modules = [
                  {
                    _module.args.nixinate = {
                      host = "192.168.64.9";
                      sshUser = "root";
                      buildOn = "remote";
                      substituteOnTarget = true;
                      hermetic = false;
                    };
                  }

                  {
                    imports = [
                      nixos-generators.nixosModules.all-formats
                    ];
                  }

                  # boot loader
                  {
                    boot.initrd.availableKernelModules = [ "xhci_pci" "uhci_hcd" "ehci_pci" "ahci" "usbhid" "sd_mod" ];
                    boot.initrd.kernelModules = [ ];
                    boot.kernelModules = [ ];
                    boot.extraModulePackages = [ ];

                    boot.growPartition = true;

                    boot.loader.grub = {
                      enable = true;
                      device = "nodev";
                      efiSupport = true;
                      efiInstallAsRemovable = true;

                      useOSProber = false;
                      configurationLimit = 10;
                    };
                  }

                  {
                    fileSystems."/" = {
                      device = "/dev/disk/by-label/nixos";
                      fsType = "ext4";
                      autoResize = true;
                    };

                    fileSystems."/boot" = {
                      device = "/dev/disk/by-label/ESP";
                      fsType = "vfat";
                    };

                    swapDevices = [ ];

                    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
                    # (the default) this is the recommended approach. When using systemd-networkd it's
                    # still possible to use this option, but it's recommended to use it in conjunction
                    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
                    networking.useDHCP = true;
                    # networking.interfaces.enp0s1.useDHCP = lib.mkDefault true;

                    nixpkgs.hostPlatform = "x86_64-linux";

                    boot.loader.grub.enable = true;

                    system.stateVersion = stateVersion;
                    boot.kernelPackages = pkgs.linuxPackages_6_10;

                    users.users.root = {
                      password = "linux";

                      openssh.authorizedKeys.keys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpmysyMziDLKjj2Faps0jl0aTZETR67zlJmeuSLOR75 jimmy@MbpHal.local"
                      ];
                    };

                    services.openssh.enable = true;
                    time.timeZone = "America/New_York";
                    networking.hostName = hostname;

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

                        after = [ "network-online.target" ];
                        wants = [ "network-online.target" ];

                        type = "davfs";
                        options = "x-systemd.automount";

                        mountConfig = {
                          DirectoryMode = "0777";
                          TimeoutSec = "15";
                        };
                      }
                    ];

                    systemd.automounts = [
                      {
                        where = "/mnt/utm-shared";

                        after = [ "network-online.target" ];
                        wants = [ "network-online.target" ];
                        wantedBy = [ "multi-user.target" ];

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
                    nix = {
                      package = pkgs.nixVersions.latest;
                      extraOptions = ''
                        experimental-features = nix-command flakes
                        bash-prompt-prefix = [flake]\040
                      '';
                    };

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
                    environment.systemPackages = [
                      pkgs.vim
                    ];

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

                    environment.systemPackages = [
                      pkgs.emulationstation-batocera
                    ];

                    bato.systems.psx.enable = true;
                  }
                ];
              };
        };
    };
}
