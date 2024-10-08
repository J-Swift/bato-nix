{ lib
, stdenv
, batocera-src

, makeWrapper
, pciutils
, ffmpeg

, script-type ? "xorg"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-resolution";

  version = "v39";

  src = batocera-src;

  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    pciutils
  ];

  installPhase = ''
    runHook preInstall

    currentSrc=$(pwd)
    batoPath=$currentSrc/package/batocera/core/batocera-resolution/scripts

    mkdir -p $out/bin
    install -m 0755 $batoPath/resolution/batocera-resolution.${script-type} $out/bin/batocera-resolution
    install -m 0755 $batoPath/screenshot/batocera-screenshot.${script-type} $out/bin/batocera-screenshot
    wrapProgram $out/bin/batocera-screenshot \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}

    mkdir -p $out/etc/X11/xorg.conf.d
    cp -prn $currentSrc/board/batocera/x86/fsoverlay/etc/X11/xorg.conf.d/20-amdgpu.conf $out/etc/X11/xorg.conf.d/20-amdgpu.conf

    runHook postInstall
  '';
})
