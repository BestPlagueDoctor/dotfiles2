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
      allowedTCPPorts = [ 22 80 443 ];
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
