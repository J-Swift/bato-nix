{ lib
, SDL2
, SDL2_mixer
, alsa-lib
, boost
, cmake
, curl
, fetchFromGitHub
, freeimage
, freetype
, gettext
, libcec
, libcec_platform
, libGL
, libGLU
, libvlc
, pkg-config
, rapidjson
, stdenv
, udev
  # , google_fonts # needed at runtime
}:

let
  # ubuntu_font = google_fonts.override { fonts = "UbuntuCondensed-Regular.ttf"; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "emulationstation-batocera";

  # NOTE: this is mirroring batocera v39 snapshot
  version = "2024-02-20";
  src = fetchFromGitHub {
    owner = "batocera-linux";
    repo = "batocera-emulationstation";
    rev = "41663d686d9aa2801fb0bda583124776153c8df1";
    fetchSubmodules = true;
    hash = "sha256-uG1q4fvP2AmSTcbFg/G3fFXzGsgwFEzbLOVkr98wsDY=";
  };

  patches = [ ./mypatch.patch ];

  nativeBuildInputs = [
    SDL2
    cmake
    pkg-config
    gettext
  ];

  buildInputs = [
    SDL2
    SDL2_mixer
    alsa-lib
    boost
    curl
    freeimage
    freetype
    libcec
    libcec_platform
    libGL
    libGLU
    libvlc
    rapidjson
    udev
  ];

  strictDeps = true;

  env.NIX_CFLAGS_COMPILE = "-I${lib.getDev SDL2_mixer}/include/SDL2";
  cmakeFlags = [
    (lib.cmakeFeature "OpenGL_GL_PREFERENCE" "LEGACY")
    (lib.cmakeBool "GL" true)
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ../emulationstation $out/bin/emulationstation
    mkdir -p $out/share/emulationstation/
    cp -r ../resources $out/share/emulationstation/
    # cp -r ../resources $out/bin

    # install -m 0755 -d $out/share/emulationstation/resources/help
    # install -m 0755 -d $out/share/emulationstation/resources/flags
    # install -m 0755 -d $out/share/emulationstation/resources/battery
    # install -m 0755 -d $out/share/emulationstation/resources/services
    # install -m 0644 -D ../resources/*.* $out/share/emulationstation/resources
    # install -m 0644 -D ../resources/help/*.* $out/share/emulationstation/resources/help
    # install -m 0644 -D ../resources/flags/*.* $out/share/emulationstation/resources/flags
    # install -m 0644 -D ../resources/battery/*.* $out/share/emulationstation/resources/battery
    # install -m 0644 -D ../resources/services/*.* $out/share/emulationstation/resources/services

    runHook preInstall
  '';

  # es-core/src/resources/ResourceManager.cpp: resources are searched at the
  # same place of binaries.
  postFixup = ''
    pushd $out
    ln -s $out/share/emulationstation/resources $out/bin/
    popd
  '';

  meta = {
    description = "EmulationStation is a cross-platform graphical front-end for emulators with controller navigation.";
    homepage = "https://github.com/batocera-linux/batocera-emulationstation";
    license = lib.licenses.mit;
    mainProgram = "emulationstation-batocera";
    maintainers = [
      {
        email = "jimmyqpublik@gmail.com";
        github = "J-Swift";
        githubId = 734158;
        name = "Jimmy Reichley";
      }
    ];
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
})
