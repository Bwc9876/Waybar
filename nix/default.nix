{ lib
, pkgs
, version
}:
let
  catch2_3 = {
    src = pkgs.fetchFromGitHub
      {
        owner = "catchorg";
        repo = "Catch2";
        rev = "v3.5.1";
        hash = "sha256-OyYNUfnu6h1+MfCF8O+awQ4Usad0qrdCtdZhYgOY+Vw=";
      };
  };
in
pkgs.callPackage ({ lib
, stdenv
, fetchFromGitHub
, SDL2
, alsa-lib
# , catch2_3
, fftw
, glib
, gobject-introspection
, gtk-layer-shell
, gtkmm3
, howard-hinnant-date
, hyprland
, iniparser
, jsoncpp
, libdbusmenu-gtk3
, libevdev
, libinotify-kqueue
, libinput
, libjack2
, libmpdclient
, libnl
, libpulseaudio
, libsigcxx
, libxkbcommon
, meson
, ncurses
, ninja
, pipewire
, pkg-config
, playerctl
, portaudio
, python3
, scdoc
, sndio
, spdlog
, sway
, udev
, upower
, wayland
, wireplumber
, wlroots
, wrapGAppsHook

, cavaSupport ? true
, evdevSupport ? true
, experimentalPatches ? true
, hyprlandSupport ? true
, inputSupport ? true
, jackSupport ? true
, mpdSupport ? true
, mprisSupport ? stdenv.isLinux
, nlSupport ? true
, pulseSupport ? true
, rfkillSupport ? true
, runTests ? true
, sndioSupport ? true
, swaySupport ? true
, traySupport ? true
, udevSupport ? true
, upowerSupport ? true
, wireplumberSupport ? true
, withMediaPlayer ? mprisSupport && false
}:

let
  # Derived from subprojects/cava.wrap
  libcava.src = fetchFromGitHub {
    owner = "LukashonakV";
    repo = "cava";
    rev = "0.10.1";
    hash = "sha256-iIYKvpOWafPJB5XhDOSIW9Mb4I3A4pcgIIPQdQYEqUw=";
  };
  catch2_3 = pkgs.catch2_3.overrideAttrs (oldAttrs: {
    version = "3.5.1";
    src = pkgs.fetchFromGitHub
      {
        owner = "catchorg";
        repo = "Catch2";
        rev = "v3.5.1";
        hash = "sha256-OyYNUfnu6h1+MfCF8O+awQ4Usad0qrdCtdZhYgOY+Vw=";
      };
  });
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "waybar";
  inherit version;

  src = lib.cleanSourceWith {
    filter = name: type: type != "regular" || !lib.hasSuffix ".nix" name;
    src = lib.cleanSource ../.;
  };

  postUnpack = lib.optional cavaSupport ''
    pushd "$sourceRoot"
    cp -R --no-preserve=mode,ownership ${libcava.src} subprojects/cava-0.10.1
    patchShebangs .
    popd
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    scdoc
    wrapGAppsHook
  ] ++ lib.optional withMediaPlayer gobject-introspection;

  propagatedBuildInputs = lib.optionals withMediaPlayer [
    glib
    playerctl
    python3.pkgs.pygobject3
  ];

  strictDeps = false;

  buildInputs = [
    gtk-layer-shell
    gtkmm3
    howard-hinnant-date
    jsoncpp
    libsigcxx
    libxkbcommon
    spdlog
    wayland
    wlroots
  ]
  ++ lib.optionals cavaSupport [
    SDL2
    alsa-lib
    fftw
    iniparser
    ncurses
    pipewire
    portaudio
  ]
  ++ lib.optional evdevSupport libevdev
  ++ lib.optional hyprlandSupport hyprland
  ++ lib.optional inputSupport libinput
  ++ lib.optional jackSupport libjack2
  ++ lib.optional mpdSupport libmpdclient
  ++ lib.optional mprisSupport playerctl
  ++ lib.optional nlSupport libnl
  ++ lib.optional pulseSupport libpulseaudio
  ++ lib.optional sndioSupport sndio
  ++ lib.optional swaySupport sway
  ++ lib.optional traySupport libdbusmenu-gtk3
  ++ lib.optional udevSupport udev
  ++ lib.optional upowerSupport upower
  ++ lib.optional wireplumberSupport wireplumber
  ++ lib.optional (!stdenv.isLinux) libinotify-kqueue;

  nativeCheckInputs = [ catch2_3 ];
  doCheck = runTests;

  mesonFlags = (lib.mapAttrsToList lib.mesonEnable {
    "cava" = cavaSupport;
    "dbusmenu-gtk" = traySupport;
    # "gtk-layer-shell" = true;
    "jack" = jackSupport;
    "libinput" = inputSupport;
    "libnl" = nlSupport;
    "libudev" = udevSupport;
    "man-pages" = true;
    "mpd" = mpdSupport;
    "mpris" = mprisSupport;
    "pulseaudio" = pulseSupport;
    "rfkill" = rfkillSupport;
    "sndio" = sndioSupport;
    "systemd" = false;
    "tests" = runTests;
    "upower_glib" = upowerSupport;
    "wireplumber" = wireplumberSupport;
  }) ++ lib.optional experimentalPatches (lib.mesonBool "experimental" true);

  preFixup = lib.optionalString withMediaPlayer ''
    cp $src/resources/custom_modules/mediaplayer.py $out/bin/waybar-mediaplayer.py

    wrapProgram $out/bin/waybar-mediaplayer.py \
      --prefix PYTHONPATH : "$PYTHONPATH:$out/${python3.sitePackages}"
  '';

  meta = {
    homepage = "https://github.com/alexays/waybar";
    description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
    changelog = "https://github.com/alexays/waybar/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "waybar";
    maintainers = with lib.maintainers; [
      FlorianFranzen
      jtbx
      lovesegfault
      minijackson
      rodrgz
      synthetica
      khaneliman
    ];
    inherit (wlroots.meta) platforms;
  };
})) {}
