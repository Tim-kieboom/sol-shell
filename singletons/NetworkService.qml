pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// Wi-Fi for the bar: on/off, the list of networks, connecting (including the
// password prompt for new networks) and scanning. Only the wifi device is
// handled; wired ethernet is ignored.
Singleton {
    id: root

    // Networking.devices lists every network interface (ethernet, wifi, ...).
    // We only want the wifi one; null if the machine has none.
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool enabled: Networking.wifiEnabled
    // false when a hardware switch / airplane mode blocks wifi; toggling is pointless then
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled

    readonly property var connectedNetwork: wifiDevice
        ? (wifiDevice.networks.values.find(n => n.connected) ?? null)
        : null

    // Networks to show: no hidden ones (empty name), connected first, then
    // saved ("known") ones, then strongest signal first.
    // filter() returns a fresh array, so sorting it in place is safe.
    readonly property var networks: {
        if (!wifiDevice)
            return [];
        return wifiDevice.networks.values
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected)
                || (b.known - a.known)
                || (b.signalStrength - a.signalStrength));
    }

    // One line for the UI, so the UI doesn't need to know the rules
    readonly property string statusText: {
        if (!hardwareEnabled)
            return "Blocked";
        if (!enabled)
            return "Off";
        return connectedNetwork ? connectedNetwork.name : "Not connected";
    }

    // ---- popup viewers ----
    // How many wifi popups are open right now. There is one popup per monitor
    // and they all share this service, so a plain on/off flag would let one
    // popup closing switch off scanning (or cancel a password prompt) that
    // another popup still needs. Each popup adds one when it opens and removes
    // one when it closes; the service reacts to the total.
    property int viewerCount: 0

    // Looking for networks costs power, so we only scan while somebody is
    // looking at the list.
    readonly property bool shouldScan: viewerCount > 0 && enabled

    function applyScanning(): void {
        if (wifiDevice)
            wifiDevice.scannerEnabled = shouldScan;
    }

    onShouldScanChanged: applyScanning()
    onWifiDeviceChanged: applyScanning()
    // the last popup closing abandons any half-typed password
    onViewerCountChanged: {
        if (viewerCount === 0) {
            pendingNetwork = null;
            // the red "Wrong password" on a row only lasts while you are looking at it
            clearFailure();
        }
    }

    // ---- helpers for one network ----

    // 4 icon levels from a 0..1 signal strength
    function signalIcon(network: var): string {
        const s = network.signalStrength;
        if (s > 0.75)
            return Icons.wifiStrong;
        if (s > 0.5)
            return Icons.wifiGood;
        if (s > 0.25)
            return Icons.wifiWeak;
        return Icons.wifiNone;
    }

    // Open networks (and "Owe", which encrypts without a password) need no password
    function isSecured(network: var): bool {
        return network.security !== WifiSecurityType.Open
            && network.security !== WifiSecurityType.Owe
            && network.security !== WifiSecurityType.Unknown;
    }

    // We can only connect straight away if the network is saved or open.
    // A new secured network needs a password first (see submitPassword below).
    function needsPassword(network: var): bool {
        return !network.known && isSecured(network);
    }

    function networkStatus(network: var): string {
        // a failed attempt says so on its row (see handleFailure)
        if (isFailed(network))
            return failedText;
        if (network.state === ConnectionState.Connecting)
            return "Connecting...";
        if (network.state === ConnectionState.Disconnecting)
            return "Disconnecting...";
        if (network.connected)
            return "Connected";
        if (network.known)
            return "Saved";
        return needsPassword(network) ? "Password required" : "Open";
    }

    // The network the user is currently typing a password for, or null.
    // It lives here (not in the row) so that only one prompt can be open and
    // the popup can cancel it when it closes.
    property var pendingNetwork: null

    // A click means "flip it". For a new secured network that means "ask for the
    // password": clicking again closes the prompt.
    function toggleConnection(network: var): void {
        clearFailure();
        if (network.connected)
            network.disconnect();
        else if (needsPassword(network))
            pendingNetwork = (pendingNetwork === network) ? null : network;
        else
            network.connect();
    }

    function submitPassword(password: string): void {
        if (!pendingNetwork || password === "")
            return;
        clearFailure();
        // This saves the network with the password. If the password turns out to be wrong
        // that saved copy must go again (see handleFailure), so remember that we made it.
        createdProfiles = [...createdProfiles.filter(n => n !== pendingNetwork.name), pendingNetwork.name];
        // saves the network with this password and connects; next time it is "known"
        pendingNetwork.connectWithPsk(password);
        pendingNetwork = null;
    }

    function cancelPassword(): void {
        pendingNetwork = null;
    }

    // ---- when connecting fails ----

    // Every network object has a connectionFailed signal. One Connections per network
    // listens to it; the Instantiator makes and removes them as networks come and go.
    Instantiator {
        model: root.wifiDevice ? root.wifiDevice.networks.values : []

        delegate: Connections {
            required property var modelData

            target: modelData

            function onConnectionFailed(reason): void {
                root.handleFailure(modelData, reason);
            }
        }
    }

    // The network whose last attempt failed, and what to say about it. The row of that
    // network shows the text instead of its usual status, until the next attempt or
    // until the popup is closed.
    property string failedName: ""
    property string failedText: ""

    // Names of the networks that the shell saved from a typed password and that have
    // not connected yet. Connecting saves the network *with* the password before we
    // know it is right; a wrong one would stay saved and every click afterwards would
    // reuse it without ever asking again.
    property var createdProfiles: []

    function isFailed(network: var): bool {
        return failedName !== "" && network.name === failedName
            && network.state !== ConnectionState.Connecting && !network.connected;
    }

    function clearFailure(): void {
        failedName = "";
        failedText = "";
    }

    // A network that is connected now needs no cleanup any more
    onConnectedNetworkChanged: {
        if (!connectedNetwork)
            return;
        createdProfiles = createdProfiles.filter(n => n !== connectedNetwork.name);
        if (connectedNetwork.name === failedName)
            clearFailure();
    }

    // The words for a failure: [short title, sentence]
    function failureWords(name: string, reason: int): var {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return ["Wrong password", "The password for " + name + " was not accepted."];
        case ConnectionFailReason.WifiAuthTimeout:
            return ["Authentication timed out", name + " did not answer in time. Check the password and the signal."];
        case ConnectionFailReason.WifiClientDisconnected:
            return ["Disconnected", name + " dropped the connection."];
        case ConnectionFailReason.WifiNetworkLost:
            return ["Network lost", name + " is out of range."];
        default:
            return ["Could not connect", "Could not connect to " + name + "."];
        }
    }

    // Reasons that mean "the password is wrong" (as far as NetworkManager can tell)
    function isPasswordFailure(reason: int): bool {
        return reason === ConnectionFailReason.NoSecrets
            || reason === ConnectionFailReason.WifiAuthTimeout
            || reason === ConnectionFailReason.WifiClientFailed;
    }

    function handleFailure(network: var, reason: int): void {
        const words = failureWords(network.name, reason);
        failedName = network.name;
        failedText = words[0];
        // `key` keeps NetworkManager retrying a dead network from stacking up cards
        ShellMessages.error("Wi-Fi", words[0], words[1], "wifi:" + network.name);

        // Undo the saving of a password that did not work, so the next click asks for
        // the password again; and when the popup is open, ask right away.
        if (createdProfiles.includes(network.name) && isPasswordFailure(reason)) {
            createdProfiles = createdProfiles.filter(n => n !== network.name);
            network.forget();
            if (viewerCount > 0)
                pendingNetwork = network;
        }
    }

    function toggle(): void {
        if (hardwareEnabled)
            Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
