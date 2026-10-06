pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The current weather for one place, from Open-Meteo (a free weather service that
// needs no account or key). The place comes from a small file you write yourself:
//
//     ~/.config/quickshell/weather-location.json
//     { "latitude": 51.9225, "longitude": 4.47917, "locationName": "Rotterdam" }
//
// The file is watched, so changing the place needs no restart. The weather is
// fetched when the place is known and then every 15 minutes. If a refresh fails
// the last values stay (see `stale`) and the next refresh tries again.
Singleton {
    id: root

    // ---------------------------------------------------------------- location

    readonly property string locationPath: Settings.homeDir + "/.config/quickshell/weather-location.json"

    readonly property real latitude: location.latitude
    readonly property real longitude: location.longitude
    readonly property string locationName: location.locationName
    // true once the file holds usable coordinates
    readonly property bool configured: Number.isFinite(latitude) && Number.isFinite(longitude)

    FileView {
        path: root.locationPath
        // reading only: nothing here ever writes to this file
        printErrors: false
        watchChanges: true
        onFileChanged: reload()

        // JsonAdapter turns the JSON keys into these properties. A key that is
        // missing from the file keeps the value given here.
        adapter: JsonAdapter {
            id: location
            property real latitude: NaN
            property real longitude: NaN
            property string locationName: ""
        }
    }

    // ----------------------------------------------------------------- weather

    // true while a request is on its way
    property bool loading: false
    // true once a request has worked at least once for the current place
    property bool available: false
    // true when the latest refresh failed, so the numbers below may be old
    property bool stale: false
    property string error: ""
    property date updated: new Date(0)

    // degrees Celsius
    property real temperature: 0
    property real feelsLike: 0
    property real high: 0
    property real low: 0

    // The days after today, tomorrow first. Each entry is
    // { date, code, high, low, rain }: rain is the chance of rain or snow in percent.
    property var forecast: []
    // how many days after today to ask for
    readonly property int forecastDays: 5
    // percent
    property real humidity: 0
    // kilometers per hour
    property real windSpeed: 0
    // WMO weather code (0 clear, 3 overcast, 61 rain, ...), -1 = unknown
    property int weatherCode: -1
    property bool isDay: true

    readonly property string condition: conditionText(weatherCode)
    readonly property string icon: conditionIcon(weatherCode, isDay)

    // a changed place means the old numbers are for somewhere else
    onLatitudeChanged: placeChanged()
    onLongitudeChanged: placeChanged()

    function placeChanged(): void {
        available = false;
        // both coordinates change one after the other; wait for the second
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: root.refresh()
    }

    function refresh(): void {
        if (!configured || loading)
            return;

        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m"
            + "&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max"
            + "&forecast_days=" + (1 + forecastDays) + "&timezone=auto";

        loading = true;
        const request = new XMLHttpRequest();
        request.timeout = 15000;
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            loading = false;
            if (request.status === 200)
                apply(request.responseText);
            else
                fail(request.status === 0 ? "no connection" : "server answered " + request.status);
        };
        request.open("GET", url);
        request.send();
    }

    function apply(text: string): void {
        try {
            const data = JSON.parse(text);
            const now = data.current;
            temperature = now.temperature_2m;
            feelsLike = now.apparent_temperature;
            humidity = now.relative_humidity_2m;
            windSpeed = now.wind_speed_10m;
            weatherCode = now.weather_code;
            isDay = now.is_day === 1;
            high = data.daily.temperature_2m_max[0];
            low = data.daily.temperature_2m_min[0];
            forecast = parseForecast(data.daily);
            updated = new Date();
            available = true;
            stale = false;
            error = "";
        } catch (e) {
            fail("unexpected answer");
        }
    }

    // The daily numbers of the answer are lists with one entry per day (today first);
    // this turns them into one object per day, leaving out today.
    function parseForecast(daily: var): var {
        const days = [];
        for (let i = 1; i < daily.time.length; i++) {
            // "2026-10-06" as a date at midnight local time. new Date("2026-10-06") would
            // mean midnight UTC, which can land on the day before.
            const [year, month, day] = daily.time[i].split("-").map(Number);
            days.push({
                date: new Date(year, month - 1, day),
                code: daily.weather_code[i],
                high: daily.temperature_2m_max[i],
                low: daily.temperature_2m_min[i],
                // the service sends null when it has no estimate
                rain: daily.precipitation_probability_max[i] ?? 0
            });
        }
        return days;
    }

    function fail(message: string): void {
        error = message;
        // keep showing the last numbers, but say they may be old
        stale = available;
    }

    // ---------------------------------------------------------------- helpers

    // "14°" for a number like 13.6
    function degrees(value: real): string {
        return Math.round(value) + "°";
    }

    function conditionText(code: int): string {
        if (code === 0)
            return "Clear sky";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 55)
            return "Drizzle";
        if (code === 56 || code === 57)
            return "Freezing drizzle";
        if (code === 61 || code === 63 || code === 65)
            return code === 61 ? "Light rain" : (code === 63 ? "Rain" : "Heavy rain");
        if (code === 66 || code === 67)
            return "Freezing rain";
        if (code >= 71 && code <= 75)
            return code === 71 ? "Light snow" : (code === 73 ? "Snow" : "Heavy snow");
        if (code === 77)
            return "Snow grains";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code === 85 || code === 86)
            return "Snow showers";
        if (code === 95)
            return "Thunderstorm";
        if (code === 96 || code === 99)
            return "Thunderstorm with hail";
        return "Unknown";
    }

    // the glyph for a weather code; at night the sun is replaced by the moon
    // (clear and partly cloudy skies are the only ones whose glyph has a sun in it)
    function conditionIcon(code: int, day: bool): string {
        if (code === 0 || code === 1)
            return day ? Icons.weatherSunny : Icons.weatherNight;
        if (code === 2)
            return day ? Icons.weatherPartlyCloudy : Icons.weatherNightPartlyCloudy;
        if (code === 3)
            return Icons.weatherCloudy;
        if (code === 45 || code === 48)
            return Icons.weatherFog;
        if (code >= 51 && code <= 57)
            return Icons.weatherRainy;
        if (code >= 61 && code <= 67)
            return Icons.weatherRainy;
        if (code >= 71 && code <= 77)
            return Icons.weatherSnowy;
        if (code >= 80 && code <= 82)
            return Icons.weatherPouring;
        if (code === 85 || code === 86)
            return Icons.weatherSnowyHeavy;
        if (code >= 95)
            return Icons.weatherLightningRainy;
        return Icons.temperature;
    }

    // ------------------------------------------------------------- ipc control

    // Look at it from outside the shell:
    //   sol-shell ipc call weather summary
    IpcHandler {
        target: "weather"

        function summary(): string {
            if (!root.configured)
                return "not configured: " + root.locationPath;
            return root.locationName + " (" + root.latitude + ", " + root.longitude + ")\n"
                + (root.available
                    ? root.degrees(root.temperature) + " (feels " + root.degrees(root.feelsLike) + "), "
                        + root.condition + ", high " + root.degrees(root.high) + " low " + root.degrees(root.low)
                        + ", humidity " + root.humidity + "%, wind " + root.windSpeed + " km/h"
                        + "\n" + root.forecast.map(d => Qt.formatDate(d.date, "ddd d MMM") + ": " + root.conditionText(d.code) + " " + root.degrees(d.high) + "/" + root.degrees(d.low) + ", rain " + d.rain + "%").join("\n")
                        + (root.stale ? " [STALE: " + root.error + "]" : "")
                    : "no data yet" + (root.error ? " (" + root.error + ")" : ""));
        }

        function refresh(): void {
            root.refresh();
        }
    }
}
