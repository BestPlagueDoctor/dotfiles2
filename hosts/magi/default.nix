{ config, pkgs, lib, user, ... }:

{
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6aed6fbc-8e4e-47e2-938e-ccd352f2bfc6";
      fsType = "ext4";
    };
  };

  # NFS mounts to expose media to Kodi
  # NOTE: when I transfer this server to a real guy, I'm going to need to do all this again
  fileSystems."/export/music" = {
    device = "/srv/media/music";
    options = [ "bind" ];
  };

  fileSystems."/export/tv" = {
    device = "/srv/media/tv";
    options = [ "bind" ];
  };

  fileSystems."/export/movies" = {
    device = "/srv/media/movies";
    options = [ "bind" ];
  };

  fileSystems."/export/games" = {
    device = "/srv/media/games";
    options = [ "bind" ];
  };

  nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      allowed-users = [ "@users" "@wheel" ];
      experimental-features = [
        "auto-allocate-uids"
        "ca-derivations"
        "flakes"
        "nix-command"
        "recursive-nix"
      ];
      warn-dirty = false;
    };
  };

    
  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "magi";

    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eno1 = {
      useDHCP = true;
      wakeOnLan.enable = true;
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 111 2049 4000 4001 4002 20048 ];
      allowedUDPPorts = [ 111 2049 4000 4001 4002 20048];
    };
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    font = "Tamsyn7x13r";
    packages = [ pkgs.tamsyn ];
    earlySetup = true;
  };

  users = {
    defaultUserShell = pkgs.zsh;

    users = {
      root = {
        home = lib.mkForce "/home/root";
      };

      "${user.login}" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = with pkgs; [
      bottom
      doas-sudo-shim
      fd
      git
      hdparm
      ldns
      lm_sensors
      lshw
      nmap
      pciutils
      profanity
      ripgrep
      rsync
      tmux
      tree
      usbutils
      wget
      figlet
      wakeonlan
      rxvt-unicode
    ];

    shellAliases = {
      sudo = "doas";
    };
  };

  programs = {
    mosh.enable = true;
    mtr.enable = true;
    zsh.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure = {
        customRC = ''
          set number
          set hidden
          set shell=bash
          set cmdheight=2
          set nocompatible
          set shortmess+=c
          set updatetime=300
          set background=dark
          set foldmethod=marker
          set signcolumn=yes
          set nobackup nowritebackup
          set tabstop=2 shiftwidth=2 expandtab
          set tagrelative
          set tags^=./.git/tags;
        set mouse=a
          '';
      };
    };
  };

  services = {
    fstrim.enable = true;
    haveged.enable = true;
    smartd.enable = true;
    timesyncd.enable = true;
    udisks2.enable = true;
    fail2ban.enable = false;

    minecraft-server = {
      enable = false;
      eula = true;
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    nfs = {
      server.enable = true;
      server.lockdPort = 4001;
      server.mountdPort = 4002;
      server.statdPort = 4000;
      server.exports = ''
      /export 10.0.0.86(rw,all_squash,insecure,anonuid=1000,anongid=100)
      /export/music 10.0.0.86(rw,all_squash,insecure,anonuid=1000,anongid=100)
      /export/movies 10.0.0.86(rw,all_squash,insecure,anonuid=1000,anongid=100)
      /export/tv 10.0.0.86(rw,all_squash,insecure,anonuid=1000,anongid=100)
      /export/games 10.0.0.86(rw,all_squash,insecure,anonuid=1000,anongid=100)
    '';
    };

    nginx = {
      user = "sam";
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."plague.oreo.ooo" = {
        forceSSL = true;
        enableACME = true;
        root = "/srv/media";
        locations."/".extraConfig = "autoindex on;";
      };
    };
  };

  security = {
    auditd.enable = true;
    sudo.enable = false;
    pam.services.sshd.showMotd = true;

    allowUserNamespaces = true;
    protectKernelImage = true;
    unprivilegedUsernsClone = false;

    acme = {
      acceptTerms = true;
      defaults.email = user.email;
    };

    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
        noPass = false;
      }];
    };
  };

  system.stateVersion = lib.mkForce "24.11";
}
