{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = [
    pkgs.nixpkgs-fmt
  ];

  shellHook = ''
  '';
}
