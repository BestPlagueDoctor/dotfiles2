{ config, sys, pkgs, lib, root, user, inputs, ... }:

let
  symlink = config.lib.file.mkOutOfStoreSymlink;

  home = "/home/${user.login}";

  files = "${home}/files";
  common = "${home}/common";

  # TODO: Factor this out along with nixpkgs.hostPlatform
  nix-misc = inputs.nix-misc.packages.x86_64-linux;
in
{
  username = user.login;
  homeDirectory = home;
  stateVersion = sys.system.stateVersion;

  packages =
    ## Lang Specific ##
    (with pkgs; [
      gnuapl
      nil
      shellcheck
    ]) ++

    ## CLI Utils ##
    (with nix-misc; [
      git-fuzzy
    ]) ++

    (with pkgs; [
      btop
      comma
      direnv
      duf
      dos2unix
      fasd
      fd
      ffmpeg
      file
      gh
      htop
      hyperfine
      jq
      killall
      libnotify
      libva-utils
      lsof
      mediainfo
      miniserve
      ncdu
      nix-tree
      nurl
      onefetch
      pandoc
      patchutils
      powertop
      procs
      ripgrep
      scc
      sops
      strace
      tcpdump
      unrar
      unzip
      xplr
      zellij
      zip
    ]) ++

    ## Networking ##
    (with pkgs; [
      remmina
      bluetuith
      croc
      gping
      iperf
      ipfs
      ldns
      mosh
      nmap
      scrcpy
      speedtest-cli
      w3m
      wget
      whois
      wireshark
      xh
    ]) ++

    ## Privacy and Security ##
    (with pkgs; [
      bubblewrap
      usbguard
      veracrypt
    ]) ++

    ## Desktop Environment ##
    (with pkgs; [
      firefox-wayland
      google-chrome

      gimp-with-plugins
      libreoffice-fresh

      bemenu
      grim
      imv
      nomacs
      simple-scan
      slurp
      swappy
      swaylock
      wl-clipboard
      wlr-randr

      xdg-user-dirs
      xdg-utils
      xorg.xeyes
      xorg.xkill

      breeze-icons
      gnome.adwaita-icon-theme
      material-design-icons

      fira-code
      fira-code-symbols
      hack-font
      hicolor-icon-theme
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      tamsyn

      gtk3

      vial
    ]) ++

    ## Windows ##
    (with pkgs; [
      ntfs3g
      dosfstools
      efibootmgr
      exfatprogs
    ]) ++

    ## Media ##
    (with pkgs; [
      easyeffects
      mpc_cli
      pamixer
      pavucontrol
      vlc
      yt-dlp
      playerctl
    ]) ++

    ## Communication ##
    (with pkgs; [
      discord-canary
      zoom-us
    ]);

  file = {
    desktop.source = symlink "${files}/desktop";
    dl.source = symlink "${files}/dl";
    docs.source = symlink "${files}/docs";
    media.source = symlink "${files}/media";
    music.source = symlink "${files}/music";
    ss.source = symlink "${files}/ss";
    templates.source = symlink "${files}/templates";

    dnsCheck = {
      source = "${root}/conf/bin/dnscheck.sh";
      target = ".local/bin/dnscheck";
      executable = true;
    };

    lesskey = {
      target = ".lesskey";
      text = ''
        #env
        LESSHISTFILE=${config.xdg.cacheHome}/less/history

        #command
        / forw-search ^W
      '';
    };

    emacs-ayu-dark = {
      source = "${root}/conf/emacs/ayu-dark-theme.el";
      target = ".emacs.d/ayu-dark-theme.el";
    };
  };

  sessionPath = [ "${home}/.local/bin" ];


  sessionVariables = {
    # General
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";

    # Wayland
    MOZ_ENABLE_WAYLAND = "1";
    XKB_DEFAULT_OPTIONS = "caps:escape";

    # hyprland
    LIBVA_DRIVER_NAME="nvidia";
    XDG_SESSION_TYPE="wayland";
    GBM_BACKEND="nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME="nvidia";
    WLR_NO_HARDWARE_CURSORS="1";

    # Cleaning up home dir
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    IPFS_PATH = "${config.xdg.dataHome}/ipfs";
    EDITOR = lib.getBin (pkgs.writeShellScript "editor" ''
      exec ${lib.getBin config.services.emacs.package}/bin/emacsclient -ct $@
    '');
  };

  shellAliases = {
    cat = "bat";
    diff = "delta";
    g = "git";
    open = "xdg-open";
    ovpn = "openvpn3";
    rlf = "readlink -f";
    tf = "terraform";
    zc = "zcalc -r";
    zl = "zellij";
    bz = "bazel";
    ms = "miniserve -HWqrgzl --readme --index index.html";

    noti = "noti ";
    doas = "doas ";
    sudo = "doas ";

    sc = "systemctl";
    jc = "journalctl";
    uc = "systemctl --user";
    udc = "udisksctl";

    vi = "$EDITOR -t";
    vim = "$EDITOR -t";

    rscp = "rsync -ahvP";

    hl = "exec Hyprland";
  };
}
