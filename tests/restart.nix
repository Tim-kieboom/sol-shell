# `sol-shell restart` again and again, on a machine where the shell is the only one (so it owns the
# notification server, the tray and the media watcher, which a shell run next to another one never does):
#
#     nix build .#checks.x86_64-linux.restart -L
#
# Stopping a shell used to crash it when the bar was drawn as islands (the click mask list was changed while
# the bar was being destroyed). Each restart stops the running shell, so this fails the build if any stop
# leaves a crash report, if more or fewer than one shell is running afterwards, or if the shell that comes
# up does not answer. It takes no pictures.
{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "sol-shell-restart";

  nodes.machine = import ./machine.nix { inherit self; };

  testScript = ''
    def as_alice(command):
        return machine.succeed(
            "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 " + command
        )

    def shells():
        # the sol-shell instances on this screen, one line each
        out = as_alice("quickshell list --all")
        return out.count("sol-shell/shell.qml")

    def crashes():
        return machine.succeed("ls /home/alice/.cache/quickshell/crashes 2>/dev/null || true").split()

    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u alice Hyprland", timeout=120)
    machine.wait_until_succeeds("pgrep -u alice -f quickshell", timeout=120)
    machine.sleep(10)

    # the islands bar is the one with the click mask; open the settings and use a layout, so there is more to destroy
    as_alice("sol-shell ipc call barstyle use islands")
    machine.sleep(2)
    as_alice("sol-shell ipc call settings open")
    machine.sleep(2)
    as_alice("sol-shell ipc call barlayout apply islands")
    machine.sleep(2)
    as_alice("sol-shell ipc call settings close")
    machine.sleep(2)
    assert shells() == 1, "there should be one shell to begin with, found %d" % shells()
    assert crashes() == [], "the shell crashed before the first restart: %s" % crashes()

    for round in range(1, 7):
        with subtest("restart number %d" % round):
            as_alice("sol-shell restart")
            # the new shell answers
            machine.wait_until_succeeds(
                "runuser -u alice -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1"
                " sol-shell ipc call lock locked | grep -qx false",
                timeout=60,
            )
            machine.sleep(6)
            print(as_alice("quickshell list --all"))
            assert crashes() == [], "restart %d left crash reports: %s" % (round, crashes())
            assert shells() == 1, "restart %d left %d shells running" % (round, shells())
            # work for the bar to destroy: another layout, then the settings
            as_alice("sol-shell ipc call barlayout apply " + ["minimal", "islands", "dashboard"][round % 3])
            machine.sleep(2)

    log = as_alice("sol-shell log")
    assert "ERROR" not in log, "the shell logged errors, see above"
  '';
}
