"""
Applet: Mount Vernon WX
Summary: Current conditions and a three-day outlook
Description: A dark, high-contrast two-screen weather app with a large current
condition icon, current temperature, today's high and low, humidity, wind in
knots and direction, and a three-day forecast. Weather data is provided by
Open-Meteo.
Author: Greg Worthing
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """{
    "lat": 48.4212,
    "lng": -122.3340,
    "locality": "Mount Vernon",
    "timezone": "America/Los_Angeles"
}"""

FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
FONT_TINY = "tom-thumb"
FONT_TEMP = "6x13"
FONT_FORECAST_TEMP = "tb-8"
BLACK = "#000000"
BLUE = "#00B8FF"
BLUE_GLOW = "#004D80"
OFF_WHITE = "#E8EEF2"
MUTED = "#9FAEB8"
DIVIDER = "#34434C"

# Greg's photorealistic icon set, cropped and palette-optimized specifically
# for the Tidbyt's 64x32 canvas. Separate sources keep forecast icons crisp.
CURRENT_ICONS = {
    "cloudy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAM1BMVEUAAADQ0dLLy82IiYzz8/SfoKLg4OKvr7KRkpVfYGN+foFwcXSpqatRUVScnaK9vcNxcnWsdo7BAAAAAXRSTlMAQObYZgAAAJRJREFUKM+1UUEOgzAMwySNU0IL/3/tsk1i0HHFqnqwFTtup+kJYL6lRYEiN4KRXheZRk0A9yUcikFa3SNaFJY+CMBCbbVVv0TNxuaaQErnCKaJmqmp9tOABKFqyCvPevBevswHdt4rLfjmkGYKHiMwupNb95I1/eDnrXenmUVkx+CloTCje9v3/+cS/rwH5ZHPTLwAYegEUX+31sEAAAAASUVORK5CYII=",
    "foggy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAKlBMVEUAAACZmJmysrNzc3Osq6yWlZbh4eLR0dLu7u+gn6B1dHViYmPd3N2Qj5D82+KxAAAAAXRSTlMAQObYZgAAAIZJREFUKM+9T8sOwzAIKw7gkHb//7uDalKodq8lOGDhx3G8CckBxt8d0GFw0rSTSvp0dwKwTYhaRORpFc5NXBpkmKF2tI8RPhMlxBzV7THOtVIr1Wx1bymt+QNVNvMp7wxggeh5Rd3BcomHVsa16kGwqui186ZIVsFdsVvcsSyetXs4OV7FF2ECBBPEJVN5AAAAAElFTkSuQmCC",
    "moon": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAJFBMVEX///8AAAD776UkIxjf9f//8qj+8adjXkHbz5B7dVEdGxPWy43isZI7AAAAAXRSTlMAQObYZgAAAHFJREFUKM+NkdsOwCAIQ0Gl0+3//3dzMSqCiX3sCZQL0Ym4amNbFCIbkogEF7MlBOTZ59R9FAVaiXwgeuDzwQ4I2FTUTm5G9ZepRja8Pf4MlTLWUzV331saySVyLM90QMxSp138RKab2DcFgYSjP+/0AilxA1HpkOdPAAAAAElFTkSuQmCC",
    "partly_cloudy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAV1BMVEUAAAD9rgf91ij9yy79+0j88tT39/b883P97yn77qH96hP80wn49vP8tgTe3uCgoabj39n8eADQ0NPJs5+3t7vz7fC/vsKRkpadnaFqbHJgYWZ8fYJucHYa4zQmAAAAAXRSTlMAQObYZgAAAKtJREFUKM+9j8kOgzAMRMtiQxYMmBQnlP//zpqqlKVceumTcnmjGcW32//I8ry48nkJWNXZly9qY0xl3TnJrKvL0jrw54Jz1roGkLxvD41moULoiHDfylzfA4JRz4S830L1AAMhctiSe+sRDarUhzSSrAliNwB+IH4nXvsjMXMIvCBx8ymJhChREVmXQgxqdEKmR5qmJPtvyWtEkiLz8fo5EunVJ7vQXrifeAJrIAp4yt/X1QAAAABJRU5ErkJggg==",
    "rainy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAASFBMVEUAAADNzdHHx8q+vsKwsLSQkJWfn6Te3uLDw8dNTVLr6++Kio++vsFub3NgYWZeX2R+foI8PUEzNDggISQxMjdvb3QuLzRISU5fL4hZAAAAAXRSTlMAQObYZgAAAIpJREFUKM+1j8EOgzAMQ+vOSZeWlFIY+/8/HQfGpIkTEj4+y04cwj1CPOfxQeGJF0VBTfzDT4oaM5i0HLDokCgJgpyhkIM7Mz3nBKTNIuKeKYTWrZ8uqqIyym4MbLW2yZu5u3W3b5OY2+hE69anqdffjRLG6hDWeV5e69+76+JteZ8OL+GCLoVu0AeJWQTYNGZJVgAAAABJRU5ErkJggg==",
    "sleet_rain": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAS1BMVEUAAADO0NXw8fTS1Nm6vcRJTledoaissLZZXme+wMa/wsh8gYqZnaXa3eKanaWLj5fLzdNmanPt7vF6f4dJTlZWWmNobHQ8QEgvMzoq2hxHAAAAAXRSTlMAQObYZgAAAJRJREFUKM+lj9sOgkAMRLdlLyhdKvay/P+XCglqiMQHmL6dzjTTEK4J8Jh3MUaA9MvzggtAv6O3DuA+0LqpHzhyeCAAYo6IwKV7m8OEyIRYKyxTc/4ce1bKAMQsPFARlS2BhcncmVVd1Gza/Kl3Ny9YqTXVpvKtRak3YSO3uc1p3NVNTUma8uHnaW14XXw2OJ4N/tELkioGQO2/vnYAAAAASUVORK5CYII=",
    "snow": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAQlBMVEUAAACIi5X09fjO0dbd3+Sfoqu/wsesr7e6vcScn6hpbXZwdX5LTle6vciPkpuqrbV6fodYXGU4O0MyNT1qbni4u8QYGpG1AAAAAXRSTlMAQObYZgAAALtJREFUKM+lkdtuAyEMRMGXNXYMGNL8/6+W1W6rNtm+NDyAdDzy2ENKb50MeM2Jt40wv3BkJBQs+UmOoiaITHg72U28AghCMVpvk3rw3kIAAwFIkIhQS995pCSwtdVBRBszYxt6NENoGhZu5sPXPfzgLGYxli/ZnBHTvZ3eg8e0QDH1+9KbfnyN2nP4EnJzH+ap/lqD3XS6xkUiu2OpT3Af/GQrEP5RefQ/Eq9yiR/pu02+KO/uvfz7mz8Bi3MGn8fHSk0AAAAASUVORK5CYII=",
    "storm": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAaVBMVEUAAADR0tbU2uuqr7z1+PmssLl9hZpmbYNtd5FPWG0nLDo6R2kpOGShtOFwlOdHbNB3halabKSuyvPc7f80So48dvZWh/RJWotHVHhYapw5WrgHOtMUKm0sNVMnUtkUN50KGk4VHjcWJFHeldhlAAAAAXRSTlMAQObYZgAAAKpJREFUKM/Vj8kSgjAQRJkskoRsJCFhSUT8/48Uq0AsSk+enGP3m+npqvpx4IuOEAb8iQcCFOBykjHGNaNP83C44HhlUSOVNhboi6WUEIaJarV23iu05fALJj5Ia03XOUJ8THbbqIH2Mg2jiUrHbsqFb5csyznIMLoYp+t8W5o9Qyw5JGqVm1Y93ws7XuVJDshpM69837yX4KWVrA25L+JUj3NRl36P/bt5AEq8CSEuGLZhAAAAAElFTkSuQmCC",
    "sunny": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAQlBMVEUAAAD9ngP8vg/8uhH9nQD87TD881L80An8/Gr9ZgD8/Y783DL7+rf81kX86Br9ySD8tAP9kAL8wB79bgD9VAD8sw6CxUJHAAAAAXRSTlMAQObYZgAAAJ5JREFUKM+1kckOwyAMRFnipVDAjun//2pBzQHSc+aAxDxsjY1zT8iH6OKfG8IBiMQv7zc/RgZOKWHGvWD67yGGcmx+rnUWJAbisoCGVAGZESrRGiAT1QpDwxdaOqVxnWwcotiWCpFJhi2isARup8pPqpqXmQuaXuql7XnNBjPrmjcQCqn13k14X8mcnaQQRx/uu/U+4Kfd31/wke90X4RlB0rbldE6AAAAAElFTkSuQmCC",
}

FORECAST_ICONS = {
    "cloudy": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAJFBMVEUAAACysrTS0tSKi45xcnZERUnq6uuJiYyfoKOrq6739/ff3+HvdDvfAAAAAXRSTlMAQObYZgAAAEJJREFUCNd9jUEOACEIA7F2F2z//981GrM3CQcmDdOI6zT0H8Cnv3kSFslNo0oC921prhbIEOwlyUF4vhxhtrx3xwdbQQFDpgN+SwAAAABJRU5ErkJggg==",
    "foggy": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAG1BMVEUAAACZmJmwsLHPzs+zs7OWlpd/fn+xr7Hk5OR93Kv0AAAAAXRSTlMAQObYZgAAADtJREFUCNd9jckRACAMAoOApv+KvX2a12a4Ir6HQLlcSElebE2sdZssDu0Y10NjcmNm3gw8pBReN/Af7zwOAMmFrYT+AAAAAElFTkSuQmCC",
    "moon": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAG1BMVEX///8AAAD/8ahsZ0ff9f//8qjCuIBZVTuLhFuRdGK7AAAAAXRSTlMAQObYZgAAAENJREFUCNdNjlsKwEAIAxPX1N7/xLU+YPPjhEEU6JAcssMK4NLT7ICk4Jos3GK3Sd6dNjrXTrpgvJjyp04u+3wgq/kBWhwBU0+hLZoAAAAASUVORK5CYII=",
    "partly_cloudy": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAMFBMVEUAAAD/uAL9/J/93jf9/yX81Cb8tgD19vjQz9Kur7T/tkPr4+Xz8PqrrLCLi5FnaG4QOs3mAAAAAXRSTlMAQObYZgAAAENJREFUCNeFjEkOwCAMA8OamJTw/98SaFFv7fjikSUTfRFienuOuRxJtRYWPEtT9uiWi2/Ee1eDGICxlm6iwzkfRj9Mcw0BtAXeLNUAAAAASUVORK5CYII=",
    "rainy": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAJ1BMVEUAAAC+vsKfn6POztJub3PS0tavr7P09PidnaFNTlJZWV5wcXQlJioRL61sAAAAAXRSTlMAQObYZgAAADxJREFUCNeFjUEOwCAMw1hIWujy//duTOI44ZNzsNLagQt9awclfApFKlNjjSDBwVmv32XGtL2j8unhlwdOVwDxyhrC8AAAAABJRU5ErkJggg==",
    "sleet_rain": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAMFBMVEUAAABFSlSqrra3usGLkJi5vMOytr0dIi2coKrCxczn6e1/hI5ZXmcoLTg9Qk0FCA9W0GMQAAAAAXRSTlMAQObYZgAAADxJREFUCNetijkSACAIxBA5PBD+/1tHGgtbU2UnC/BS8HolZEnT1of0we0M5MlESJZhmXhErLypm4fCBzZ5KAFThKNedwAAAABJRU5ErkJggg==",
    "snow": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAJ1BMVEUAAADT1dy5vMOVmKCsr7egpKuws7q/wsjh4+d/gopZXWYyNj48P0gShBv1AAAAAXRSTlMAQObYZgAAAEdJREFUCNdtjEsOwEAIQketP/T+562ZNF10yoK8AGGtU8Ty8qXmsSkpwjhch8XDgo05Z0kGGKob0xQamuPPRXWprD8dKX2DG396AXZsW5CFAAAAAElFTkSuQmCC",
    "storm": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAALVBMVEUAAACWm6WutcTUz84qLEDs8/VgbIxBT3ZsmPs4ZNLG3/tygagSImQAFqIQFin5pNBTAAAAAXRSTlMAQObYZgAAAEFJREFUCNedizsCwCAIxSgPEBS5/3H7cXFwaqYMCdGBa3MGsExYrTn4dahxuPYhTz0ywz1mfVVa95kl62lmWfSPG2+YAVYMGH4OAAAAAElFTkSuQmCC",
    "sunny": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAMFBMVEUAAAD+uhn/5yn//Eb/2y7/+Fz//+T/+DL/7gr//5D/3S7/zAD/tQr/jwb/XAD/cgKK9DbyAAAAAXRSTlMAQObYZgAAAEZJREFUCNd9zUEOACEIA0AEFBSQ///WXfVsb5M2KcArBYm4XFBtrcoRqvQuyhvD9IuPDQ438zhAn5EzzgzYM2/xd8j4PIcFfBIBrcLeil0AAAAASUVORK5CYII=",
}

def round_temp(value):
    return int(float(value) + (0.5 if float(value) >= 0 else -0.5))

def weather_kind(code, is_day = True):
    code = int(code)
    if code == 0:
        return "sunny" if is_day else "moon"
    if code == 1 or code == 2:
        return "partly_cloudy" if is_day else "cloudy"
    if code == 3:
        return "cloudy"
    if code == 45 or code == 48:
        return "foggy"
    if code == 56 or code == 57 or code == 66 or code == 67:
        return "sleet_rain"
    if (code >= 51 and code <= 65) or (code >= 80 and code <= 82):
        return "rainy"
    if (code >= 71 and code <= 77) or (code >= 85 and code <= 86):
        return "snow"
    if code >= 95:
        return "storm"
    return "cloudy"

def current_icon(kind):
    return render.Image(
        width = 24,
        height = 22,
        src = base64.decode(CURRENT_ICONS[kind]),
    )

def forecast_icon(kind, width = 11, height = 11):
    return render.Image(
        width = width,
        height = height,
        src = base64.decode(FORECAST_ICONS[kind]),
    )

def temperature_text(value):
    content = str(round_temp(value)) + "°"
    return render.Stack(
        children = [
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = BLUE_GLOW),
            ),
            render.Text(content = content, font = FONT_TEMP, color = BLUE),
        ],
    )

def forecast_temperature_text(value):
    content = str(round_temp(value)) + "°"
    return render.Stack(
        children = [
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLUE_GLOW),
            ),
            render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLUE),
        ],
    )

def today_temps(daily):
    high = str(round_temp(daily["temperature_2m_max"][0])) + "°"
    low = str(round_temp(daily["temperature_2m_min"][0])) + "°"
    return render.Row(
        cross_align = "center",
        children = [
            render.Text(content = high, font = FONT_TINY, color = OFF_WHITE),
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Box(width = 1, height = 6, color = DIVIDER),
            ),
            render.Text(content = low, font = FONT_TINY, color = BLUE),
        ],
    )

def wind_direction(degrees):
    directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    index = int((float(degrees) + 22.5) / 45.0) % 8
    return directions[index]

def forecast_day(daily, timezone, index, width):
    code = int(daily["weather_code"][index])
    label = time.parse_time(
        daily["time"][index],
        format = "2006-01-02",
        location = timezone,
    ).format("Mon").upper()
    return render.Box(
        width = width,
        height = 32,
        child = render.Stack(
            children = [
                render.Padding(pad = (1, 2, 0, 0), child = forecast_icon(weather_kind(code), 15, 14)),
                render.Padding(
                    pad = (8, 10, 0, 0),
                    child = forecast_temperature_text(daily["temperature_2m_max"][index]),
                ),
                render.Padding(
                    pad = (0, 26, 0, 0),
                    child = render.Box(
                        width = width,
                        height = 6,
                        child = render.Column(
                            expanded = True,
                            cross_align = "center",
                            main_align = "center",
                            children = [
                                render.Text(content = label, font = FONT_TINY, color = MUTED),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def current_screen(current, daily):
    kind = weather_kind(
        int(current["weather_code"]),
        int(current["is_day"]) == 1,
    )
    humidity = str(int(current["relative_humidity_2m"]))
    wind = str(round_temp(current["wind_speed_10m"]))
    direction = wind_direction(current["wind_direction_10m"])

    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Stack(
            children = [
                render.Padding(pad = (0, 0, 0, 0), child = current_icon(kind)),
                render.Padding(
                    pad = (17, 8, 0, 0),
                    child = temperature_text(current["temperature_2m"]),
                ),
                render.Padding(pad = (2, 25, 0, 0), child = today_temps(daily)),
                render.Padding(
                    pad = (38, 19, 0, 0),
                    child = render.Box(
                        width = 26,
                        height = 13,
                        child = render.Column(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Text(content = humidity + "%", font = FONT_TINY, color = OFF_WHITE),
                                render.Text(content = wind + "KT " + direction, font = FONT_TINY, color = OFF_WHITE),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def forecast_screen(daily, timezone):
    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Row(
            children = [
                forecast_day(daily, timezone, 1, 21),
                forecast_day(daily, timezone, 2, 21),
                forecast_day(daily, timezone, 3, 22),
            ],
        ),
    )

def error_screen():
    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Column(
            expanded = True,
            cross_align = "center",
            main_align = "center",
            children = [
                render.Text(content = "WX OFFLINE", font = "6x13", color = BLUE),
                render.Text(content = "TRYING AGAIN SOON", font = FONT_TINY, color = MUTED),
            ],
        ),
    )

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    units = config.get("units", "Fahrenheit")
    unit_parameter = "celsius" if units == "Celsius" else "fahrenheit"
    request_url = (
        FORECAST_URL +
        "?latitude=" + str(location["lat"]) +
        "&longitude=" + str(location["lng"]) +
        "&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m" +
        "&daily=weather_code,temperature_2m_max,temperature_2m_min" +
        "&temperature_unit=" + unit_parameter +
        "&wind_speed_unit=kn" +
        "&timezone=auto" +
        "&forecast_days=4"
    )
    response = http.get(request_url, ttl_seconds = 600)

    if response.status_code != 200:
        return render.Root(delay = 3000, max_age = 300, child = error_screen())

    weather = response.json()
    timezone = weather.get("timezone", location.get("timezone", "America/Los_Angeles"))
    current = weather["current"]
    daily = weather["daily"]

    now_screen = current_screen(current, daily)
    outlook_screen = forecast_screen(daily, timezone)

    return render.Root(
        delay = 1000,
        max_age = 600,
        show_full_animation = True,
        child = render.Animation(
            children = [
                now_screen,
                now_screen,
                now_screen,
                now_screen,
                outlook_screen,
                outlook_screen,
                outlook_screen,
                outlook_screen,
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Weather location (defaults to Mount Vernon, WA)",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Temperature Units",
                desc = "Choose Fahrenheit or Celsius",
                icon = "temperatureHalf",
                default = "Fahrenheit",
                options = [
                    schema.Option(display = "Fahrenheit", value = "Fahrenheit"),
                    schema.Option(display = "Celsius", value = "Celsius"),
                ],
            ),
        ],
    )
