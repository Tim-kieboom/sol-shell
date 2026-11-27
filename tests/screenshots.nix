# Screenshots for the README, taken in the same VM as the test (tests/machine.nix), so
# nothing personal is on screen:
#
#     nix build .#screenshots -L
#     ls result/
#
# The machine has no network, so the weather says where to put its location file, and no
# audio, Wi-Fi or Bluetooth hardware, so those popups are mostly empty. The pointer is
# placed with `hyprctl dispatch movecursor` (Hyprland's classic .conf mode, which the VM
# runs) and clicked with ydotool.
#
# The clicks are at fixed places (the machine's screen is always 1280x800): on the bar, and in the
# settings window, which sits in the middle of the screen (596x560, so it spans x 342 to 938 and
# y 120 to 680). When the bar or the settings change, these places move: take the pictures once,
# look where things are, and fix the numbers. In the settings, the sidebar tabs are at x 420, and a
# tab always opens with the page reset to Appearance (the page is built again each time it opens).
#
# The bar style and the layout are changed with `sol-shell ipc call barstyle use ...` and `barlayout apply ...`
# (not by clicking the chips in the Layout tab, which move with the editor), and a layout file is undone by
# deleting it. `check` prints "CHECK FAILED" and goes on, so a wrong place costs one picture, not the run.
#
# The first pictures are of the minimal bar. Then the script picks the islands style and the
# compact bar in the settings, and the notifications (the README's first picture) are shown on
# that bar. Before the theme pictures it goes back to the minimal bar.
{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "sol-shell-screenshots";

  nodes.machine = { pkgs, ... }:
    let
      # The weather comes from api.open-meteo.com, and the test machine has no internet.
      # So the machine answers for that name itself: /etc/hosts points it at a small
      # HTTPS server below, with a made-up forecast that starts today, and a certificate
      # for that name which the machine trusts. The shell is not changed for this.
      certificate = pkgs.runCommand "fake-open-meteo-certificate" { nativeBuildInputs = [ pkgs.openssl ]; } ''
        mkdir $out
        openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
          -keyout $out/key.pem -out $out/cert.pem -subj "/CN=api.open-meteo.com" \
          -addext "subjectAltName=DNS:api.open-meteo.com,DNS:geocoding-api.open-meteo.com" \
          -addext "basicConstraints=critical,CA:TRUE"
      '';

      fakeWeather = pkgs.writeText "fake-open-meteo.py" ''
        import datetime, http.server, json, ssl

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path.startswith("/v1/search"):
                    # the place search of the settings: two made-up answers
                    places = {"results": [
                        {"name": "Amsterdam", "latitude": 52.37403, "longitude": 4.88969, "country": "Netherlands", "admin1": "North Holland"},
                        {"name": "Amsterdam", "latitude": 42.93869, "longitude": -74.18847, "country": "United States", "admin1": "New York"},
                    ]}
                    body = json.dumps(places).encode()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)
                    return
                today = datetime.date.today()
                answer = {
                    "current": {
                        "temperature_2m": 14.2, "apparent_temperature": 12.8,
                        "relative_humidity_2m": 71, "weather_code": 2,
                        "is_day": 1, "wind_speed_10m": 14.4,
                    },
                    "daily": {
                        "time": [(today + datetime.timedelta(days=i)).isoformat() for i in range(6)],
                        "weather_code": [2, 3, 61, 80, 2, 0],
                        "temperature_2m_max": [16.4, 15.1, 13.7, 12.9, 15.6, 17.2],
                        "temperature_2m_min": [9.3, 10.2, 10.8, 8.4, 7.1, 8.0],
                        "precipitation_probability_max": [10, 35, 80, 60, 20, 5],
                    },
                }
                body = json.dumps(answer).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

        server = http.server.HTTPServer(("127.0.0.1", 443), Handler)
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain("${certificate}/cert.pem", "${certificate}/key.pem")
        server.socket = context.wrap_socket(server.socket, server_side=True)
        server.serve_forever()
      '';
    in
    {
      imports = [ (import ./machine.nix { inherit self; }) ];
  
      # the place for the weather, there before alice logs in
      systemd.tmpfiles.rules = [
        "d /home/alice/.config 0755 alice users -"
        "d /home/alice/.config/quickshell 0755 alice users -"
        # GTK3 programs (Wofi, Thunar) read the shell's generated stylesheet, as in the README
        "d /home/alice/.config/gtk-3.0 0755 alice users -"
        "L+ /home/alice/.config/gtk-3.0/gtk.css - - - - /home/alice/.local/state/theme/gtk.css"
        "f+ /home/alice/.config/quickshell/weather-location.json 0644 alice users - { \"latitude\": 52.37, \"longitude\": 4.89, \"locationName\": \"Amsterdam\" }"
      ];

      # the launcher's program, and a few entries for it to list (the machine has no applications)
      environment.systemPackages = [ pkgs.wofi ] ++ map
        (name: pkgs.makeDesktopItem {
          name = pkgs.lib.toLower name;
          desktopName = name;
          exec = "true";
          icon = "application-x-executable";
        })
        [ "Calculator" "Files" "Music" "Notes" "Terminal" "Web Browser" ];

      networking.hosts."127.0.0.1" = [ "api.open-meteo.com" "geocoding-api.open-meteo.com" ];
      security.pki.certificateFiles = [ "${certificate}/cert.pem" ];
      systemd.services.fake-open-meteo = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${fakeWeather}";
      };
    };

  testScript = ''
    import shlex

    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u alice -f quickshell", timeout=120)
    machine.sleep(8)
    signature = machine.succeed("ls /run/user/1000/hypr").strip()

    def as_alice(command):
        return machine.succeed(
            "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1"
            " DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
            " YDOTOOL_SOCKET=/run/ydotoold/socket HYPRLAND_INSTANCE_SIGNATURE=" + signature + " " + command
        )

    # a drag with the left button: press at the first place, move through a point in between, let go at the second
    def drag(x1, y1, x2, y2):
        as_alice("hyprctl dispatch movecursor %d %d" % (x1, y1))
        pause(0.5)
        as_alice("ydotool click 0x40")
        pause(0.5)
        as_alice("hyprctl dispatch movecursor %d %d" % ((x1 + x2) // 2, (y1 + y2) // 2))
        pause(0.3)
        as_alice("hyprctl dispatch movecursor %d %d" % (x2, y2))
        pause(0.5)
        as_alice("ydotool click 0x80")
        pause(1.5)

    # a check that does not stop the run (the pictures are only kept when the whole test passes)
    def check(command):
        status, output = machine.execute(
            "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1"
            " DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
            " HYPRLAND_INSTANCE_SIGNATURE=" + signature + " " + command
        )
        if status != 0:
            print("CHECK FAILED: " + command)

    def check_root(command):
        status, output = machine.execute(command)
        if status != 0:
            print("CHECK FAILED: " + command)

    def pause(seconds):
        machine.execute("sleep %s" % seconds)

    def click(x, y):
        as_alice("hyprctl dispatch movecursor %d %d" % (x, y))
        pause(0.5)
        as_alice("ydotool click 0xC0")
        pause(1.5)

    # take the picture with the pointer out of the way, in a corner
    def shot(name):
        as_alice("hyprctl dispatch movecursor 1279 799")
        pause(1)
        machine.screenshot(name)

    # the weather arrives from the fake Open-Meteo above
    machine.wait_until_succeeds(
        "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 sol-shell ipc call weather summary | grep -q feels",
        timeout=60,
    )

    # Hyprland's own banners (config format, start-hyprland) are not part of the shell
    as_alice("hyprctl dismissnotify")

    shot("01-desktop")

    # the clock, the CPU ring and the Wi-Fi icon of the minimal bar
    click(545, 15)
    shot("02-calendar")
    click(545, 15)

    click(916, 15)
    shot("03-task-manager")
    click(916, 15)

    click(1087, 15)
    shot("04-network")
    click(1087, 15)

    click(34, 15)
    shot("06-power-menu")
    click(34, 15)

    # the launcher (Wofi, in the theme's colors)
    as_alice("sol-shell ipc call launcher toggle")
    pause(3)
    shot("21-launcher")
    as_alice("sol-shell ipc call launcher toggle")
    pause(1)

    # The settings window is in the middle of the screen: a sidebar of categories on the left (tabs at
    # x 420), the chosen category on the right. It always opens on Appearance. Where the tabs are:
    tabs = {"appearance": 184, "layout": 220, "night": 256, "weather": 292, "system": 328, "about": 364}

    def settings_window(what):
        as_alice("sol-shell ipc call settings " + what)
        pause(2)

    def settings_tab(name):
        click(420, tabs[name])

    settings_window("open")
    shot("07-settings")

    # the Layout tab (the style chips, the position, the presets and the three sides of the bar)
    settings_tab("layout")
    shot("22-settings-layout")
    settings_window("close")

    # the islands bar (picked with the command; the chip in the Layout tab does the same)
    as_alice("sol-shell ipc call barstyle use islands")
    pause(2)
    shot("11-islands")
    click(520, 18)
    shot("12-islands-calendar")
    click(520, 18)

    # the compact bar is the Compact preset: one menu icon, the clock without the date
    as_alice("sol-shell ipc call barlayout apply compact")
    pause(3)
    shot("13-compact")
    click(1252, 18)
    shot("14-quick-settings")
    click(1252, 18)

    # the notifications, on the islands bar in its compact form: the README's first picture
    as_alice("notify-send -a Mail -u normal 'New message' 'Lunch tomorrow at noon?'")
    as_alice("notify-send -a Backup -u critical 'Backup failed' 'The disk is full'")
    as_alice("notify-send -a Music -u low 'Now playing' 'Vermeer, Girl with a Pearl Earring (the album)'")
    pause(2)
    shot("05-notifications")
    # the normal and low ones time out by themselves; a critical one stays until its x is clicked
    pause(8)
    click(1247, 60)

    # back to the minimal bar, which is what the theme pictures show: the layout file goes away
    as_alice("sol-shell ipc call barstyle use minimal")
    machine.succeed("rm -f /home/alice/.config/quickshell/bar-layout.json")
    pause(3)
    check("sol-shell ipc call barlayout status | grep -q none")

    # The items added later: a VPN (a WireGuard interface made as root, which is all the item looks
    # at; it shows up within three seconds) and keep awake, switched on and shown. Then both are undone.
    as_alice("sol-shell ipc call barstyle enable keepAwake")
    as_alice("sol-shell ipc call keepawake on")
    machine.succeed("ip link add wg-test type wireguard && ip link set wg-test up")
    pause(5)
    check("sol-shell ipc call vpn status | grep -q wg-test")
    check("sol-shell ipc call keepawake status | grep -q on")
    shot("23-vpn-keep-awake")
    machine.succeed("ip link del wg-test")
    as_alice("sol-shell ipc call keepawake off")
    as_alice("sol-shell ipc call barstyle disable keepAwake")

    # the theme chips, on the Appearance tab (the page opens on it): (x, y) of each one. The last click
    # puts the default theme (Solliom) back, so the pictures after these are in it.
    settings_window("open")
    shot("34-settings-appearance")
    for name, x, y in [("gruvbox", 768, 227), ("nord", 552, 289), ("tokyonight", 768, 289), ("catppuccin-latte", 768, 351), ("wallpaper", 552, 413)]:
        click(x, y)
        shot("08-settings-" + name)
    click(552, 227)

    # the night light times (the places may have moved since they were measured)
    settings_tab("night")
    shot("35-night-light")
    click(904, 211)
    click(908, 246)
    click(804, 286)
    shot("16-night-light-buttons")
    click(855, 246)
    as_alice("env YDOTOOL_SOCKET=/run/ydotoold/socket ydotool key 29:1 30:1 30:0 29:0")
    as_alice("env YDOTOOL_SOCKET=/run/ydotoold/socket ydotool type 22:30")
    as_alice("env YDOTOOL_SOCKET=/run/ydotoold/socket ydotool key 28:1 28:0")
    pause(1)
    shot("17-night-light-typed")
    for line in ['"nightLightSchedule": true', '"nightLightFrom": "22:30"', '"nightLightUntil": "06:45"']:
        check_root("grep -F '" + line + "' /home/alice/.local/state/sol-shell/settings.json")
    settings_window("close")

    # The weather settings, on their own tab: search for a place, pick the first, Fahrenheit and back
    typing_keys = "env YDOTOOL_SOCKET=/run/ydotoold/socket "
    settings_window("open")
    settings_tab("weather")
    shot("36-weather-tab")
    click(710, 242)
    as_alice(typing_keys + "ydotool type Amsterdam")
    pause(3)
    shot("19-weather-search")
    click(640, 270)
    pause(2)
    shot("20-weather-chosen")
    check_root("grep -F '52.37403' /home/alice/.config/quickshell/weather-location.json")
    click(900, 280)
    check_root("grep -F '\"temperatureUnit\": \"fahrenheit\"' /home/alice/.config/quickshell/weather-location.json")
    click(848, 280)
    check_root("grep -F '\"temperatureUnit\": \"celsius\"' /home/alice/.config/quickshell/weather-location.json")
    settings_window("close")

    # Your own layout (bar-layout.json, version 2): the workspaces and the launcher in a pill, the CPU and
    # memory in the center, the clock and the weather on the right; on the minimal and the islands bar.
    layout = '{"version": 2, "left": ["power", ["launcher", "workspaces"]], "center": [["cpu", "memory"], "media"], "right": [["clock", "weather"], "volume", "wifi", "bluetooth", ["vpn", "bell", "settings"]]}'
    machine.succeed("echo " + shlex.quote(layout) + " | runuser -u alice -- tee /home/alice/.config/quickshell/bar-layout.json")
    pause(3)
    check("sol-shell ipc call barlayout status | grep -q 'in use'")
    shot("24-layout-minimal")
    as_alice("sol-shell ipc call barstyle use islands")
    pause(2)
    shot("25-layout-islands")
    as_alice("sol-shell ipc call barstyle use minimal")

    # the dropdown, and a position: the Dashboard preset on the bottom of the screen
    as_alice("sol-shell ipc call barlayout apply dashboard")
    as_alice("sol-shell ipc call barstyle place bottom")
    pause(3)
    shot("26-dashboard-bottom")
    as_alice("sol-shell ipc call barstyle place top")

    # The layout editor: with a layout the editor shows the three sides (pills, the dropdown, the Hidden box)
    settings_window("open")
    settings_tab("layout")
    shot("27-layout-editor")
    settings_window("close")
    machine.succeed("rm -f /home/alice/.config/quickshell/bar-layout.json")
    pause(3)
    check("sol-shell ipc call barlayout status | grep -q none")

    # the wallpaper picker, and the circle: the next wallpaper, a moment into the change
    as_alice("sol-shell ipc call wallpaper pick")
    pause(2)
    shot("37-wallpaper-picker")
    as_alice("sol-shell ipc call wallpaper pick")

    # the lock screen, with some dots typed, then opened again
    typing = "env YDOTOOL_SOCKET=/run/ydotoold/socket "
    as_alice("sol-shell ipc call lock lock")
    pause(4)
    shot("09-lock-screen")
    as_alice(typing + "ydotool type hunter2")
    pause(1)
    shot("10-lock-typing")
    as_alice(typing + "ydotool key 1:1 1:0")
    as_alice(typing + "ydotool type sol-shell-test-password")
    as_alice(typing + "ydotool key 28:1 28:0")
    pause(3)
  '';
}
