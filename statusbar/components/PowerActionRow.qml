import "../../singletons"

// One line in the power menu. `action` is one entry of PowerService.actions.
ListRow {
    id: root

    required property var action

    // Dangerous actions (shut down, ...) need a second click. Harmless entries,
    // like "Settings", turn this off and just emit `activated` on the first click.
    property bool needsConfirm: true
    signal activated

    // true after the first click, while we wait for the confirming second click
    readonly property bool armed: needsConfirm && PowerService.pendingId === root.action.id

    // the power menu is a little roomier than the lists
    implicitHeight: 40
    iconSize: Fonts.titleMedium
    titleSize: Fonts.bodyMedium
    sideMargin: 10
    gap: 12

    icon: action.icon
    title: action.label

    // Armed rows turn red-ish and say so, so it is obvious something is about
    // to happen.
    iconColor: armed ? Theme.danger : Theme.accent
    subtitle: armed ? "Click again to confirm" : ""
    subtitleColor: Theme.danger
    highlighted: armed
    highlightColor: armed ? Theme.withOpacity(Theme.danger, 0.2) : Theme.nonAccent

    onClicked: {
        if (needsConfirm)
            PowerService.activate(action);
        else
            activated();
    }
}
