-- 10Hour · black & white minimal Hyprland (Lua)
local HOME = os.getenv("HOME")
local S = HOME .. "/10Hour/scripts/"

local white, grey, black = "rgba(ffffffff)", "rgba(333333ff)", "rgba(000000ff)"

-- monitors
hl.monitor({ output = "", mode = "1920x1080@144", position = "auto", scale = 1 })

-- look
hl.config({
    general = {
        gaps_in = 4, gaps_out = 8, border_size = 0, layout = "dwindle",
        resize_on_border = true, allow_tearing = false,
        col = { active_border = white, inactive_border = grey },
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0, inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur = { enabled = true, size = 8, passes = 3, noise = 0.02, brightness = 0.8,
                 contrast = 1.0, vibrancy = 0.1, ignore_opacity = true, new_optimizations = true },
    },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true,
             focus_on_activate = true, background_color = black },
    animations = { enabled = false },
})

-- input
hl.config({
    input = {
        kb_layout = "pt", kb_options = "caps:escape", numlock_by_default = true,
        repeat_rate = 35, repeat_delay = 300, follow_mouse = 1, sensitivity = 0,
        touchpad = { tap_to_click = true, tap_and_drag = true, disable_while_typing = true,
                     natural_scroll = true, scroll_factor = 0.8, clickfinger_behavior = true },
    },
    gestures = { workspace_swipe_distance = 300, workspace_swipe_cancel_ratio = 0.25,
                 workspace_swipe_direction_lock = true, workspace_swipe_create_new = false },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(S .. "wallpaper.sh --restore")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- window rules
for _, c in ipairs({ "pavucontrol", "nm-connection-editor", "network-manager",
                     "blueman-manager", "org.pulseaudio.pavucontrol" }) do
    hl.window_rule({ match = { class = c }, float = true, center = true, size = { 850, 560 } })
end
hl.window_rule({ match = { title = "^(Open File|Save File|Select a File|Choose Files)$" },
                 float = true, center = true, size = { 900, 620 } })
hl.window_rule({ match = { initial_title = "^(Picture-in-Picture|Picture in picture)$" },
                 float = true, pin = true, size = { 480, 270 } })
hl.window_rule({ match = { initial_title = "^scratchpad$" }, float = true, center = true,
                 workspace = "special:scratchpad silent", size = { 1000, 650 } })

-- kitty: kitty.conf sets the focused opacity; unfocused is dimmed by 0.7 on top
hl.window_rule({ match = { class = "kitty" }, opacity = "1.0 override 0.7 override 1.0 override" })

-- binds ---------------------------------------------------------
local function run(keys, cmd, desc, opts)
    opts = opts or {}; opts.description = desc
    hl.bind(keys, hl.dsp.exec_cmd(cmd), opts)
end
local function act(keys, d, desc, opts)
    opts = opts or {}; opts.description = desc
    hl.bind(keys, d, opts)
end

run("SUPER + RETURN", "kitty",         "Terminal")
run("SUPER + D",      "rofi -show drun", "Launcher")
run("SUPER + E",      "nautilus",      "File manager")
run("SUPER + B",      "firefox",       "Browser")
run("SUPER + comma",  S .. "wifi-menu.sh", "Wi-Fi menu")
run("SUPER + C", S .. "controlpanel.sh", "System menu")
run("SUPER + M", S .. "menu.sh", "Main menu")

act("SUPER + Q",     hl.dsp.window.close(), "Close window")
act("SUPER + F",     hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }), "Fullscreen")
act("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
act("SUPER + P",     hl.dsp.window.pseudo({ action = "toggle" }), "Pseudo-tiling")

for key, dir in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
    act("SUPER + " .. key, hl.dsp.focus({ direction = dir }), "Focus " .. dir)
    act("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), "Move " .. dir)
end

for i = 1, 10 do
    local key = i % 10
    act("SUPER + " .. key, hl.dsp.focus({ workspace = i }), "Workspace " .. i)
    act("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), "Send to " .. i)
end
act("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
act("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")

act("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"), "Scratchpad")
run("SUPER + CTRL + S", "kitty --title scratchpad", "Scratchpad terminal")

act("SUPER + mouse:272", hl.dsp.window.drag(),   "Drag window",   { mouse = true })
act("SUPER + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

local function osd(k, a, d, rep) run(k, S .. "osd.sh " .. a, d, { locked = true, repeating = rep or false }) end
osd("XF86AudioRaiseVolume", "vol-up", "Volume up", true)
osd("XF86AudioLowerVolume", "vol-down", "Volume down", true)
osd("XF86AudioMute", "vol-mute", "Mute")
osd("XF86MonBrightnessUp", "bri-up", "Brightness up", true)
osd("XF86MonBrightnessDown", "bri-down", "Brightness down", true)

run("XF86AudioPlay", "playerctl play-pause", "Play / pause", { locked = true })
run("XF86AudioNext", "playerctl next", "Next track", { locked = true })
run("XF86AudioPrev", "playerctl previous", "Previous track", { locked = true })

for _, k in ipairs({ "Print", "SUPER + SHIFT + S" }) do run(k, S .. "capture.sh screenshot", "Screenshot") end
run("SUPER + SHIFT + R", S .. "capture.sh record", "Screen recording")

run("SUPER + W",         S .. "wallpaper.sh --pick",   "Wallpaper picker")
run("SUPER + SHIFT + W", S .. "wallpaper.sh --random", "Random wallpaper")

run("SUPER + CTRL + L",  "hyprlock", "Lock")
run("SUPER + SHIFT + RETURN", S .. "powermenu.sh", "Power menu")
