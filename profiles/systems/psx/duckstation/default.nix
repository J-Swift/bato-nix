{ config, pkgs, lib, ... }:

let
  bato-duckstation = pkgs.duckstation.overrideAttrs (finalAttrs: previousAttrs: {
    patches = previousAttrs.patches ++ [ ./004-adjust-paths.patch ];
    cmakeFlags = previousAttrs.cmakeFlags ++ [
      (lib.cmakeBool "BUILD_SHARED_LIBS" false)
      (lib.cmakeBool "BUILD_QT_FRONTEND" true)
    ];
  });
in
{
  environment.systemPackages = [
    bato-duckstation
  ];
}
