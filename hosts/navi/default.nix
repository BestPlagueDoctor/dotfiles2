{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      allowed-users = [ "@wheel" ];
      builders-use-substitutes = false;
      require-sigs = false;
    };

    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
  };

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ tp_smapi ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];

    kernelModules = [ "kvm-intel" "tp_smapi" ];

    kernelParams = [ "i915.enable_rc6=7" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/e2ebde39-323d-4813-bc4c-63c344e7c08e";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/B690-60AC";
      fsType = "vfat";
    };
  };

  time.timeZone = "America/Chicago";

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  networking = {
    hostName = "navi";
    interfaces.enp0s25.useDHCP = true;
    wireless.iwd.enable = true;
    networkmanager.enable = false;
    firewall.allowedTCPPorts = [8009 8010];
  };

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    font = "Tamsyn6x12r";
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
      }];
    };
  };

  services = {
    avahi.enable = true;
    blueman.enable = true;
    fstrim.enable = true;
    openssh.enable = true;
    udisks2.enable = true;
    pcscd.enable = true;
    tlp.enable = true;
    upower.enable = true;

    printing = {
      enable = true;
      drivers = with pkgs; [
        cnijfilter2
        gutenprint
        gutenprintBin
      ];
    };

    physlock = {
      enable = true;
      allowAnyUser = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    udev.packages = with pkgs; [
      ledger-udev-rules
      yubikey-personalization
    ];

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

  hardware = {
    bluetooth.enable = true;
    cpu.intel.updateMicrocode = true;

    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
        vaapiIntel
        vaapiVdpau
      ];
    };

    trackpoint = {
      enable = true;
      sensitivity = 150;
      speed = 97;
      emulateWheel = true;
    };
  };

  sound = {
    enable = false;
    mediaKeys = {
      enable = true;
      volumeStep = "5%";
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
    light.enable = true;
    nix-ld.enable = true;
    hyprland.enable = true;
    #steam.enable = true;
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


  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  system.stateVersion = lib.mkForce "21.11";
}
