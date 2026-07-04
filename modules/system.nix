# SYSTEM.NIX
# System-level config items
{ pkgs, config, ... }:
{
    # User permissions & setup
    users.users.transsonicgirl = {
        isNormalUser = true;
        description = "transsonicgirl";
        extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "dialout" "plugdev" ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORo1J0nR0C8Fu274GaY/FUccDKFo2lQYFhlbqckplvR transsonicgirl@morpheus" ];
    };

    # Kernel modules
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    # Locale
    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";

    # System services
    services.printing.enable = true;
    services.printing.drivers = [ pkgs.brlaser ];
    services.flatpak.enable = true;
    services.cron.enable = true;
    networking.networkmanager.enable = true;
    services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.PermitRootLogin = "no";
    };
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Environment vars
    environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin}";
    };

    # Fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
    ];

    # ZSA keyboard udev rules
    services.udev.extraRules = ''
        # Rules for Oryx web flashing and live training
        KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
        KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

        # Legacy rules for live training over webusb (Not needed for firmware v21+)
          # Rule for all ZSA keyboards
          SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
          # Rule for the Moonlander
          SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
          # Rule for the Ergodox EZ
          SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
          # Rule for the Planck EZ
          SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

        # Wally Flashing rules for the Ergodox EZ
        ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
        ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
        KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

        # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
        # Keymapp Flashing rules for the Voyager
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
        '';
}
