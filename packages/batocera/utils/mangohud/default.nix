{ lib
, stdenv
, batocera-src
, fetchFromGitHub
, fetchurl

, meson
, ninja
, pkg-config
, unzip
, glslang
, python311
, python311Packages
, libdrm
, libX11
, dbus

, enableDrm ? true
, enableVulkan ? true
, enableXorg ? true
, enableWayland ? false
}:

let
  python3 = python311;
  python3Packages = python311Packages;

  imgui = rec {
    version = "1.81";
    fs-name = "imgui-${imgui.version}";
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "refs/tags/v${version}";
      hash = "sha256-rRkayXk3xz758v6vlMSaUu5fui6NR8Md3njhDB0gJ18=";
    };
    patch = fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/imgui_${version}-1/get_patch";
      hash = "sha256-bQC0QmkLalxdj4mDEdqvvOFtNwz2T1MpTDuMXGYeQ18=";
    };
  };

  spdlog = rec {
    version = "1.8.5";
    fs-name = "spdlog-${spdlog.version}";
    src = fetchFromGitHub {
      owner = "gabime";
      repo = "spdlog";
      rev = "refs/tags/v${version}";
      hash = "sha256-D29jvDZQhPscaOHlrzGN1s7/mXlcsovjbqYpXd7OM50=";
    };
    patch = fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/spdlog_${version}-1/get_patch";
      hash = "sha256-PDjyddV5KxKGORECWUMp6YsXc3kks0T5gxKrCZKbdL4=";
    };
  };

  vulkan-headers = rec {
    version = "1.2.158";
    fs-name = "Vulkan-Headers-${vulkan-headers.version}";
    src = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Headers";
      rev = "refs/tags/v${version}";
      hash = "sha256-5uyk2nMwV1MjXoa3hK/WUeGLwpINJJEvY16kc5DEaks=";
    };
    patch = fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/vulkan-headers_${version}-2/get_patch";
      hash = "sha256-hgNYz15z9FjNHoj4w4EW0SOrQh1c4uQSnsOOrt2CDhc=";
    };
  };

  subprojects = [ imgui spdlog vulkan-headers ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mangohud";

  version = "2021-10-01";

  src = fetchFromGitHub {
    owner = "flightlessmango";
    repo = "MangoHud";
    rev = "a8a0a245e69fbbca5263d2436fd1c04289375498";
    hash = "sha256-eOaYKFTYK2hs1DCaAWW4w6ugN3pZ2qWxE3VIjew4+tM=";
  };

  postUnpack = ''(
    cd "$sourceRoot/subprojects"
    
    ${lib.concatMapStrings
      (sub: "cp -R --no-preserve=mode,ownership ${sub.src} ${sub.fs-name}\n")
      subprojects}
  )'';

  patches = [
    "${batocera-src}/package/batocera/utils/mangohud/0001-vulkan-Per-device-font-image-s.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0002-WIP-separate-transfer-queue-command.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0003-add-stb_image-and-stb_image_resize.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0004-add-load-textures-functions.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0005-convert-textures-to-rgba.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0006-options-image-path-image_max_width-int-image_backgro.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0007-Option-to-use-vulkan.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0008-mangohud-on-drm.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0009-desc-pool-flag.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0010-wip-single-params.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0011-wip-images.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0012-wip-notifier.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0013-wip-set-image-unloaded.patch"
    "${batocera-src}/package/batocera/utils/mangohud/0014-wip-simpler-locking-q.patch"
  ];

  postPatch = ''
    substituteInPlace bin/mangohud.in \
      --subst-var-by libraryPath ${lib.makeSearchPath "lib/mangohud" ([
        (placeholder "out")
      ])} \
      --subst-var-by version "${finalAttrs.version}" \
      --subst-var-by dataDir ${placeholder "out"}/share

    (
      cd subprojects
      ${lib.concatMapStrings
        (sub: "unzip ${sub.patch}\n")
        subprojects}
    )
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    unzip
    glslang
    python3
    python3Packages.mako
  ] ++ (lib.optional enableXorg libX11);

  buildInputs = [ dbus ]
    ++ (lib.optional enableDrm libdrm);
  # ++ (lib.optional enableVulkan vulkan-headers);
  # ++ (lib.optional enableXorg xorg.xorgserver);

  mesonFlags = [
    "-Dwith_xnvctrl=disabled"
    "-Duse_vulkan=${if enableVulkan then "true" else "false"}"
    "-Dwith_x11=${if enableXorg then "enabled" else "disabled"}"
    "-Dwith_wayland=${if enableWayland then "enabled" else "disabled"}"
  ];

  # postInstall = ''
  #   install -m 0755 ${batocera-src}/package/batocera/core/batocera-settings/batocera-settings-get-master $out/bin/batocera-settings-get-master
  #   substituteInPlace $out/bin/batocera-settings-get-master \
  #     --replace-fail "/usr/" "/run/current-system/sw/"
  # '';
})
