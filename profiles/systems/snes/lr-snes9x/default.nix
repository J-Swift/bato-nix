{ config, pkgs, lib, ... }:

{
  imports = [
    ../../retroarch
  ];

  config = {
    bato.systems.retroarch.enable = true;
    bato.systems.retroarch.cores = [ pkgs.libretro.snes9x ];
  };
}
