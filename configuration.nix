{ config, pkgs, lib, inputs, ... }:

let
  sowm = pkgs.callPackage ./pkgs/sowm.nix { };
in
{
  # ==========================================================================
  # BOOT — kernel giữ nguyên gốc, KHÔNG khai báo boot.kernelPackages,
  # boot.kernelParams, boot.kernelModules, boot.blacklistedKernelModules, ...
  # ==========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1; # menu chờ tối thiểu — vẫn thuộc bootloader, không phải kernel

  # ==========================================================================
  # NETWORK — chỉ iwd, không NetworkManager/wpa_supplicant
  # ==========================================================================
  networking.hostName = "fastnix";
  networking.networkmanager.enable = false;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true; # iwd tự làm DHCP, không cần networkd
  };

  services.resolved.enable = true;

  # Nếu máy dùng card wifi cần firmware non-free để bắt sóng, bật dòng dưới.
  # Đây là firmware blob, không phải chỉnh kernel.
  # hardware.enableRedistributableFirmware = true;

  # ==========================================================================
  # THỜI GIAN
  # ==========================================================================
  services.timesyncd.enable = true;
  time.timeZone = "Asia/Ho_Chi_Minh";

  # ==========================================================================
  # JOURNALD — giới hạn size, không tắt hẳn
  # ==========================================================================
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=20M
    RuntimeMaxUse=50M
  '';

  # ==========================================================================
  # oomd — tắt theo yêu cầu tối giản tuyệt đối
  # ==========================================================================
  systemd.oomd.enable = false;

  # ==========================================================================
  # CÁC SERVICE KHÔNG CẦN — tắt để giảm background task
  # ==========================================================================
  services.printing.enable = false;
  services.avahi.enable = false;
  services.geoclue2.enable = false;
  services.power-profiles-daemon.enable = false;
  services.upower.enable = false;
  services.udisks2.enable = false; # nnn vẫn dùng được, chỉ không auto-mount USB qua polkit
  hardware.bluetooth.enable = false;

  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;

  # ==========================================================================
  # XORG + WM (sowm) — dùng startx, KHÔNG display manager
  # ==========================================================================
  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false; # không cần xterm mặc định, đã có st

  services.xserver.displayManager.startx.enable = true;
  services.xserver.displayManager.startx.generateScript = true;

  services.xserver.windowManager.session = [
    {
      name = "sowm";
      start = ''
        ${sowm}/bin/sowm &
        waitPID=$!
      '';
    }
  ];

  # ==========================================================================
  # AUTOLOGIN + AUTOSTART X — thẳng vào sowm sau khi boot
  # ==========================================================================
  services.getty.autologinUser = "user";

  environment.etc."profile.d/autostart-wm.sh".text = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec startx -- -keeptty > /dev/null 2>&1
    fi
  '';

  # ==========================================================================
  # AUDIO — Pipewire + Wireplumber tối giản, pulse compat bắt buộc cho Zen
  # ==========================================================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true; # Zen (Chromium-based) cần pulse socket
    jack.enable = false;
    wireplumber.enable = true;
  };

  # ==========================================================================
  # SHELL — dash làm login shell + /bin/sh hệ thống
  # ==========================================================================
  environment.binsh = "${pkgs.dash}/bin/dash";
  environment.shells = [ pkgs.dash ];

  # ==========================================================================
  # USER
  # ==========================================================================
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" ];
    shell = pkgs.dash;
    initialPassword = "changeme"; # đổi ngay sau khi cài bằng `passwd`
  };

  # ==========================================================================
  # PACKAGES
  # ==========================================================================
  environment.defaultPackages = lib.mkForce [ ]; # bỏ toàn bộ gói mặc định NixOS thêm vào

  environment.systemPackages = with pkgs; [
    sowm
    st
    dash
    nnn
    dmenu
    inputs.zen-browser.packages.${pkgs.system}.default
  ];

  fonts.packages = with pkgs; [ dejavu_fonts ];
  fonts.fontconfig.enable = true;

  # ==========================================================================
  # NIX
  # ==========================================================================
  nix.settings.auto-optimise-store = true;
  nix.gc.automatic = false; # không bật timer dọn rác định kỳ — tránh background task
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";
}
