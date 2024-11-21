args@{ config, pkgs, lib, modulesPath, inputs, root, user, ... }:

{
  wsl = {
    enable = true;
    defaultUser = "sam";
    nativeSystemd = true;
    wslConf.network.hostname = "wsl";
    wslConf.automount.root = "/mnt";
  };

  boot.isContainer = true;

  time.timeZone = "America/New_York";

  nix = {
    package = pkgs.nixVersions.latest;
    channel.enable = true;
    nixPath = lib.mkForce [ "nixpkgs=${config.nix.registry.nixpkgs.flake}" ];

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
    };

    settings = {
      allowed-users = lib.mkForce [ "@users" "@wheel" ];
      trusted-users = lib.mkForce [ "@wheel" ];
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

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  networking = {
    hostName = "X1";
    useDHCP = true;
    wireless.iwd.enable = true;
    networkmanager.enable = false;
    firewall.allowedTCPPorts = [8080 8009 8010];
  };

  home-manager = {
    users."${user.login}" = import "${root}/home";
    extraSpecialArgs = { 
      isHeadless = false;
      inherit inputs root user; 
      stateVersion = "24.11";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    font = "Tamsyn7x13r";
    packages = [ pkgs.tamsyn ];
    earlySetup = true;
  };

  security = {
    rtkit.enable = true;
    sudo.enable = false;

    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
        noPass = true;
      }];
    };
  };

  services = {
    avahi.enable = true;
    #blueman.enable = true;
    fstrim.enable = true;
    openssh.enable = true;
    udisks2.enable = true;
    pcscd.enable = true;
    tlp.enable = true;
    upower.enable = true;
    #logind.lidSwitch = "lock";


    actkbd = {
      enable = true;
      bindings = [
      {
        keys = [ 224 ];
        events = [ "key" ];
        command = "${pkgs.light}/bin/light -U 10";
      }
      {
        keys = [ 225 ];
        events = [ "key" ];
        command = "${pkgs.light}/bin/light -A 10";
      }
      ];
    };
  };

  users.users.sam = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = with pkgs; [
      doas-sudo-shim
      comma
      hdparm
      lm_sensors
      lshw
      pciutils
      usbutils
      pcsctools
      git
      rsync
      libGL
    ];

    variables.EDITOR = "nvim";
    pathsToLink = [ "/share/zsh" ];

  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    light.enable = true;
    nix-ld.enable = true;
    hyprland.enable = false;
    steam.enable = false;
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

  zramSwap.enable = true;
  system.stateVersion = lib.mkForce "21.11";
}
