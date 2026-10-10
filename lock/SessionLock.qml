import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

// The actual lock: asks the compositor to cover every screen with the lock screen
// (LockScreen.qml) while LockService.locked is true. Place one of these in shell.qml.
//
// If the shell dies while the screen is locked, the compositor keeps it locked and shows a
// plain color (that is what makes the lock safe). See the README for how to get back in.
Scope {
    WlSessionLock {
        id: lock

        locked: LockService.locked

        LockScreen {}
    }

    Connections {
        target: lock

        // the compositor can end the lock by itself (for example when another lock program
        // takes over): then the service must not think it is still locked
        function onLockStateChanged(): void {
            if (!lock.locked && LockService.locked)
                LockService.locked = false;
        }

        function onSecureStateChanged(): void {
            LockService.secure = lock.secure;
        }
    }
}
