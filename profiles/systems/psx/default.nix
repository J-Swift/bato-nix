{ config, pkgs, lib, ... }:

let
  cfg = config.bato.systems.psx;
in
{
  options = {
    bato.systems.psx = {
      enable = lib.mkEnableOption (lib.mdDoc "Playstation 1");
    };
  };

  imports = [
    ./duckstation
  ];

  config = { };
}
