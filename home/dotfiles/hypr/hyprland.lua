--------------------------------------------------------------------------------
--  Hyprland config — Lua format
--  The .conf (hyprlang) format is deprecated and is removed in Hyprland 0.57.
--  Hyprland prefers hyprland.lua over hyprland.conf when both are present.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  VARIABLES
--------------------------------------------------------------------------------

local mod = "SUPER"

-- Update this to your preferred terminal if you switch away from kitty
local terminal = "kitty"
local launcher = "wofi --show run"

hl.env("STEAM_FRAME_FORCE_CLOSE", "1")

--------------------------------------------------------------------------------
--  CURSOR
--------------------------------------------------------------------------------

hl.env("HYPRCURSOR_THEME", "KasaneTeto")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "KasaneTeto")
hl.env("XCURSOR_SIZE", "24")

--------------------------------------------------------------------------------
--  MONITORS
--  DP-2 is primary (right), DP-1 is to its left.
--  `preferred` picks the monitor's native resolution automatically.
--  To force 180Hz explicitly, replace "preferred" with e.g. "2560x1440@180"
--------------------------------------------------------------------------------

hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = "1" })
hl.monitor({ output = "DP-2", mode = "preferred", position = "auto-left", scale = "1" })

--------------------------------------------------------------------------------
--  AUTOSTART
--  hl.on("hyprland.start", ...) is the exec-once equivalent: it runs at startup
--  but not on every config reload.
--------------------------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd("dex --autostart --environment hyprland"))
    hl.dispatch(hl.dsp.exec_cmd("nm-applet --indicator"))
    hl.dispatch(hl.dsp.exec_cmd("hyprpaper"))
    hl.dispatch(hl.dsp.exec_cmd("waybar"))
    hl.dispatch(hl.dsp.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"))
    hl.dispatch(hl.dsp.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland"))
end)

--------------------------------------------------------------------------------
--  CATPPUCCIN MOCHA COLORS
--------------------------------------------------------------------------------

local c = {
    rosewater = "rgb(f5e0dc)",
    flamingo  = "rgb(f2cdcd)",
    pink      = "rgb(f5c2e7)",
    mauve     = "rgb(cba6f7)",
    red       = "rgb(f38ba8)",
    maroon    = "rgb(eba0ac)",
    peach     = "rgb(fab387)",
    yellow    = "rgb(f9e2af)",
    green     = "rgb(a6e3a1)",
    teal      = "rgb(94e2d5)",
    sky       = "rgb(89dceb)",
    sapphire  = "rgb(74c7ec)",
    blue      = "rgb(89b4fa)",
    lavender  = "rgb(b4befe)",
    text      = "rgb(cdd6f4)",
    subtext1  = "rgb(bac2de)",
    subtext0  = "rgb(a6adc8)",
    overlay2  = "rgb(9399b2)",
    overlay1  = "rgb(7f849c)",
    overlay0  = "rgb(6c7086)",
    surface2  = "rgb(585b70)",
    surface1  = "rgb(45475a)",
    surface0  = "rgb(313244)",
    base      = "rgb(1e1e2e)",
    mantle    = "rgb(181825)",
    crust     = "rgb(11111b)",
}

--------------------------------------------------------------------------------
--  INPUT / GENERAL / DECORATION
--------------------------------------------------------------------------------

hl.config({
    input = {
        follow_mouse = 0, -- 0 = focus does not follow mouse (matches the i3 config)
        sensitivity  = 0, -- pointer sensitivity, 0 = no change
    },

    general = {
        gaps_in     = 5,
        gaps_out    = 0,
        border_size = 2,

        col = {
            active_border   = c.lavender,
            inactive_border = c.overlay0,
        },

        layout = "dwindle", -- closest to i3's tiling behavior
    },

    -- Hyprland has a built-in compositor, so picom is not needed.
    decoration = {
        rounding = 5, -- matches corner-radius = 5 in picom.conf

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Terminal opacity is set per-window in WINDOW RULES below.

        blur = {
            enabled = false, -- no blur was configured in picom, keeping it off
        },

        shadow = {
            enabled = false, -- no shadows were configured in picom
        },
    },

    animations = {
        enabled = true,
    },

    -- Dwindle is the closest match to i3's tiling. It splits alternately
    -- horizontal/vertical. `togglesplit` (bound to mod+c / mod+v / mod+e below)
    -- flips the split direction for the current node.
    dwindle = {
        preserve_split = true,
        smart_split    = false,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        focus_on_activate        = true, -- matches: focus_on_window_activation urgent
        -- NOTE: workspace_back_and_forth does not exist in Hyprland.
        -- Pressing a workspace key while already on it does nothing by default.
    },
})

--------------------------------------------------------------------------------
--  ANIMATIONS
--  Set animations.enabled = false above to disable entirely.
--------------------------------------------------------------------------------

hl.curve("ease", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "ease" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "ease" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "ease" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "ease" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "ease" })

--------------------------------------------------------------------------------
--  WORKSPACES
--  Named workspaces: work, reference, background, then 4-10
--------------------------------------------------------------------------------

hl.workspace_rule({ workspace = "name:work",       monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "name:reference",  monitor = "DP-2" })
hl.workspace_rule({ workspace = "name:background", monitor = "DP-2" })

for i = 4, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1" })
end

--------------------------------------------------------------------------------
--  WINDOW RULES
--------------------------------------------------------------------------------

-- App -> workspace assignments
hl.window_rule({
    name      = "discord-to-background",
    match     = { class = "discord" },
    workspace = "name:background",
})

hl.window_rule({
    name      = "firefox-to-reference",
    match     = { class = "firefox" },
    workspace = "name:reference",
})

hl.window_rule({
    name      = "code-to-work",
    match     = { class = "code" },
    workspace = "name:work",
})

hl.window_rule({
    name      = "Code-to-work",
    match     = { class = "Code" },
    workspace = "name:work",
})

hl.window_rule({
    name    = "kitty-opacity",
    match   = { class = "kitty" },
    opacity = "0.75 0.75",
})

-- Assetto Corsa window sizing
hl.window_rule({
    name       = "assetto-corsa",
    match      = { class = "steam_app_244210", title = "^(Assetto Corsa)$" },
    monitor    = "DP-1",
    fullscreen = true,
})

--------------------------------------------------------------------------------
--  KEYBINDS
--------------------------------------------------------------------------------

-- - Terminal & launcher -
hl.bind(mod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + d",      hl.dsp.exec_cmd(launcher))

-- - Kill focused window (i3: mod+q) -
hl.bind(mod .. " + q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprctl kill")) -- kill cursor

-- - App shortcuts -
hl.bind(mod .. " + SHIFT + f", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + SHIFT + d", hl.dsp.exec_cmd("discord"))
hl.bind(mod .. " + SHIFT + s", hl.dsp.exec_cmd("spotify"))

-- - Focus movement: hjkl + arrow keys -
local focusKeys = {
    { "h", "left" },  { "j", "down" },  { "k", "up" },    { "l", "right" },
    { "left", "left" }, { "down", "down" }, { "up", "up" }, { "right", "right" },
}

for _, k in ipairs(focusKeys) do
    hl.bind(mod .. " + " .. k[1], hl.dsp.focus({ direction = k[2] }))
end

-- - Move windows: Shift+hjkl + Shift+arrows -
for _, k in ipairs(focusKeys) do
    hl.bind(mod .. " + SHIFT + " .. k[1], hl.dsp.window.move({ direction = k[2] }))
end

-- - Split direction -
hl.bind(mod .. " + c", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + v", hl.dsp.layout("togglesplit"))

-- - Fullscreen -
hl.bind(mod .. " + f", hl.dsp.window.fullscreen())

-- - Layout switching -
--   i3 has stacking/tabbed/split modes; Hyprland doesn't have direct equivalents.
--   mod+s / mod+w are left unbound — add your own if needed.
--   mod+e toggles the dwindle split as a rough analog to "toggle split" layout.
hl.bind(mod .. " + e", hl.dsp.layout("togglesplit"))

-- - Float toggle (i3: mod+Shift+space) -
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))

-- - Focus toggle float/tile (i3: mod+space) -
--   Hyprland has no direct equivalent. This cycles focus among all windows instead.
hl.bind(mod .. " + space", hl.dsp.window.cycle_next())

-- - Floating window drag (i3: floating_modifier mod) -
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- mod + left click drag
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- mod + right click drag

-- - Screenshots (grim + slurp + wl-copy) -
hl.bind(mod .. " + SHIFT + p",        hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind(mod .. " + CTRL + SHIFT + p", hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png'))

-- - Audio -
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"))

-- - Audio device switching -
hl.bind(mod .. " + m", hl.dsp.exec_cmd("pactl set-default-sink alsa_output.usb-EDIFIER_EDIFIER_G2000_EDI00000X07-01.analog-stereo"))
hl.bind(mod .. " + n", hl.dsp.exec_cmd("pactl set-default-sink alsa_output.pci-0000_13_00.6.analog-stereo"))

-- - Reload / exit -
--   Hyprland auto-reloads when the config file changes; explicit reload still works.
hl.bind(mod .. " + SHIFT + c", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + r", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + x",         hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + e", hl.dsp.exit())

-- - Workspace switching (mod+1..0) and moving windows (mod+Shift+1..0) -
local workspaces = {
    { "1", "name:work" },
    { "2", "name:reference" },
    { "3", "name:background" },
    { "4", "4" }, { "5", "5" }, { "6", "6" }, { "7", "7" },
    { "8", "8" }, { "9", "9" }, { "0", "10" },
}

for _, w in ipairs(workspaces) do
    hl.bind(mod .. " + " .. w[1],             hl.dsp.focus({ workspace = w[2] }))
    hl.bind(mod .. " + SHIFT + " .. w[1],     hl.dsp.window.move({ workspace = w[2] }))
end

--------------------------------------------------------------------------------
--  RESIZE SUBMAP
--  NOTE: resize deltas require relative = true. Without it, x/y are treated as
--  an absolute target size and a negative value is rejected.
--------------------------------------------------------------------------------

hl.bind(mod .. " + r", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    local function resizeBy(x, y)
        return hl.dsp.window.resize({ x = x, y = y, relative = true })
    end

    -- hjkl resize (matches the old resize.conf)
    hl.bind("j",         resizeBy(-10, 0), { repeating = true })
    hl.bind("k",         resizeBy(0, 10),  { repeating = true })
    hl.bind("l",         resizeBy(0, -10), { repeating = true })
    hl.bind("semicolon", resizeBy(10, 0),  { repeating = true })

    -- Arrow key resize
    hl.bind("left",  resizeBy(-10, 0), { repeating = true })
    hl.bind("down",  resizeBy(0, 10),  { repeating = true })
    hl.bind("up",    resizeBy(0, -10), { repeating = true })
    hl.bind("right", resizeBy(10, 0),  { repeating = true })

    -- Exit resize mode
    hl.bind("return",      hl.dsp.submap("reset"))
    hl.bind("escape",      hl.dsp.submap("reset"))
    hl.bind(mod .. " + r", hl.dsp.submap("reset"))
end)
