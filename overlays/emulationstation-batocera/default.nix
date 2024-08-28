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
}:

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

  patches = [ ./001-add-nixos-share-path.patch ];

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
    libGL
    libGLU
    libvlc
    rapidjson
    udev
  ];

  strictDeps = true;
  dontStrip = true;

  cmakeBuildType = "Debug";
  env.NIX_CFLAGS_COMPILE = "-I${lib.getDev SDL2_mixer}/include/SDL2";
  cmakeFlags = [
    # (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Debug")
    (lib.cmakeBool "BATOCERA" true)
    (lib.cmakeFeature "CMAKE_C_FLAGS" "-DX86_64")
    (lib.cmakeFeature "CMAKE_C_FLAGS" "-g")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-DX86_64")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-g")
    (lib.cmakeFeature "OpenGL_GL_PREFERENCE" "LEGACY")
    (lib.cmakeBool "DISABLE_KODI" true)
    (lib.cmakeBool "CEC" false)
    (lib.cmakeBool "GL" true)
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ../emulationstation $out/bin/emulationstation
    mkdir -p $out/share/emulationstation/
    cp -r ../resources $out/share/emulationstation/

    runHook postInstall
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
