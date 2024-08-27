{ config, pkgs, lib, ... }:

let
  cfg = config.bato.systems.snes;
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

  config = { };
}
