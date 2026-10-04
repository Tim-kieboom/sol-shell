pragma Singleton

import Quickshell
import Quickshell.Networking

Singleton {
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
        if (viewerCount === 0)
            pendingNetwork = null;
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
    // A new secured network needs a password first (a later slice).
    function needsPassword(network: var): bool {
        return !network.known && isSecured(network);
    }

    function networkStatus(network: var): string {
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
        // saves the network with this password and connects; next time it is "known"
        pendingNetwork.connectWithPsk(password);
        pendingNetwork = null;
    }

    function cancelPassword(): void {
        pendingNetwork = null;
    }

    function toggle(): void {
        if (hardwareEnabled)
            Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
