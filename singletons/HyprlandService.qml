pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var workspaces: {
        if (!Hyprland || !Hyprland.workspaces)
            return [];

        const validWorkspaces = Hyprland.workspaces.values.filter(w => w.id > 0);
        return validWorkspaces.map(w => ({
                    id: w.id,
                    screenName: w.monitor ? w.monitor.name : "",
                    isActive: w.active,
                    isFocused: w.focused
                }));
    }
}
