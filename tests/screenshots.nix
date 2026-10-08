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
          -addext "subjectAltName=DNS:api.open-meteo.com" \
          -addext "basicConstraints=critical,CA:TRUE"
      '';

      fakeWeather = pkgs.writeText "fake-open-meteo.py" ''
        import datetime, http.server, json, ssl

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
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
        "f+ /home/alice/.config/quickshell/weather-location.json 0644 alice users - { \"latitude\": 52.37, \"longitude\": 4.89, \"locationName\": \"Amsterdam\" }"
      ];

      networking.hosts."127.0.0.1" = [ "api.open-meteo.com" ];
      security.pki.certificateFiles = [ "${certificate}/cert.pem" ];
      systemd.services.fake-open-meteo = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${fakeWeather}";
      };
    };

  testScript = ''
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

    click(606, 15)
    shot("02-calendar")
    click(606, 15)

    click(1040, 15)
    shot("03-task-manager")
    click(1040, 15)

    click(1184, 15)
    shot("04-network")
    click(1184, 15)

    as_alice("notify-send -a Mail -u normal 'New message' 'Lunch tomorrow at noon?'")
    as_alice("notify-send -a Backup -u critical 'Backup failed' 'The disk is full'")
    as_alice("notify-send -a Music -u low 'Now playing' 'Vermeer, Girl with a Pearl Earring (the album)'")
    pause(2)
    shot("05-notifications")
    # the normal and low ones time out by themselves; a critical one stays until its x is clicked
    pause(8)
    click(1247, 58)

    click(34, 15)
    shot("06-power-menu")
    click(83, 57)
    shot("07-settings")

    # the theme chips in the settings page: (x, y) of each one
    for name, x, y in [("gruvbox", 284, 133), ("nord", 67, 195), ("tokyonight", 284, 195), ("catppuccin-latte", 284, 257)]:
        click(x, y)
        shot("08-settings-" + name)
  '';
}
