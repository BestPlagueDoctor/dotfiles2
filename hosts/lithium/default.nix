args@{ config, pkgs, lib, modulesPath, inputs, root, user, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      #includeDefaultModules = false;
      verbose = false;
      # in case i lose it
      #kernelModules = [ "nvme" "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd"];
      kernelModules = [ "amdgpu" "nvme" ];
    };

    consoleLogLevel = 0;

    kernelModules = [ "kvm-amd" "kvm-intel" "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd"];
    blacklistedKernelModules = [ "nvidia" "nouveau" ];
    kernelParams = [ "amd_iommu=on" "fbcon=map:1" "video=DP-1:1024x768@60" "video=DP-2:1920x1200@60" "video=HDMI-A-1:1920x1080@144" ];
    #extraModprobeConfig = "options kvm_intel nested=1 vfio-pci ids=10de:2484, 10de:228b ";

    postBootCommands = ''
      DEVS="0000:07:00.0 0000:07:00.1"

      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';

    loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        editor = false;
      };
    };
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };
  };

  networking = {
    hostId = "c2c58d17";
    hostName = "lithium";

    wireless.iwd.enable = true;

    interfaces."enp6s0" = {
      useDHCP = true;
      wakeOnLan.enable = true;
    };
    firewall.allowedTCPPorts = [ 8080 ];
  };

  hardware = {
    enableAllFirmware = true;

    bluetooth.enable = true;
    cpu.amd.updateMicrocode = true;
    rtl-sdr.enable = true;

    opengl.extraPackages = with pkgs; [ amdvlk ];
    opengl.extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        rocmPackages.clr.icd
      ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk];
    };

    #nvidia = {
    #  package = config.boot.kernelPackages.nvidiaPackages.stable;
    #  open = true;
    #  modesetting.enable = true;
    #};
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  console = {
    keyMap = "us";
    font = "Tamsyn7x13r";
    packages = [ pkgs.tamsyn ];
    earlySetup = false;
  };

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
    config = {
      cudaSupport = false;
      rocmSupport = true;
    };
  };

  services = {
    blueman.enable = true;
    devmon.enable = true;
    fwupd.enable = true;
    fstrim.enable = true;
    haveged.enable = true;
    i2pd.enable = false;
    iperf3.enable = true;
    physlock.enable = true;
    smartd.enable = true;
    spice-vdagentd.enable = true;
    tcsd.enable = false;
    timesyncd.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;

    avahi = {
      enable = false;
      nssmdns4 = true;
      nssmdns6 = true;
    };

    openssh = {
      enable = true;
      ports = [ 22 2222 ];
      settings = {
        LogLevel = "VERBOSE";
        PasswordAuthentication = false;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    printing = {
      enable = true;
      drivers = with pkgs; [
        canon-cups-ufr2
        gutenprint
        gutenprintBin
        cnijfilter2
      ];
    };

    resolved = {
      enable = false;
      fallbackDns = lib.mkForce [];
      dnssec = "false";
    };

    tor = {
      enable = true;
      client.enable = true;
    };

    udev = {
      packages = with pkgs; [
        yubikey-personalization
        vial
      ];
    };

    usbguard = {
      enable = false;
      rules = builtins.readFile ./conf/usbguard/rules.conf;
    };

    xserver.videoDrivers = [ "amdgpu" ];
  };


  systemd = {
    watchdog.rebootTime = "15s";

    tmpfiles.rules = [
      "d /var/srv 0755 - - -"
      "L /srv - - - - /var/srv"
    ];

    suppressedSystemUnits = [
      "sys-kernel-debug.mount"
    ];
  };

  security = {
    allowUserNamespaces = true;
    protectKernelImage = true;
    unprivilegedUsernsClone = true;
    virtualisation.flushL1DataCache = null;

    apparmor.enable = true;
    auditd.enable = true;
    rtkit.enable = true;
    polkit.enable = true;
    sudo.enable = false;

    acme = {
      acceptTerms = true;
      defaults.email = user.email;
    };

    audit = {
      enable = false;
      rules = [ ];
    };

    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
        noPass = false;
      }];
    };

    pam = {
      u2f.enable = true;
      services = {
        swaylock = {};
        hyprlock = {};
        login.u2fAuth = true;
        doas.u2fAuth = true;
      };
    };

    tpm2 = {
      enable = false;
      abrmd.enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  virtualisation = {
    spiceUSBRedirection.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf = {
          enable = true;
          #package = (pkgs.OVMF.override {
          #  secureBoot = true;
          #  tpmSupport = true;
          #});
        };
      };
    };

    # dont think i need this
    docker = {
      enable = false;
      enableNvidia = false;
    };

    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    users = {
      root.hashedPassword = null;

      "${user.login}" = {
        isNormalUser = true;
        #passwordFile = config.sops.secrets."${user.login}-pw".path;
        hashedPassword = "$6$uu5eUSdw0QK9hPOK$jPrHDxfbRrk5aJw9HX/TNkv5.F.vcqFQhVu3Reuw6Az83/P/bERiTWMOYoHxfXatoroIYoHcocMACir09wMtw.";
        extraGroups = [
          "adbusers"
          "docker"
          "i2c"
          "libvirtd"
          "lp"
          "plugdev"
          "scanner"
          "wheel"
          "qemu-libvirtd"
        ];
      };
    };
  };

  home-manager = {
    users."${user.login}" = import "${root}/home";
    extraSpecialArgs = { 
      inherit inputs root user; 
      stateVersion = "24.11";
      isHeadless = false;
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    variables.ROC_ENABLE_PRE_VEGA = "1";

    systemPackages = (with pkgs; [
      doas-sudo-shim
      hdparm
      lm_sensors
      rdma-core
      lshw
      opensm
      pciutils
      radeontop
      sbctl
      smartmontools
      usbutils

      git
      rsync

      (hunspellWithDicts [ hunspellDicts.en_US hunspellDicts.en_US-large ])

    ]);
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    hyprland.enable = true;
    mosh.enable = true;
    mtr.enable = true;
    nix-ld.enable = true;
    zsh.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
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

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
  };

  ssbm = {
    overlay.enable = true;
    gcc.oc-kmod.enable = true;
    gcc.rules.enable = true;
  };
  zramSwap.enable = true;

  system = {
    stateVersion = lib.mkForce "24.11";
    activationScripts.report-changes = ''
      PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '';
  };
}
