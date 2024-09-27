args@{ config, pkgs, lib, modulesPath, inputs, root, user, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    #extraModulePackages = with config.boot.kernelPackages; [ tp_smapi ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];

    kernelModules = [ "kvm-amd" ];

    #kernelParams = [ "i915.enable_rc6=7" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f1b173e9-b05e-409b-a6eb-80494280e6f7";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C723-1F49";
      fsType = "vfat";
    };

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
    hostName = "navi";
    useDHCP = true;
    wireless.iwd.enable = true;
    networkmanager.enable = false;
    firewall.allowedTCPPorts = [8080 8009 8010];
  };

  home-manager = {
    users."${user.login}" = import "${root}/home";
    extraSpecialArgs = { 
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
    #logind.lidSwitch = "lock";

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
      jack.enable = false;
    };

    udev.packages = with pkgs; [
      ledger-udev-rules
      yubikey-personalization
      (pkgs.writeTextFile {
       name = "52-xilinx-digilent-usb.rules";
       text = ''
       ATTR{idVendor}=="1443", MODE:="666"
       ACTION=="add", ATTR{idVendor}=="0403", ATTR{manufacturer}=="Digilent", MODE:="666"
       '';

       destination = "/etc/udev/rules.d/52-xilinx-digilent-usb.rules";
       })
      (pkgs.writeTextFile {
       name = "52-xilinx-ftdi-usb.rules";
       text = ''
       ACTION=="add", ATTR{idVendor}=="0403", ATTR{manufacturer}=="Xilinx", MODE:="666"
       '';

       destination = "/etc/udev/rules.d/52-xilinx-ftdi-usb.rules";
       })
      (pkgs.writeTextFile {
       name = "52-xilinx-pcusb.rules";
       text = ''
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="0008", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="0007", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="0009", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="000d", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="000f", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="0013", MODE="666"
       ATTR{idVendor}=="03fd", ATTR{idProduct}=="0015", MODE="666"
       '';

       destination = "/etc/udev/rules.d/52-xilinx-pcusb.rules";
       })
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

  virtualisation.virtualbox.host.enable = false;

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

  users.users.sam = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "adbusers" "vboxusers" ];
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
    light.enable = true;
    nix-ld.enable = true;
    hyprland.enable = true;
    steam.enable = true;
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
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  zramSwap.enable = true;
  system.stateVersion = lib.mkForce "21.11";
}
