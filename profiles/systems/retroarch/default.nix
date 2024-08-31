{ config, pkgs, lib, batocera-src, ... }:

let
  cfg = config.bato.systems.retroarch;
in
{
  options = {
    bato.systems.retroarch = {
      enable = lib.mkEnableOption (lib.mdDoc "Retroarch");

      cores = lib.mkOption {
        type = pkgs.lib.types.listOf pkgs.lib.types.package;
        default = [ ];
        description = pkgs.lib.mdDoc ''
          List of libretro cores to install
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      let
        retro-with-cores =
          pkgs.retroarch.override
            {
              cores = cfg.cores;
            };
      in
      [
        retro-with-cores
        (pkgs.callPackage ./shaders/batocera-shaders { inherit batocera-src; })
        (pkgs.callPackage ./libretro-core-info { })
      ];
  };
}
