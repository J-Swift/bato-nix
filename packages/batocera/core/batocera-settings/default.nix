# package/batocera/core/batocera-settings
{ lib
, stdenv
, batocera-src
, fetchFromGitHub

, meson
, ninja
, pkg-config
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-settings";

  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "batocera-linux";
    repo = "mini_settings";
    rev = finalAttrs.version;
    hash = "sha256-FBhXuajAM1/Cajy7p+BrZDIE0HJrbHUqdXUNYJE+790=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  mesonFlags = [
    "-Ddefault_config_path=/userdata/system/batocera.conf"
    "-Dget_exe_name=batocera-settings-get"
    "-Dset_exe_name=batocera-settings-set"
  ];

  postInstall = ''
    install -m 0755 ${batocera-src}/package/batocera/core/batocera-settings/batocera-settings-get-master $out/bin/batocera-settings-get-master
    substituteInPlace $out/bin/batocera-settings-get-master \
      --replace-fail "/usr/" "/run/current-system/sw/"
  '';
})
