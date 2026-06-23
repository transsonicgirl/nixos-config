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
    services.openssh.enable = true;
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
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
        # ZSA keyboards
        KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
        KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

        # Rule for all ZSA keyboards
        SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
        # Rule for the Moonlander
        SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
        # Rule for the Ergodox EZ
        SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1308", GROUP="plugdev"
        # Rule for the Planck EZ
        SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"
        # Voyager
        SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1976", GROUP="plugdev"
        '';
}
