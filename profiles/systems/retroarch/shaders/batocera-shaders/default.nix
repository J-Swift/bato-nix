{ lib
, stdenv
, batocera-src

, shader-sets ? [ "sharp-bilinear-simple" "retro" "scanlines" "enhanced" "curvature" "zfast" "flatten-glow" "mega-bezel" "mega-bezel-lite" "mega-bezel-ultralite" ]
, arch ? "x86_64"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-shaders";

  version = "v39";

  src = batocera-src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    currentSrc=$(pwd)
    batoPath=$currentSrc/package/batocera/emulators/retroarch/shaders/batocera-shaders/configs

    mkdir -p $out/share/batocera/shaders/bezel/Mega_Bezel/Presets
    cp -R $currentSrc/package/batocera/emulators/retroarch/shaders/batocera-shaders/presets-batocera/* $out/share/batocera/shaders/bezel/Mega_Bezel/Presets
    
    mkdir -p $out/share/batocera/shaders/configs
    cp $batoPath/rendering-defaults.yml $out/share/batocera/shaders/configs/
    if test -e $batoPath/rendering-defaults-${arch}.yml; then \
      cp $batoPath/rendering-defaults-${arch}.yml $out/share/batocera/shaders/configs/rendering-defaults-arch.yml; \
    fi

    # sets
    for set in {${lib.strings.concatStringsSep "," (lib.map (x: "'${x}'") shader-sets)}}; do
      mkdir -p $out/share/batocera/shaders/configs/$set;
      cp $batoPath/$set/rendering-defaults.yml $out/share/batocera/shaders/configs/$set/;
      if test -e $batoPath/$set/rendering-defaults-${arch}.yml; then
        cp $batoPath/$set/rendering-defaults-${arch}.yml $out/share/batocera/shaders/configs/$set/rendering-defaults-arch.yml
      fi
    done

    runHook postInstall
  '';
})
