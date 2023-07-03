{ config, pkgs, lib, user, domain, ... }:

{
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6aed6fbc-8e4e-47e2-938e-ccd352f2bfc6";
      fsType = "ext4";
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];
  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    inherit domain;
    hostName = "magi";

    defaultGateway = "10.0.0.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eno1.ipv4.addresses = [ {
      address = "10.0.0.69";
      prefixLength = 24;
    } ];

    firewall = {
      allowedTCPPorts = [ 22 ];
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
      enable = true;
      eula = true;
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };

  security = {
    auditd.enable = true;
    sudo.enable = false;
    pam.services.sshd.showMotd = true;

    allowUserNamespaces = true;
    protectKernelImage = true;
    unprivilegedUsernsClone = false;

    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
      }];
    };
  };

  system.stateVersion = lib.mkForce "22.05";
}
