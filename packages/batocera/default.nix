{ lib
, stdenv
, batocera-src
, makeWrapper
, writeTextFile

, python311
, python311Packages
, rsync

, emus ? [ "BR2_PACKAGE_LIBRETRO_SNES9X" ]
}:

let
  python3 = python311;
  python3Packages = python311Packages;

  config-file = writeTextFile {
    name = "bato-config";
    text = ''
      ${lib.concatMapStrings (emu: "${emu}=y\n") emus}
    '';
  };

  emulator-launcher = python3Packages.buildPythonApplication rec {
    pname = "emulator-launcher";
    version = "2024-08-30";

    sourceRoot = "source/package/batocera/core/batocera-configgen/configgen";
    src = batocera-src;

    patchPhase = ''
      runHook prePatch

      substituteInPlace configgen/batoceraFiles.py \
        --replace-fail "retroarchCores = \"/usr/lib/libretro/\"" "retroarchCores = \"/run/current-system/sw/lib/retroarch/cores/\""
      find ./ -type f -exec sed -i -e 's|/usr/share/|/run/current-system/sw/share/|g' {} \;
      find ./ -type f -exec sed -i -e 's|/usr/bin/|/run/current-system/sw/bin/|g' {} \;
      find ./ -type f -exec sed -i -e 's|/usr/lib/libretro|/run/current-system/sw/lib/retroarch|g' {} \;

      runHook postPatch
    '';

    build-system = [
      python3Packages.setuptools
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-python";

  version = "v39";

  src = batocera-src;
  patchPhase = ''
    runHook prePatch

    pushd package/batocera/core/batocera-configgen/configgen
    substituteInPlace configgen/batoceraFiles.py \
      --replace-fail "retroarchCores = \"/usr/lib/libretro/\"" "retroarchCores = \"/run/current-system/sw/lib/retroarch/cores/\""
    find . -type f -exec sed -i -e 's|/usr/share/|/run/current-system/sw/share/|g' {} \;
    find . -type f -exec sed -i -e 's|/usr/bin/|/run/current-system/sw/bin/|g' {} \;
    find . -type f -exec sed -i -e 's|/usr/lib/libretro|/run/current-system/sw/lib/retroarch|g' {} \;
    popd

    runHook postPatch
  '';

  strictDeps = true;

  nativeBuildInputs = [
    rsync
    python3
    python3.pkgs.pyyaml
    makeWrapper
  ];

  buildInputs = [
    python3
    # python3.pkgs.pyyaml
    python3.pkgs.pyudev
    python3.pkgs.evdev
    python3.pkgs.pillow
    emulator-launcher
  ];

  buildPhase = ''
    runHook preBuild

    currentSrc=$(pwd)

    mkdir -p $out/tmp
    rsync -a package/batocera/emulationstation/batocera-es-system/roms $out/tmp/
    chmod -R +rw $out/tmp/roms

    mkdir -p $out/result
    pushd package/batocera/emulationstation/batocera-es-system
    python3 batocera-es-system.py \
      $currentSrc/package/batocera/emulationstation/batocera-es-system/es_systems.yml \
      $currentSrc/package/batocera/emulationstation/batocera-es-system/es_features.yml \
      $out/result/es_external_translations.h \
      $out/result/es_keys_translations.h \
      $currentSrc/package/batocera \
      $currentSrc/package/batocera/emulationstation/batocera-es-system/locales/blacklisted-words.txt \
      ${config-file} \
      $out/result/es_systems.cfg \
      $out/result/es_features.cfg \
      $currentSrc/package/batocera/core/batocera-configgen/configs/configgen-defaults.yml \
      $currentSrc/package/batocera/core/batocera-configgen/configs/configgen-defaults-x86_64.yml \
      $out/tmp/roms \
      $out/result/roms \
      x86_64
    popd

    mkdir -p $out/datainit/system/configs/emulationstation
    cp $currentSrc/package/batocera/core/batocera-system/batocera.conf $out/datainit/system/
    cp $currentSrc/package/batocera/core/batocera-system/batocera-boot.conf $out/datainit/
    cp $currentSrc/package/batocera/emulationstation/batocera-emulationstation/controllers/es_input.cfg $out/datainit/system/configs/emulationstation/

    mkdir -p $out/init.d
    cp $currentSrc/board/batocera/fsoverlay/etc/init.d/rcS $out/init.d/
    substituteInPlace $out/init.d/rcS \
      --replace-fail "for i in /etc/init.d/" "for i in $out/init.d/"
    cp $currentSrc/board/batocera/fsoverlay/etc/init.d/S12populateshare $out/init.d/
    substituteInPlace $out/init.d/S12populateshare \
      --replace-fail "IN=/usr/share/batocera/datainit" "IN=$out/datainit"

    mkdir -p $out/{bin,opt}
    rsync -a $currentSrc/package/batocera/core/batocera-configgen $out/opt/

    ln -sf $out/opt/batocera-configgen/configgen/configgen/emulatorlauncher.py $out/bin/emulatorlauncher
    chmod +x $out/bin/emulatorlauncher

    wrapProgram $out/bin/emulatorlauncher \
      --prefix PATH : ${lib.makeBinPath [ python3 ]} \
      --prefix PYTHONPATH : "$PYTHONPATH"

    rm -rf $out/tmp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    currentSrc=$(pwd)

    mkdir -p $out/share/emulationstation
    # TODO(jpr): move these to ES src folder
    mv $out/result/es_external_translations.h $out/share/es_external_translations.h
    mv $out/result/es_keys_translations.h $out/share/es_keys_translations.h
    install -Dm 0644 $out/result/es_systems.cfg $out/share/emulationstation/es_systems.cfg
    install -Dm 0644 $out/result/es_features.cfg $out/share/emulationstation/es_features.cfg

    mkdir -p $out/share/batocera/configgen
    cp $currentSrc/package/batocera/core/batocera-configgen/configs/configgen-defaults.yml \
      $out/share/batocera/configgen/configgen-defaults.yml
    cp $currentSrc/package/batocera/core/batocera-configgen/configs/configgen-defaults-x86_64.yml \
      $out/share/batocera/configgen/configgen-defaults-arch.yml

    mkdir -p $out/opt
    mv $out/result/roms $out/opt

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
