{ lib
, writeTextFile
, stdenv

, python3
, rsync

, batocera-src
, emus ? [ "BR2_PACKAGE_LIBRETRO_SNES9X" ]
}:

let
  config-file = writeTextFile {
    name = "bato-config";
    text = ''
      ${lib.concatMapStrings (emu: "${emu}=y\n") emus}
    '';
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-python";

  version = "v39";

  src = batocera-src;

  strictDeps = true;

  nativeBuildInputs = [
    rsync
    python3
    python3.pkgs.pyyaml
  ];

  buildPhase = ''
    runHook preBuild

    mkdir -p $out/{tmp,result}
    rsync -a $src/package/batocera/emulationstation/batocera-es-system/roms $out/tmp/
    chmod -R +rw $out/tmp/roms

    cd $src/package/batocera/emulationstation/batocera-es-system
    python3 batocera-es-system.py \
      $src/package/batocera/emulationstation/batocera-es-system/es_systems.yml \
      $src/package/batocera/emulationstation/batocera-es-system/es_features.yml \
      $out/result/es_external_translations.h \
      $out/result/es_keys_translations.h \
      $src/package/batocera \
      $src/package/batocera/emulationstation/batocera-es-system/locales/blacklisted-words.txt \
      ${config-file} \
      $out/result/es_systems.cfg \
      $out/result/es_features.cfg \
      $src/package/batocera/core/batocera-configgen/configs/configgen-defaults.yml \
      $src/package/batocera/core/batocera-configgen/configs/configgen-defaults-x86_64.yml \
      $out/tmp/roms \
      $out/result/roms \
      x86_64

    rm -rf $out/tmp
    cd $out/result
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/emulationstation
    # TODO(jpr): move these to ES src folder
    mv es_external_translations.h $out/share/es_external_translations.h
    mv es_keys_translations.h $out/share/es_keys_translations.h
    install -Dm 0644 es_systems.cfg $out/share/emulationstation/es_systems.cfg
    install -Dm 0644 es_features.cfg $out/share/emulationstation/es_features.cfg

    mkdir -p $out/opt
    mv roms $out/opt
    # mv es_features.cfg $out/opt
    # mv es_systems.cfg $out/opt

    rm -rf $out/result

    runHook postInstall
  '';

  meta = {
    description = "EmulationStation is a cross-platform graphical front-end for emulators with controller navigation.";
    homepage = "https://github.com/batocera-linux/batocera-linux";
    license = lib.licenses.mit;
    # mainProgram = "emulationstation-batocera";
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
