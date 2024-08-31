{ lib
, stdenv
, batocera-src

, enableMouse ? true
, mouse-type ? "xorg"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "batocera-scripts";

  version = "3";

  sourceRoot = "source/package/batocera/core/batocera-scripts";
  src = batocera-src;

  patchPhase = ''
    runHook prePatch

    substituteInPlace scripts/batocera-vulkan \
      --replace-fail "/usr/bin/vulkaninfo" "/run/current-system/sw/bin/vulkaninfo"

    runHook postPatch
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m 0755 scripts/batocera-vulkan $out/bin/
  '' +
  (lib.optionalString enableMouse ''
    install -m 0755 scripts/batocera-mouse.${mouse-type} $out/bin/batocera-mouse
  '') + ''

    runHook postInstall
    '';
})











