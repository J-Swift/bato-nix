{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libretro-core-info";

  # NOTE: this is mirroring batocera v39 snapshot
  version = "v1.16.0";
  src = fetchFromGitHub {
    owner = "libretro";
    repo = "libretro-core-info";
    rev = finalAttrs.version;
    hash = "sha256-LK+iBKi5Rq/8zpOzwqql8xEUj84+mH6o5KbNCMH7sMA=";
  };

  dontBuild = true;

  makeFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    currentSrc=$(pwd)

    mkdir -p $out/share/libretro/info

    cd $out/share/libretro/info
    ln -sf mednafen_saturn_libretro.info      beetle-saturn_libretro.info
    ln -sf bsnes_hd_beta_libretro.info        bsnes_hd_libretro.info
    ln -sf genesis_plus_gx_wide_libretro.info genesisplusgx-wide_libretro.info
    ln -sf genesis_plus_gx_libretro.info      genesisplusgx_libretro.info
    ln -sf mame2010_libretro.info             mame0139_libretro.info
    ln -sf mame2003_plus_libretro.info        mame078plus_libretro.info
    ln -sf mame_libretro.info                 mess_libretro.info
    ln -sf mupen64plus_next_libretro.info     mupen64plus-next_libretro.info
    ln -sf mednafen_pce_fast_libretro.info    pce_fast_libretro.info
    ln -sf mednafen_pce_libretro.info         pce_libretro.info
    ln -sf mednafen_pcfx_libretro.info        pcfx_libretro.info
    ln -sf snes9x2002_libretro.info           pocketsnes_libretro.info
    ln -sf snes9x2010_libretro.info           snes9x_next_libretro.info
    ln -sf vbam_libretro.info                 vba-m_libretro.info
    ln -sf mednafen_vb_libretro.info          vb_libretro.info

    # emuscv_libretro.info         => no info found
    # mamevirtual_libretro.so      => no info found
    # superflappybirds_libretro.so => no info found
    # zc210_libretro.so            => no info found
    # hatarib_libretro.info       => no info found
    touch $out/share/libretro/info/emuscv_libretro.info
    touch $out/share/libretro/info/mamevirtual_libretro.info
    touch $out/share/libretro/info/superflappybirds_libretro.info
    touch $out/share/libretro/info/zc210_libretro.info
    touch $out/share/libretro/info/hatarib_libretro.info
  '';
})
