{ config, pkgs, lib, modulesPath, inputs, root, user, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];


  ssbm = {
    overlay.enable = true;
    gcc.oc-kmod.enable = true;
    gcc.rules.enable = true;
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

  boot = {
    initrd = {
      #includeDefaultModules = false;
      verbose = false;
      # in case i lose it
      #kernelModules = [ "nvme" "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd"];
      kernelModules = [ "nvme" ];
      #blacklistedKernelModules = [ "nvidia" "nouveau" ];
    };
    #supportedFilesystems = [ "zfs" ];

    consoleLogLevel = 0;
    #kernelModules = [
    #  "ib_umad"
    #  "ib_ipoib"
    #];

    kernelModules = [ "kvm-amd" "kvm-intel" "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd"];
    blacklistedKernelModules = [ "nvidia" "nouveau" ];
    kernelParams = [ "amd_iommu=on" "fbcon=map:1" ];
    #extraModprobeConfig = "options kvm_intel nested=1 vfio-pci ids=10de:2484, 10de:228b ";

    postBootCommands = ''
      DEVS="0000:07:00.0 0000:07:00.1"

      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';


/*

    kernelParams = [
      "elevator=none"
      "kvm.nx_huge_pages=force"
      "lsm=yama,apparmor,bpf"
      "quiet"
      "slub_debug=FZ"
      "udev.log_priority=3"
    ];

    kernel.sysctl = {
      # Needed for router
      "net.ipv4.conf.all.accept_redirects" = true;
      "net.ipv6.conf.all.accept_redirects" = true;
      "net.ipv4.conf.all.accept_source_route" = true;
      "net.ipv6.conf.all.accept_source_route" = true;
      "net.ipv4.ip_forward" = true;
      "net.ipv4.conf.all.send_redirects" = true;

      "net.ipv4.conf.all.secure_redirects" = true;
      "net.ipv6.conf.all.secure_redirects" = true;

      "net.ipv4.conf.all.log_martians" = true;
      "net.ipv4.conf.all.rp_filter" = true;

      "net.ipv4.icmp_echo_ignore_all" = false;
      "net.ipv4.icmp_echo_ignore_broadcasts" = true;
      "net.ipv4.icmp_ignore_bogus_error_responses" = true;

      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_dsack" = false;
      "net.ipv4.tcp_fack" = false;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_rfc1337" = true;
      "net.ipv4.tcp_sack" = false;
      "net.ipv4.tcp_synack_retries" = 5;
      "net.ipv4.tcp_timestamps" = false;
      "net.ipv4.tcp_window_scaling" = true;

      "net.ipv6.conf.default.accept_ra" = false;
      "net.ipv6.conf.default.accept_ra_pinfo" = false;
      "net.ipv6.conf.default.accept_ra_rtr_pref" = false;
      "net.ipv6.conf.default.aceept_ra_defrtr" = false;
      "net.ipv6.conf.default.max_addresses" = 1;
      "net.ipv6.conf.default.router_solicitations" = false;

      "net.core.bpf_jit_harden" = 2;
      "net.core.default_qdisc" = "cake";
      "net.core.netdev_max_backlog" = 5000;
      "net.core.rmem_max" = 8388608;
      "net.core.wmem_max" = 8388608;

      "kernel.core_uses_pid" = true;
      "kernel.kptr_restrict" = 2;
      "kernel.panic_on_oops" = false;
      "kernel.perf_event_paranoid" = 3;
      "kernel.printk" = "3 3 3 3";
      "kernel.randomize_va_space" = 2;
      "kernel.unprivileged_bpf_disabled" = true;
      "kernel.yama.ptrace_scope" = 2;

      # Appropriate for x86
      "vm.max_map_count" = 1048576;
      "vm.mmap_rnd_bits" = 32;
      "vm.mmap_rnd_compat_bits" = 16;

      "user.max_user_namespaces" = 10000;

      "fs.protected_hardlinks" = true;
      "fs.protected_symlinks" = true;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
    };

*/

    loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        editor = false;
      };
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

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
    };

    #nvidia = {
    #  package = config.boot.kernelPackages.nvidiaPackages.stable;
    #  open = true;
    #  modesetting.enable = true;
    #};

    sane = {
      enable = true;
      extraBackends = with pkgs; [
        sane-airscan
      ];
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  console = {
    keyMap = "us";
    font = "Tamsyn7x13r";
    packages = [ pkgs.tamsyn ];
    earlySetup = false;
  };

  nix = {
    package = pkgs.nixUnstable;
    nixPath = lib.mkForce [ "nixpkgs=${config.nix.registry.nixpkgs.flake}" ];

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
    };

    #buildMachines = [
    #  {
    #    hostName = "home.armeen.org";
    #    sshKey = "/home/sam/.ssh/id_ecdsa";
    #    sshUser = "sam";
    #    supportedFeatures = [ "kvm" "big-parallel" "ca-derivations" "nixos-test" ];
    #    system = "x86_64-linux,aarch64-linux,i686-linux";
    #    maxJobs = 32;
    #    speedFactor = 100;
    #  }

    #  {
    #    hostName = "10.0.0.69";
    #    sshKey = "/home/sam/.ssh/id_ecdsa";
    #    sshUser = "sam";
    #    system = "x86_64-linux,aarch64-linux,i686-linux";
    #    maxJobs = 1;
    #    speedFactor = 5;
    #  }
    #];



    settings = {
      allowed-users = lib.mkForce [ "@wheel" ];
      trusted-users = lib.mkForce [ "@wheel" ];
      builders-use-substitutes = true;
      require-sigs = false;
      #substituters = [
      #  "https://cache.ngi0.nixos.org"
      #  "https://nix-community.cachix.org"
      #  "ssh://sam@home.armeen.org?ssh-key=/home/sam/.ssh/id_ecdsa"
      #];
      trusted-public-keys = [
        "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    extraOptions = ''
      warn-dirty = false
      experimental-features = flakes nix-command ca-derivations
    '';
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  services = {
    blueman.enable = true;
    flatpak.enable = true;
    fstrim.enable = true;
    haveged.enable = true;
    i2pd.enable = false;
    iperf3.enable = true;
    onedrive.enable = true;
    physlock.enable = true;
    saned.enable = true;
    smartd.enable = true;
    spice-vdagentd.enable = true;
    tcsd.enable = false;
    timesyncd.enable = true;
    udisks2.enable = true;
    fwupd.enable = true;

    avahi = {
      enable = true;
      nssmdns = true;
    };

    monero = {
      enable = false;

      rpc = { };

      extraConfig = ''
        rpc-use-ipv6=1
        rpc-ignore-ipv4=1
        rpc-bind-ipv6-address=::1
        rpc-restricted-bind-ipv6-address=::1
        rpc-restricted-bind-port=18089

        p2p-use-ipv6=1
        p2p-ignore-ipv4=1
        p2p-bind-ipv6-address=::
        no-igd=1
        no-zmq=1
        enforce-dns-checkpointing=1
      '';
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    openssh = {
      enable = true;
      ports = [ 22 2222 ];
      settings = {
        LogLevel = "VERBOSE";
        PasswordAuthentication = false;
        X11Forwarding = true;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        gutenprintBin
        cnijfilter2
      ];
    };

    tor = {
      enable = true;
      client.enable = true;
    };

    udev = {
      packages = with pkgs; [
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

      extraRules = ''
        ACTION=="add|change"                                                    \
        , KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*" \
        , ENV{ID_FS_TYPE}=="zfs_member"                                         \
        , ATTR{../queue/scheduler}="none"
      '';
    };

    usbguard = {
      enable = false;
      rules = builtins.readFile ./conf/usbguard/rules.conf;
    };

    xserver.videoDrivers = [ "amdgpu" ];

    /*
    zfs = {
      trim.enable = true;
      autoScrub.enable = true;
      autoSnapshot.enable = true;
    };
    */
  };


  systemd = {
    watchdog.rebootTime = "15s";

    tmpfiles.rules = [
      "d /run/cache 0755 - - -"
      "d /var/etc 0755 - - -"
      "d /var/srv 0755 - - -"
      "d /run/tmp 1777 - - -"

      "L /srv - - - - /var/srv"
      "L /tmp - - - - /run/tmp"

      # Using /home/root instead
      "R /root - - - - -"

      # For Wolfram kernel
      "L /bin/uname - - - - ${pkgs.coreutils}/bin/uname"
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
      services.swaylock = {};
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
    virtualbox.host.enable = true;
    #waydroid.enable = true;

    libvirtd = {
      enable = true;
      qemuOvmf = true;
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
      enableNvidia = true;
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
      root = {
        hashedPassword = null;
        home = lib.mkForce "/home/root";
      };

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
          "vboxusers"
          "qemu-libvirtd"
        ];
      };
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];

    systemPackages = (with pkgs; [
      rdma-core
      lshw
      opensm
      radeontop
      smartmontools
      usbutils

      git
      rsync

      (hunspellWithDicts [ hunspellDicts.en_US hunspellDicts.en_US-large ])

      #(lkrg.override { kernel = config.boot.kernelPackages.kernel; })
    ])
    ++
    (with pkgs.pkgsMusl; [
      hdparm
      lm_sensors
      pciutils
    ]);

    etc = {
      /*
      "ssh/ssh_host_ed25519_key".source = "/var/etc/ssh/ssh_host_ed25519_key";
      "ssh/ssh_host_ed25519_key.pub".source = "/var/etc/ssh/ssh_host_ed25519_key.pub";
      "ssh/ssh_host_rsa_key".source = "/var/etc/ssh/ssh_host_rsa_key";
      "ssh/ssh_host_rsa_key.pub".source = "/var/etc/ssh/ssh_host_rsa_key.pub";
      */

      openvpn.source = "${pkgs.update-resolv-conf}/libexec/openvpn";
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    mtr.enable = true;
    nix-ld.enable = true;
    zsh.enable = true;

    custom.ddcutil = {
      enable = true;
      users = [ user.login ];
    };

    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default.override { enableNvidiaPatches = true; };
    };

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

/*
  sops = {
    defaultSopsFile = "${root}/secrets/secrets.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "${user.login}-pw".neededForUsers = true;
    };
  };
*/

  zramSwap.enable = true;

  system.stateVersion = lib.mkForce "22.11";
}
