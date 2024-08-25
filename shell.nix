{ pkgs, ... }:

let
  utmRebuild = pkgs.writeScriptBin "utm-rebuild" ''
    #!/usr/bin/env osascript

    tell application "UTM"
      try
        stop virtual machine named "bato-nix"
      end try

      try
        delete virtual machine named "bato-nix"
      end try

      set baseVm to virtual machine named "bato-base"
      set qcow to POSIX file "/Users/jimmy/Developer/bato-nix/_utm/bato-nix.qcow2"

      duplicate baseVm with properties {configuration:{name:"bato-nix", architecture:"x86_64", uefi:false, drives:{{source:qcow}}}}
    end tell
  '';
in
pkgs.mkShell {
  buildInputs = [
    pkgs.nixpkgs-fmt
    utmRebuild
  ];

  shellHook = ''
  '';
}
