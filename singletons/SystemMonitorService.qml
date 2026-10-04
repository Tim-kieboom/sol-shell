pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The numbers behind the task manager popup: what htop and btop show. CPU use per
// thread, temperature, load, uptime, memory in detail, and the busiest programs.
//
// Everything comes from /proc (and /sys for the temperature), the same place htop
// reads it. It is only read while a task manager popup is open (see viewerCount),
// so it costs nothing the rest of the time. SystemStats is the separate, always
// running service that feeds the two rings in the bar.
Singleton {
    id: root

    // How many task manager popups are open (one per monitor, so a count and not a
    // flag, like NetworkService's viewerCount). Nothing is read while it is 0.
    property int viewerCount: 0
    readonly property bool active: viewerCount > 0

    // how many programs the lists show
    readonly property int listSize: 6

    // ------------------------------------------------------------------ CPU

    property string cpuModel: ""
    // how many threads the processor has (read once at startup, so the thread grid
    // can be laid out at its full size before the first reading arrives)
    property int cpuThreads: 0
    // use of all threads together, 0.0 to 1.0
    property real cpuTotal: 0
    // use of each thread, 0.0 to 1.0, in thread order
    property var cores: []
    // degrees Celsius, or -1 when this machine has no sensor we know of
    property real cpuTempC: -1
    // load average over 1, 5 and 15 minutes
    property var loadAverage: [0, 0, 0]
    property real uptimeSeconds: 0
    property int processCount: 0
    property int threadCount: 0

    // ------------------------------------------------------------------ memory

    property real memTotalKiB: 0
    property real memAvailableKiB: 0
    property real memFreeKiB: 0
    property real memCachedKiB: 0
    property real swapTotalKiB: 0
    property real swapFreeKiB: 0

    readonly property real memUsedKiB: Math.max(0, memTotalKiB - memAvailableKiB)
    readonly property real memUsedFraction: memTotalKiB > 0 ? memUsedKiB / memTotalKiB : 0
    readonly property real swapUsedKiB: Math.max(0, swapTotalKiB - swapFreeKiB)
    readonly property real swapUsedFraction: swapTotalKiB > 0 ? swapUsedKiB / swapTotalKiB : 0

    // ------------------------------------------------------------------ GPUs

    // Every graphics card, NVIDIA ones first, then AMD. Each:
    //   { name, util (0.0 to 1.0), vramUsedKiB, vramTotalKiB, tempC, powerW }
    // tempC and powerW are -1 when the card does not report them. NVIDIA and AMD
    // expose their numbers in completely different ways (nvidia-smi, and files
    // under /sys), so each is read its own way below and the two lists joined here.
    readonly property var gpus: _nvidia.concat(_amd)
    property var _nvidia: []
    property var _amd: []

    // ------------------------------------------------------------- programs

    // The busiest programs, grouped by name (a browser is dozens of processes but
    // one line here). Each: { name, count, cpu, rssKiB }. cpu is in percent where
    // 100 is one whole thread, so a program using four threads shows 400, like htop.
    property var topByCpu: []
    property var topByMemory: []

    // ----------------------------------------------------- formatting helpers

    // 8923456 (KiB) -> "8.5 GiB"; 523000 -> "511 MiB"
    function formatKiB(kib: real): string {
        if (kib >= 1048576)
            return (kib / 1048576).toFixed(1) + " GiB";
        return Math.round(kib / 1024) + " MiB";
    }

    // 0.0066 (a fraction) -> "0.7%"; 0.21 -> "21%". One decimal below 10%, where a
    // whole number would hide the difference between a program at 1% and at 0.2%.
    function formatPercent(fraction: real): string {
        const percent = fraction * 100;
        return (percent < 10 ? percent.toFixed(1) : Math.round(percent)) + "%";
    }

    // 27987 (seconds) -> "7h 46m"; 90000 -> "1d 1h"
    function formatUptime(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor((minutes % 1440) / 60);
        if (days > 0)
            return days + "d " + hours + "h";
        if (hours > 0)
            return hours + "h " + (minutes % 60) + "m";
        return minutes + "m";
    }

    // ------------------------------------------------------------- polling

    // Reading starts when the first popup opens. The CPU figures are DIFFERENCES
    // between two readings, so the old readings are thrown away on every start:
    // otherwise the first number would be an average since the last time it ran.
    onActiveChanged: {
        if (active) {
            _prevCores = [];
            _prevProcesses = ({});
            _prevProcessTime = 0;
            refresh();
        }
    }

    function refresh(): void {
        statFile.reload();
        loadFile.reload();
        uptimeFile.reload();
        memoryFile.reload();
        tempFile.reload();
        if (!processReader.running)
            processReader.running = true;
        if (!nvidiaReader.running)
            nvidiaReader.running = true;
        if (!amdReader.running)
            amdReader.running = true;
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    // ---------------------------------------------------------- reading files
    // `loaded` fires each time a file has been (re)read. Each handler ignores the
    // reading when nothing is open: FileView also reads once by itself at startup.

    // Per-thread ticks. "cpu0 user nice system idle iowait irq softirq steal ..."
    // is one line per thread; the line without a number is the total.
    property var _prevCores: []

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            if (!root.active)
                return;
            const lines = text().split("\n");
            const now = [];
            let total = null;
            for (const line of lines) {
                if (!line.startsWith("cpu"))
                    continue;
                const f = line.trim().split(/\s+/);
                const values = f.slice(1, 9).map(Number);
                const entry = {
                    idle: values[3] + values[4],              // idle + iowait
                    total: values.reduce((a, b) => a + b, 0)
                };
                if (f[0] === "cpu")
                    total = entry;
                else
                    now.push(entry);
            }
            const previous = root._prevCores;
            // previous[0] is the total, the rest are the threads
            if (previous.length === now.length + 1 && total) {
                const share = (cur, prev) => {
                    const dTotal = cur.total - prev.total;
                    return dTotal > 0 ? (dTotal - (cur.idle - prev.idle)) / dTotal : 0;
                };
                root.cpuTotal = share(total, previous[0]);
                root.cores = now.map((cur, i) => share(cur, previous[i + 1]));
            }
            root._prevCores = [total, ...now];
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: {
            if (!root.active)
                return;
            // "0.08 0.17 0.31 3/1710 108711": three averages, running/total threads
            const f = text().trim().split(/\s+/);
            root.loadAverage = [Number(f[0]), Number(f[1]), Number(f[2])];
            root.threadCount = Number(f[3].split("/")[1]);
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            if (root.active)
                root.uptimeSeconds = Number(text().split(" ")[0]);
        }
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: {
            if (!root.active)
                return;
            const value = name => {
                const m = text().match(new RegExp("^" + name + ":\\s+(\\d+)", "m"));
                return m ? Number(m[1]) : 0;
            };
            root.memTotalKiB = value("MemTotal");
            root.memAvailableKiB = value("MemAvailable");
            root.memFreeKiB = value("MemFree");
            root.memCachedKiB = value("Cached") + value("Buffers");
            root.swapTotalKiB = value("SwapTotal");
            root.swapFreeKiB = value("SwapFree");
        }
    }

    // The model name never changes, so it is read once
    FileView {
        path: "/proc/cpuinfo"
        onLoaded: {
            const m = text().match(/^model name\s*:\s*(.+)$/m);
            if (m)
                // "AMD Ryzen 9 7950X 16-Core Processor" -> "AMD Ryzen 9 7950X": the core
                // count is already shown by the thread grid, and it is how the chip is named
                root.cpuModel = m[1].trim().replace(/\s+\d+-Core Processor$/, "").replace(/\s+Processor$/, "");
            // one "processor : N" line per thread
            root.cpuThreads = (text().match(/^processor\s*:/mg) ?? []).length;
        }
    }

    // ----------------------------------------------------------- temperature

    // Which of the sensors under /sys/class/hwmon is the processor depends on the
    // machine and can change between boots (hwmon3 today, hwmon5 tomorrow), so
    // look it up by name: k10temp (AMD), coretemp (Intel), zenpower, cpu_thermal.
    property string _tempPath: ""

    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case \"$(cat \"$h/name\" 2>/dev/null)\" in k10temp|coretemp|zenpower|cpu_thermal) echo \"$h/temp1_input\"; break;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: root._tempPath = text.trim()
        }
    }

    FileView {
        id: tempFile
        // no path (and no complaints) when there is no known sensor
        path: root._tempPath
        printErrors: false
        onLoaded: {
            // the file holds thousandths of a degree: 49000 is 49 C
            if (root.active)
                root.cpuTempC = Number(text().trim()) / 1000;
        }
    }

    // ------------------------------------------------------------------- GPUs

    // NVIDIA: one call to nvidia-smi (about 40 ms) per second reports every card.
    // The `command -v` first means a machine without the NVIDIA tools simply gets
    // no output, instead of an error about a program that does not exist.
    Process {
        id: nvidiaReader
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: root._parseNvidia(text)
        }
    }

    // A line looks like "NVIDIA GeForce RTX 3090, 11, 2345, 24576, 48, 47.60"
    // (memory in MiB). A value a card cannot report arrives as "[N/A]", which is
    // not a number, so it becomes -1 ("unknown") or 0.
    function _parseNvidia(output: string): void {
        if (!active)
            return;
        const number = (text, fallback) => {
            const value = Number(text);
            return isNaN(value) ? fallback : value;
        };
        const cards = [];
        for (const line of output.split("\n")) {
            const f = line.split(",").map(part => part.trim());
            if (f.length < 6)
                continue;
            cards.push({
                name: f[0].replace(/^NVIDIA\s+/, ""),
                util: number(f[1], 0) / 100,
                vramUsedKiB: number(f[2], 0) * 1024,
                vramTotalKiB: number(f[3], 0) * 1024,
                tempC: number(f[4], -1),
                powerW: number(f[5], -1)
            });
        }
        // Two identical cards would look the same: number them ("GeForce RTX 3090 #0")
        const total = {};
        for (const card of cards)
            total[card.name] = (total[card.name] ?? 0) + 1;
        const next = {};
        for (const card of cards) {
            if (total[card.name] > 1) {
                const index = next[card.name] ?? 0;
                next[card.name] = index + 1;
                card.name += " #" + index;
            }
        }
        _nvidia = cards;
    }

    // AMD: the numbers are plain files under /sys/class/drm/cardN/device. Vendor
    // 0x1002 is AMD. The name is not in those files, but lspci knows it; it never
    // changes, so it is looked up once. Output: "card2|Raphael|536870912".
    property var _amdInfo: ({})

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/drm/card?/device; do [ \"$(cat \"$d/vendor\" 2>/dev/null)\" = 0x1002 ] || continue; card=$(basename \"$(dirname \"$d\")\"); slot=$(basename \"$(readlink -f \"$d\")\"); name=$(lspci -s \"${slot#0000:}\" -mm 2>/dev/null | awk -F'\"' '{print $6}'); echo \"$card|$name|$(cat \"$d/mem_info_vram_total\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const info = {};
                for (const line of text.split("\n")) {
                    const f = line.split("|");
                    if (f.length >= 3)
                        info[f[0]] = { name: f[1], vramTotalKiB: Number(f[2]) / 1024 };
                }
                root._amdInfo = info;
            }
        }
    }

    // Every second: for each AMD card "card2|busy percent|vram used in bytes|temp in
    // thousandths of a degree".
    Process {
        id: amdReader
        command: ["sh", "-c", "for d in /sys/class/drm/card?/device; do [ \"$(cat \"$d/vendor\" 2>/dev/null)\" = 0x1002 ] || continue; card=$(basename \"$(dirname \"$d\")\"); echo \"$card|$(cat \"$d/gpu_busy_percent\" 2>/dev/null)|$(cat \"$d/mem_info_vram_used\" 2>/dev/null)|$(cat \"$d\"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root._parseAmd(text)
        }
    }

    function _parseAmd(output: string): void {
        if (!active)
            return;
        const cards = [];
        for (const line of output.split("\n")) {
            const f = line.split("|");
            if (f.length < 4)
                continue;
            const info = _amdInfo[f[0]] ?? { name: "", vramTotalKiB: 0 };
            // a card with under 1 GiB of its own memory is the one built into the
            // processor, which shares the computer's memory
            const integrated = info.vramTotalKiB > 0 && info.vramTotalKiB < 1048576;
            cards.push({
                name: "AMD " + (info.name !== "" ? info.name : "Radeon") + (integrated ? " (integrated)" : ""),
                util: (Number(f[1]) || 0) / 100,
                vramUsedKiB: (Number(f[2]) || 0) / 1024,
                vramTotalKiB: info.vramTotalKiB,
                tempC: f[3] !== "" ? Number(f[3]) / 1000 : -1,
                powerW: -1
            });
        }
        _amd = cards;
    }

    // -------------------------------------------------------------- programs

    // The cumulative CPU time of each process from the previous reading, by pid.
    // Use over the last second = how much that grew.
    property var _prevProcesses: ({})
    property double _prevProcessTime: 0

    // Every /proc/<pid>/stat in one go: about 100 KB and 10 ms for 500 processes.
    // (A shell is needed for the * to be expanded into the list of files.)
    Process {
        id: processReader
        command: ["sh", "-c", "cat /proc/[0-9]*/stat 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root._parseProcesses(text)
        }
    }

    // Nix starts many programs through a wrapper, so the kernel knows them as
    // ".quickshell-wrapped", cut to 15 characters: ".quickshell-wra". Show
    // "quickshell" instead (and so the wrapper and the program are one group).
    // Only names that start with a dot are touched.
    function _displayName(raw: string): string {
        if (!raw.startsWith("."))
            return raw;
        return raw.slice(1).replace(/-w(r(a(p(p(e(d)?)?)?)?)?)?$/, "");
    }

    // A line looks like:  1234 (firefox) S 1 ... (52 fields)
    // The name is in parentheses and may itself contain spaces and parentheses, so
    // it is cut out between the FIRST "(" and the LAST ")". After that, field 14 is
    // user time and 15 system time (both in 1/100 s), 24 the memory in pages.
    function _parseProcesses(output: string): void {
        if (!active)
            return;
        const now = Date.now();
        const seconds = (now - _prevProcessTime) / 1000;
        const havePrevious = _prevProcessTime > 0 && seconds > 0.2;

        const current = {};
        const groups = {};
        let count = 0;

        for (const line of output.split("\n")) {
            const open = line.indexOf("(");
            const close = line.lastIndexOf(")");
            if (open < 0 || close < open)
                continue;
            const pid = line.slice(0, open - 1);
            const name = _displayName(line.slice(open + 1, close));
            // fields after the name start at number 3, so field N is at index N - 3
            const f = line.slice(close + 2).split(" ");
            const ticks = Number(f[11]) + Number(f[12]);
            const rssKiB = Number(f[21]) * 4;       // pages of 4 KiB

            current[pid] = ticks;
            count++;

            // % of one thread: ticks are 1/100 s, so ticks per second is the percent
            const before = _prevProcesses[pid];
            const cpu = havePrevious && before !== undefined ? Math.max(0, ticks - before) / seconds : 0;

            const group = groups[name] ?? (groups[name] = { name: name, count: 0, cpu: 0, rssKiB: 0 });
            group.count++;
            group.cpu += cpu;
            group.rssKiB += rssKiB;
        }

        _prevProcesses = current;
        _prevProcessTime = now;
        processCount = count;

        const all = Object.values(groups);
        if (havePrevious)
            topByCpu = all.slice().sort((a, b) => b.cpu - a.cpu).slice(0, listSize);
        topByMemory = all.slice().sort((a, b) => b.rssKiB - a.rssKiB).slice(0, listSize);
    }

    // --------------------------------------------------------------- ipc

    // A text summary for scripts and checks:
    //   qs ipc -p <path> call sysmon summary
    // (empty readings unless a task manager popup is open, see viewerCount)
    IpcHandler {
        target: "sysmon"

        function summary(): string {
            if (!root.active)
                return "inactive (open the task manager popup)";
            return [
                "cpu " + Math.round(root.cpuTotal * 100) + "% on " + root.cores.length + " threads, "
                    + (root.cpuTempC >= 0 ? root.cpuTempC.toFixed(0) + " C" : "no temperature"),
                "busiest threads: " + root.cores.map((v, i) => ({ i: i, v: v })).sort((a, b) => b.v - a.v).slice(0, 3).map(t => "cpu" + t.i + " " + Math.round(t.v * 100) + "%").join(", "),
                "load " + root.loadAverage.join(" ") + ", up " + root.formatUptime(root.uptimeSeconds)
                    + ", " + root.processCount + " processes / " + root.threadCount + " threads",
                "memory used " + root.formatKiB(root.memUsedKiB) + " of " + root.formatKiB(root.memTotalKiB)
                    + ", swap " + root.formatKiB(root.swapTotalKiB),
                "gpus: " + root.gpus.map(g => g.name + " " + Math.round(g.util * 100) + "% vram " + root.formatKiB(g.vramUsedKiB) + "/" + root.formatKiB(g.vramTotalKiB) + (g.tempC >= 0 ? " " + Math.round(g.tempC) + "C" : "") + (g.powerW >= 0 ? " " + Math.round(g.powerW) + "W" : "")).join("; "),
                "top cpu: " + root.topByCpu.slice(0, 3).map(p => p.name + " x" + p.count + " " + Math.round(p.cpu) + "%").join(", "),
                "top mem: " + root.topByMemory.slice(0, 3).map(p => p.name + " x" + p.count + " " + root.formatKiB(p.rssKiB)).join(", ")
            ].join("\n");
        }
    }
}
