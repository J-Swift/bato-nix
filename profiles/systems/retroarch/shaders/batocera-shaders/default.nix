{ lib
  # , writeTextFile
, stdenv
  # , makeWrapper
  # , python311Packages

  # , python311
  # , rsync

, batocera-src
, shader-sets ? [ "sharp-bilinear-simple" "retro" "scanlines" "enhanced" "curvature" "zfast" "flatten-glow" "mega-bezel" "mega-bezel-lite" "mega-bezel-ultralite" ]
, arch ? "x86_64"
}:

let
  # python3 = python311;
  # python3Packages = python311Packages;

  # config-file = writeTextFile {
  #   name = "bato-config";
  #   text = ''
  #     ${lib.concatMapStrings (emu: "${emu}=y\n") emus}
  #   '';
  # };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-shaders";

  version = "v39";

  src = batocera-src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    currentSrc=$(pwd)
    shaderDir=$currentSrc/package/batocera/emulators/retroarch/shaders/batocera-shaders/configs

    echo '1 -----'

    mkdir -p $out/share/batocera/shaders/bezel/Mega_Bezel/Presets
    cp -R $currentSrc/package/batocera/emulators/retroarch/shaders/batocera-shaders/presets-batocera/* $out/share/batocera/shaders/bezel/Mega_Bezel/Presets
    
    echo '2 -----'

    mkdir -p $out/share/batocera/shaders/configs
    cp $shaderDir/rendering-defaults.yml $out/share/batocera/shaders/configs/
    if test -e $shaderDir/rendering-defaults-${arch}.yml; then \
      cp $shaderDir/rendering-defaults-${arch}.yml $out/share/batocera/shaders/configs/rendering-defaults-arch.yml; \
    fi

    echo '3 -----'

    # sets
    for set in {${lib.strings.concatStringsSep "," (lib.map (x: "'${x}'") shader-sets)}}; do
      echo "4 [$set] --------------"
      mkdir -p $out/share/batocera/shaders/configs/$set;
      cp $shaderDir/$set/rendering-defaults.yml $out/share/batocera/shaders/configs/$set/;
      if test -e $shaderDir/$set/rendering-defaults-${arch}.yml; then
        cp $shaderDir/$set/rendering-defaults-${arch}.yml $out/share/batocera/shaders/configs/$set/rendering-defaults-arch.yml
      fi
    done

    runHook postInstall
  '';
})
