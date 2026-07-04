# Assetto Corsa + Content Manager + CSP + Pure on NixOS

> NOTE: This is claude-drafted with light edits for correctness. Don't take this as gospel, it probably messed up somewhere. 

A working-configuration runbook for running Assetto Corsa with Content Manager,
Custom Shaders Patch, and Pure under NixOS / Proton based on the `morpheus` host's config.

Much of this lives **outside** the Nix config — in the Wine prefix, in Content
Manager's own settings, and in Steam's per-game config — because it's inherently
imperative. This document records the sequence and the specific versions that
work, since a lot of it was won by trial and error and is easy to lose on a
prefix wipe.

**TL;DR**
- AC runs on **Valve Proton 9.0-4**, *not* GE-Proton. CSP's process injection
  breaks on GE-Proton11 (wine-staging 11.0).
- Content Manager runs via an **exe-swap** (it replaces `AssettoCorsa.exe`).
- **Pure must be installed by hand** (copy folders into the AC root). Dragging
  its zip into CM misplaces its Lua config and it silently won't run.
- CSP + Proton is **version-sensitive**. If the game "fails to patch" with
  missing-symbol errors, it's the CSP×Proton pairing, not your AC version.

---

## Key paths
note these paths assume you have `morpheus` set up exactly as this config states & AC is installed on `WOPR` (high-speed non-root drive). Adjust for your own needs.

| Thing | Path |
|---|---|
| AC install | `~/WOPR/SteamLibrary/steamapps/common/assettocorsa/` |
| Wine prefix | `~/WOPR/SteamLibrary/steamapps/compatdata/244210/pfx/` |
| Prefix Fonts dir | `.../pfx/drive_c/windows/Fonts/` |
| AC config (video.ini etc.) | `.../pfx/drive_c/users/steamuser/Documents/Assetto Corsa/cfg/` |
| Steam compat tools | `~/.steam/root/compatibilitytools.d/` |
| Steam AppID | `244210` |

`Z:` inside Wine maps to your Linux `/`. When a CM dialog asks for the AC root,
give it `Z:\home\transsonicgirl\WOPR\SteamLibrary\steamapps\common\assettocorsa`.

---

## 1. Proton

**Use Valve Proton 9.0-4 for AC** (set in Steam → AC → Properties →
Compatibility → force specific tool).

- GE-Proton11-1 launches CM fine but **CSP injection fails** ("Failed to patch
  Assetto Corsa: Can't find INIReader::cache … and N more"). This is a
  wine-staging 11.0 incompatibility with CSP's hooking, not a real AC-version
  problem.
- Older GE builds (9-27) **won't launch CM** on this system, even though protonDB users report it working. 
- Valve Proton 9.0-4 is the best version we found.

### The nix GE-Proton declarative setup (kept for reference / other games)

`programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ]` **does not work**
here: the default output of `proton-ge-bin` is a 112-byte text file, not the
compat-tool directory, so Steam never sees a usable tool. Two fixes were needed:

1. Reference the **`.steamcompattool` output** explicitly, not the default one.
2. Symlink it into `compatibilitytools.d/` via an activation script, because the
   `STEAM_EXTRA_COMPAT_TOOLS_PATHS` env var doesn't propagate into the bwrap'd
   Steam process reliably (upstream nixpkgs bug).

This is probably a temporary nixpkgs bug, but at time of writing (4 Jul 2026) this was the best way to get it working. 

```nix
home.activation.linkProtonGE = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run mkdir -p "$HOME/.steam/root/compatibilitytools.d"
  run ln -sfn "${pkgs.proton-ge-bin.steamcompattool}" \
    "$HOME/.steam/root/compatibilitytools.d/GE-Proton-nix"
'';
```

> Do **not** revert to `extraCompatPackages = [ pkgs.proton-ge-bin ]` — it points at
> the wrong output and silently does nothing. The activation symlink above is the
> working mechanism. For now, it's harmless to leave this in, and hopefully the nixpkgs 
> version gets fixed soon.

---

## 2. Launch options

Set in Steam → AC → Properties:

```
PROTON_ENABLE_WAYLAND=0 WINEDLLOVERRIDES="dwrite=n,b" %command%
```

- `PROTON_ENABLE_WAYLAND=0` — forces XWayland; native-Wayland Proton created an
  invisible / mis-sized window on Hyprland.
- `WINEDLLOVERRIDES="dwrite=n,b"` — both a font-rendering fix and the path CSP's
  dwrite-based injection loads through.
- Prepend `PROTON_LOG=1` temporarily to write `~/steam-244210.log` for debugging.

---

## 3. Content Manager (exe-swap)

CM runs as a Windows app by taking over the launcher's filename:

```fish
cd ~/WOPR/SteamLibrary/steamapps/common/assettocorsa
mv AssettoCorsa.exe AssettoCorsa_original.exe
cp "Content Manager.exe" "Content Manager Safe.exe"   # " Safe" disables CEF HW accel
cp "Content Manager Safe.exe" AssettoCorsa.exe        # what Steam launches
```

- The `" Safe"` suffix disables CEF hardware acceleration → fixes black
  windows/tooltips under Wine.
- In CM: **Settings → Content Manager → Appearance → "Disable windows
  transparency"** fixes black dropdowns/tooltips.

> **Steam "Verify integrity" will undo the exe-swap** — it restores the stock
> `AssettoCorsa.exe`. Re-do the swap afterward if you ever verify.

---

## 4. Prefix setup (fonts + .NET)

The AC stock launcher is .NET; if you ever use it (rather than the CM exe-swap)
it needs .NET installed, which chokes on Proton's symlinked prefix until
"dereferenced". Since we launch CM directly, this usually isn't needed — CM
running proves .NET is fine. Recorded here only in case of a stock-launcher path.

**Fonts CSP needs** (do this against the Proton 9.0 wine, with AC fully closed):

```fish
set -x WINEPREFIX $HOME/WOPR/SteamLibrary/steamapps/compatdata/244210/pfx
set -x WINE ~/WOPR/SteamLibrary/steamapps/common/"Proton 9.0 (Beta)"/files/bin/wine
set -x WINESERVER (dirname $WINE)/wineserver
set -x PATH (dirname $WINE) $PATH
steam-run winetricks -f corefonts allfonts
```

- `allfonts` covers most of what CSP wants, **except Segoe UI** (MS doesn't
  redistribute it — winetricks can't fetch it).
- **Segoe UI** must be copied in manually. This is automated declaratively via an
  activation symlink (see the flake); the font files live in `home/assets/fonts/`
  and get linked into the prefix Fonts dir. If the prefix is wiped, run a rebuild
  (or `home-manager` activation) to re-link.

---

## 5. Custom Shaders Patch

- Install via CM → Settings → CSP → About & Updates, or manually by extracting
  `lights-patch-*.zip` into the AC root (`7z x lights-patch-*.zip -o.`).
- If CM's in-app downloader silently fails, install manually from the zip.
- **If the game "fails to patch" (missing symbols):** it's the CSP×Proton
  pairing. Don't chase AC version / pdb / 32-bit toggle — those check out.
  The fix was **Valve Proton 9.0-4** (see §1).
- CSP config lives in `extension/config/`. A healthy install has many files
  there, not just `cars/` and `tracks/` subfolders. If it's near-empty, the
  config package didn't install — do a clean CSP reinstall.

---

## 6. Pure (weather/graphics)

**Install by hand — do NOT drag the zip into CM** (CM misplaces Pure's Lua config
and it silently won't run).

1. Download the high-res Pure zip from Peter Boese's Patreon.
2. Extract. Note the nesting: `Pure X.YZ Highres/Pure X.YZ/` contains the actual
   payload (`apps`, `content`, `extension`, `system` + a couple loose files).
   Pure's apps live under **`apps/lua/`** (PureConfig, PurePlanner, PurePP) — not
   `apps/python/`.
3. Copy the four folders (+ loose files) into the AC root, from the correct
   nested level:
   ```fish
   cd ~/Downloads/"Pure X.YZ Highres"/"Pure X.YZ"
   cp -rv apps content extension system ~/WOPR/SteamLibrary/steamapps/common/assettocorsa/
   ```
   Use a **normal `cp`, not sudo** — the AC dir is yours; sudo creates
   root-owned files the game can't read cleanly.
4. Restart CM.
5. CSP → Weather FX → weather style: **Pure LCS** (not Gamma).
6. Drive → Weather → Controllers → **Pure**.
7. AC → Settings → Video → Post-processing → **Pure** (or Pure Candy).

> The Pure Config app showing "noPure" **in the menu** is normal — the weather
> script only runs inside a loaded session. Check the in-game Pure Config app
> while actually driving to confirm it's active.

---

## 7. Steering wheel (Logitech G29)

- Works out of the box for detection (host sees it, CM sees it) — no udev/driver
  work needed (verified: works flawlessly in other games on the same system).
- The only issue was **AC-specific axis binding**. Fix in CM → Settings →
  Controls:
  - Use a **fresh custom mapping**, not a G29 preset — Proton axis numbering
    differs from Windows, so presets mis-assign.
  - **Press each pedal to bind it individually** (throttle, brake, clutch).
  - Tick **invert** on any pedal that reads full-at-rest.
- Set steering rotation to 900°.

---

## 8. Display / resolution (Hyprland)

With CM set to fullscreen under settings, the game window would sometimes stretch
badly & cause issues. The fix for this is to set the game to windowed mode & follow 
the instructions below.

**Working setup:**
- A Hyprland `windowrule` scoped to the **game window only** (matching class
  *and* title) — matching just `class:^(steam_app_244210)$` is too broad and
  catches CM + its tooltips/dropdowns, fullscreening them (breaks CM UI).
- Scoping to the specific game-window title let true fullscreen work cleanly.

> **Hyprland syntax note:** `windowrulev2` is deprecated (since ~0.42, fully
> replaced ~0.53). Use unified `windowrule` with `match:` syntax:
> `windowrule = match:class <regex> title:<regex>, <effect>`.

Get the exact class/title while a session runs:
```fish
hyprctl clients | grep -iB2 -A10 '244210'
hyprctl monitors | grep -iE 'Monitor|description'
```

Fallback if fullscreen still misbehaves: set AC to borderless (`FULLSCREEN=0`)
and pin the window to exact size/position on the target monitor:
```
windowrule = match:class ^(steam_app_244210)$ title:<game-title>, monitor <name>
windowrule = match:class ^(steam_app_244210)$ title:<game-title>, size 2560 1440
```

---

## Recovery notes

- **Prefix wipe / reinstall** resets fonts, CSP, Pure, exe-swap, and controller
  binds. Re-run: exe-swap (§3), fonts (§4), CSP install (§5), Pure hand-install
  (§6), rebuild to re-link Segoe fonts, re-bind wheel (§7).
- **"Verify integrity"** clobbers the exe-swap — redo §3 after.
- **Fully quit Steam** with `steam -shutdown` (not just closing the window) when
  it needs to re-scan compat tools.
- Prefix dereferencing fixed the .NET installer earlier but is **harmful to
  CSP/AC launch** — don't dereference the prefix for this game.
