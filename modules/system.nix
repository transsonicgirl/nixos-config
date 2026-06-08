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

    # Program enables
    programs.steam.enable = true;
    services.mullvad-vpn.enable = true;
    hardware.openrazer.enable = true;
    hardware.openrazer.users = [ "transsonicgirl" ];
    services.tor.enable = true;
    services.tor.client.enable = true;
    services.tailscale.enable = true;
    programs.fish.enable = true;
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs._1password-gui.polkitPolicyOwners = [ "transsonicgirl" ];

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

    # Drivers
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
    
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

}
