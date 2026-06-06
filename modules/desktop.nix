{ pkgs, ... }:
{
  # Wayland-first stack: Hyprland with SDDM as the login manager.
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  # Audio: PipeWire replacing PulseAudio (matches current Arch setup).
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Printing (CUPS, Brother driver picked up by the deb-derived package on Arch;
  # on NixOS use cups-brother-* or a generic driver — fill in per-host if needed).
  services.printing.enable = true;

  # Fonts: Nerd Fonts + Noto (your Arch system has many — start with a sane subset).
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    nerd-fonts.hack
    nerd-fonts.symbols-only
  ];

  # Bluetooth (you have a Realtek BT radio on morpheus).
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
