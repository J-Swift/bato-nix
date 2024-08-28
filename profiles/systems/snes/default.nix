{ config, pkgs, lib, ... }:

let
  cfg = config.bato.systems.snes;

  static-data = pkgs.stdenv.mkDerivation {
    name = "static-data-snes";

    src = ./baked-roms;

    # test = pkgs.writeText "test" ''
    #   hello world
    # '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/snes-static-data
      cp -r $src/* $out/share/snes-static-data/

      runHook postInstall
    '';
  };

  carbon-theme = pkgs.stdenv.mkDerivation {
    name = "bato-carbon-theme";

    src = pkgs.fetchFromGitHub {
      owner = "fabricecaruso";
      repo = "es-theme-carbon";
      rev = "6b868454cad63296a3f36b1d3c5307d60f23ac2b";
      hash = "sha256-6YfQzy6ednKu3cGuQ1FsL4W+lxymVVVOwOt9ePUXeEQ=";
    };

    # test = pkgs.writeText "test" ''
    #   hello world
    # '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/emulationstation/themes/es-theme-carbon
      cp -r $src/* $out/share/emulationstation/themes/es-theme-carbon

      runHook postInstall
    '';

  };
in
{
  options = {
    bato.systems.snes = {
      enable = lib.mkEnableOption (lib.mdDoc "Super Nintendo");
    };
  };

  imports = [
    ./lr-snes9x
  ];

  config = lib.mkIf cfg.enable {
    environment.etc."emulationstation/es_systems.cfg" = {
      source = ./es_systems.cfg;
    };

    environment.systemPackages = [
      static-data
      carbon-theme
    ];
  };
}
