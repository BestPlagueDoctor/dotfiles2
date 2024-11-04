{ config
, osConfig
, pkgs
, system
, lib
, root
, user
, inputs
, stateVersion
, ...
}:

let
  inherit (osConfig.nixpkgs) hostPlatform;

  homeDir = "/home/${user.login}";

  nix-misc = inputs.nix-misc.packages.x86_64-linux;
  ragenix = inputs.ragenix.packages.x86_64-linux.default;

  editor = lib.getBin (pkgs.writeShellScript "editor" ''
    exec ${lib.getBin config.services.emacs.package}/bin/emacsclient -ct $@
  '');
in
{
  home = {
    inherit stateVersion;

    # XXX: https://github.com/nix-community/home-manager/issues/4826
    activation.batCache = lib.mkForce (lib.hm.dag.entryAfter [ "linkGeneration" ] '''');

    username = user.login;
    packages = with pkgs; [
      nixgl.nixGLIntel
      
      asciiquarium
      adwaita-icon-theme
      bemenu
      bluetuith
      breeze-icons
      btop
      bubblewrap
      comma
      direnv
      discord-canary
      dolphin
      dos2unix
      dosfstools
      duf
      easyeffects
      efibootmgr
      exfatprogs
      fasd
      fd
      ffmpeg
      file
      fira-code
      fira-code-symbols
      firefox-wayland
      gh
      gimp-with-plugins
      google-chrome
      grim
      gtk3
      hack-font
      hicolor-icon-theme
      htop
      hyperfine
      imv
      iperf
      jq
      killall
      kotatogram-desktop
      ldns
      libnotify
      libreoffice-fresh
      libva-utils
      lsof
      material-design-icons
      mediainfo
      miniserve
      mpc_cli
      ncdu
      ncspot
      nix-inspect
      nix-output-monitor
      nix-tree
      nmap
      nomacs
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      ntfs3g
      nurl
      onefetch
      pamixer
      pandoc
      patchutils
      pavucontrol
      playerctl
      powertop
      prismlauncher
      procs
      remmina
      ripgrep
      rage
      ragenix
      rclone
      scc
      scrcpy
      simple-scan
      slurp
      sops
      speedtest-cli
      spotify
      strace
      sunshine
      swappy
      swaylock
      tamsyn
      tcpdump
      unzip
      vial
      virt-manager
      vlc
      wget
      whois
      wireshark
      wl-clipboard
      wlr-randr
      xdg-user-dirs
      xdg-utils
      xorg.xeyes
      xorg.xkill
      zellij
      zip
      zoom-us
    ];

    file = {
      dnsCheck = {
        source = "${root}/conf/bin/dnscheck.sh";
        target = ".local/bin/dnscheck";
        executable = true;
      };

      lesskey = {
        target = ".lesskey";
        text = ''
          #env

          #command
          / forw-search ^W
        '';
      };

      emacs-ayu-dark = {
        source = "${root}/conf/emacs/ayu-dark-theme.el";
        target = ".emacs.d/ayu-dark-theme.el";
      };
    };

    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

    # lots of comments in here vro.
    sessionVariables = {
      # General
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      _JAVA_AWT_WM_NONREPARENTING="1";

      # Wayland
      MOZ_ENABLE_WAYLAND = "1";
      #XKB_DEFAULT_OPTIONS = "caps:escape";

      # hyprland
      #LIBVA_DRIVER_NAME="nvidia";
      XDG_SESSION_TYPE="wayland";
      #GBM_BACKEND="nvidia-drm";
      #__GLX_VENDOR_LIBRARY_NAME="nvidia";
      #WLR_NO_HARDWARE_CURSORS="1";

      # Cleaning up home dir
      #CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
      #IPFS_PATH = "${config.xdg.dataHome}/ipfs";
      EDITOR = editor;
    };

    shellAliases = {
      cat = "bat";
      diff = "delta";
      g = "git";
      open = "xdg-open";
      rlf = "readlink -f";
      zc = "zcalc -r";
      zl = "zellij";
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
      btctl = "bluetoothctl";
      please = "sudo !!";
    };
  } // lib.optionalAttrs (hostPlatform.isLinux) {
    pointerCursor = {
      gtk.enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 16;
    };
  };
}
