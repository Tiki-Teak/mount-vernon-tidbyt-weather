"""
Applet: Mount Vernon WX
Summary: Current conditions and a three-day outlook
Description: A dark, high-contrast two-screen weather app with a large current
condition icon, current temperature, today's high and low, humidity, wind in
knots and direction, and a three-day forecast. Weather data is provided by
Open-Meteo.
Author: Greg Worthing
"""
# Build: 2026-08-27-three-drop-halo-temp-left-v4
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
FORECAST_ORANGE = "#FFB21A"
FORECAST_OUTLINE = "#505A61"
OFF_WHITE = "#E8EEF2"
MUTED = "#9FAEB8"
DIVIDER = "#34434C"

COLOR_CHOICES = {
    "Electric Blue": "#00B8FF",
    "Warm Orange": "#FFB21A",
    "Soft White": "#E8EEF2",
    "Mint Green": "#65E6B4",
    "Lavender": "#C4A7FF",
    "Sun Yellow": "#FFD34E",
}

COLOR_GLOWS = {
    "#00B8FF": "#004D80",
    "#FFB21A": "#6B3D00",
    "#E8EEF2": "#4D565C",
    "#65E6B4": "#195844",
    "#C4A7FF": "#49346B",
    "#FFD34E": "#665000",
}

def selected_color(config, id, default_name):
    return COLOR_CHOICES.get(config.get(id, default_name), COLOR_CHOICES[default_name])

def darker_color(color):
    return COLOR_GLOWS.get(color, BLUE_GLOW)

def color_options():
    return [
        schema.Option(display = "Electric Blue", value = "Electric Blue"),
        schema.Option(display = "Warm Orange", value = "Warm Orange"),
        schema.Option(display = "Soft White", value = "Soft White"),
        schema.Option(display = "Mint Green", value = "Mint Green"),
        schema.Option(display = "Lavender", value = "Lavender"),
        schema.Option(display = "Sun Yellow", value = "Sun Yellow"),
    ]

# Greg's photorealistic icon set, cropped and palette-optimized specifically
# for the Tidbyt's 64x32 canvas. Separate sources keep forecast icons crisp.
CURRENT_ICONS = {
    "cloudy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWBAMAAAAoU0G7AAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAqUExURSYmJv///7q7vtPU1uXl6MTFyI6Pkq+vs6ChpN7e4H5+gtDR1vT0+qGipcydtY0AAAABdFJOUwBA5thmAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+oIGwMgL/BwrrkAAAB+SURBVBjTY2AgAQgisRUFjRAcEdd0BQUom0kwtCJQEMabGtHV7LwBypko7rhsWTBEilFkqaCg2DKIhEqzo6Cg4CaI/hZBEJAEc4IFIQCsh1EQpEpQZALYLa4hPltNXCPBEqe3Ogp2hHc4QV3gKLjrLswBDEwuE5CcrcBACgAAsMgX5doDQpgAAAAASUVORK5CYII=",
    "foggy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAyVJREFUSInVlU1slGUUhZ/7zgxlSir2JxCLMrUSkg5oaWuQpD8mlqAkaFVg1YULVixIUPfK7E2EGI2JujUxNenK+Be0loq4gFptoGrTaZWh1o79sTpD25n3uJhvyFCmGBYkepbve757znfuvd9nkribcHe1+v9CIJ3J1C8uLjdOwsZy9xb0wP74M7vXmX8C2AzMIxvNr2QG6+rqltaaWljKPO3xLxi2H6gKzlcxfjDxpZf7sOae6LeATBLzS5khUHsZAzmwC6ALQNpgi+AwECvh/AZkgQeAcIn3oeqqys7igYCkQb/gd6AObB9oH6gD6CiSgofHTXozH3F9tdFoCmB6mspo1V+PIuuRcaRIttuNaTqdrgptqOzCtBuoBha93BczV5PDK66yPhRadV5ajuRys/F4fKVcDRse+/moZN2G1ZqUlnHJvM43x3dcATzA8E/JZrwOmtQF7MSI3RwHAL8A35nsvA/ZJy07HxwpCFwZL/8KxgLYJNL9hchuQh5IATkK07PlFkExtKfpoc6woTGZe1v4lOG2Ib8XrB0RA+0J6CmMj0GfOULfh/PZ5JpI3MjYxA4vtTpn+yU9dcPnej0YHU1uXYmwVd7NtjXFpsuSgIGBgfBcxm8LV+j6M93dM7cEUSrQf/ZsrVdkuzP3dyQbvXroUFumXNFEAvfIY4PPmtMxQTdQEVxNgD4X7v3nD3Sdo7gHAP2ffnUOK4xjgDzGj0jDYCMmm8IpJGkXWC/QEPA8hX5sAmpKvH/93IGujrWTMA9MAVGgEREHiwO9MgWLYAAIxp10ZtWHPjh6sHM2kcDtbh9sdnkdwdGLDz4R6/Wgr+/yhsjmmYe9WYuT2wX+PmHCNOW8fdTz5ONDlO7eOrjtopVD4vTpe8ltbMWpHqzGo6jDsqA5vF0jfP3SqydPLtwQeOW1t06Y8RLQYJCX2bRJUxK/Gkp5s1mHNslck0ktHhqtmFMZCORgwosziZePvxEGMOwbj3/XIIIsJmO7iRbMegyiwnLIj0tcxOwdc1xEmoSKuVMvHps/9fp71bBcg1mDPG2SWose7jiiO8V//4/2b/gHuHZocX87TbEAAAAASUVORK5CYII=",
    "moon": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAJFBMVEX///8AAAD776UkIxjf9f//8qj+8adjXkHbz5B7dVEdGxPWy43isZI7AAAAAXRSTlMAQObYZgAAAHFJREFUKM+NkdsOwCAIQ0Gl0+3//3dzMSqCiX3sCZQL0Ym4amNbFCIbkogEF7MlBOTZ59R9FAVaiXwgeuDzwQ4I2FTUTm5G9ZepRja8Pf4MlTLWUzV331saySVyLM90QMxSp138RKab2DcFgYSjP+/0AilxA1HpkOdPAAAAAElFTkSuQmCC",
    "partly_cloudy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAD2UExURQAAAOSKAOOOAP/BGvCeAPOfAOWJAOWJAP+ZAPKgAPOfAPGjAO2kAOSJAOGHANqGAOKNAeCLANyDAOWQAPKhAPKfAPOgAPGgAN2EAN6HAP+2JPOhAOqWANqEAP/DGuCKAP/BGuGHAOSJAOWKAOSLAOaKAOeMAPKpDf7CHv/DHP28FfWnBuWQAP////S0If/gbP/kd//icv/OOv7AGfSkA/X1+ebm6sPDyP7IM//jdf/SRv/CGviwDNPT2f7AGP/FI//LM//HKPr6/3p6f7y8wvu3EvX1+J6fo4+QlYyOk6+vtGhpbV5fY0lKTVxdYp+fpFhZX3V2ezSvbm0AAAAndFJOUwCQCYAyaKmABdFYJA4c8cj4+MKftXXhS4mRB0Hmw3f4iMJU6n1GKuNXR8IAAAABYktHRC3N2kE9AAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH6ggbBhggcZvNOAAAAOtJREFUKM+1kGtPAjEQRUdRURRRVHwDii+Q0fU1o2JFaWW63WXF//9nLBtIgPiJxJv5NKfnTlIAgLl5yGQAFhZhKkvZAVheyU1sV9cgv17Y2CxubU8+3ynt7l1e1RvXzf0DxHFyeHRzG9zdPzw28YmYxtjx80sQvLbekBWSn+G6XK68tz8+Wx1ipQmRUJkUVKuVL6O6SIzoB1EhD52iEUISHMVrqZM/MV63vpyElWLFIQ/Aae2sS85aF4nTIqJj0WnR+YVhLTr0dS7WcRTFdnQDjIHQCjLZXi/57k99WD8Rl/zAXzEwQ2aS/iG/clspy4uDtxQAAAAZdEVYdFNvZnR3YXJlAHd3dy5pbmtzY2FwZS5vcmeb7jwaAAAAAElFTkSuQmCC",
    "rainy": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAApJJREFUSIntlc1LlFEUh587M8688847Oq8fM6NmgxkYNWJJVJRaQe2MAsN2QR+08Cui1E0blylBg1AtWrSNIBf1F5iLFkXNIlyaEKIZYtN8MvPOaWHKOKaZIbTowOVyzu9wn/u7F+5VIsJOhm1HV/8P+HcBxqnIWaNt7Exx3dMW6fC0RTpWcr359jH94EDXHwGUQmm6OaZ5yx4pNbyqq/CwUzOMiBnwP1ann2oAotRNEXlohAeDWwYY7ZEuvTzYqJcH9xrt5sXV3Vf4+oK76/bU1NfXenKxbnfLnRDQ6SqvrbBXBp5vCaDUsM3uNu65vD5cXh8OtzGy4kKJ6q6uD2EG/ChFD8JdZXeWHDh+ErOusdV1aOjCbwF6m3nOU1YVWs1Nf0hv93UACGipeIL40hKSz3kQLlc2hAnv30VwVw1us/qJ2jfk3RRggysur7maa4aJTdRVgLzQG52YnI1OTM5aqYWoze5whg+34LDbCPpL0QMNFZpu3doUIHCksCQCAkcBkq/7x+MT/bX2xU9NWNkTTl8NNQEfAJUVBnaXB1dpcKDYxbpLjs1NY2WzWNkssblpgHyhni2xXQc8Tl8Ay1qWrNzy7CyvNdzu/LXCfscaB8KLdGyxJx1bLKyNF/WcB3Bopbx5N02gqpT5hRgAJW4fItIJPPglIJnSBnU9Iwq5tHxk6lky5RoqMtkEgBLiiQzxxELxITRv7ODtjSTQ93NsFAogszSPuzK0Rsh8m1vXvI23SN4DJGenSH2dQXIZJJch9XWG5OwUIB82dLCl5cU2qpS0Sj6vEp8/kvj8ca0MI3/lIB0dfSmKXiBdJKVEpCf94f6rwqLa7p/sbR7wW0g7ihDCjB018T06+qW4b9uArcYPwVTdaKtNHS8AAAAASUVORK5CYII=",
    "sleet_rain": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAA5hJREFUSIm1lV1Im2cUx//vmzcxSVO1+TQxMdGIDpv5OaR0LbUXmzeCg5JRGZRKh9DdjFq7btC6i7GbbYWxiw7CaKA3AXPTi9x4sd3IProRrF1ds1jzYWJimrRM8/Umvu97drGlpLayyvTAw/PwfPx/z+FwzmGICAdp7IGq7wZQ910+pu6/8u6BAYhhPiSimxrXRy37DlANztgBnGnQtupkepN/3wEgXGNkCvnR46dwxNZ9omHg6jv7BlANXHKAcE7vdMHVY0WL1QLVEfN3zGtXD+8LACT7hJVxCtcbg+BkLFqMjVCbnDqlWrz0vwFNrmktgPcUzRZYTM0AAL1OA1nDITQ0tlzZzQuv32/w+v2G/wRsy9n3ARxSNJsgihIAQBT+mRXaVo1KJV3Y+djjC+h7e/rWenv61zy+gP5lAK62IMI4AHDKRvwSjMJkaEQmuwUAkKuaQURnAHxd++2k25196/TwRbPOoAQAra7pIoDP6s+fAwB4HQDAEArFCgrF7M7P9Hl8AX2b2RaVczJ2Jbr+eZutdTaTzQEALAbjbDi6LtrMjmuCIEoeX8AxNTGWqw8yAwCVvzIvuFnZ3Hi2lnMy9vjwkKrIl2eXQyu384UC8oUCfg/9ebvElz99c3hIxXGyZ7p1AFoEgFLqIcq5OEiogIQKyrk4SqmHAOje1MRYLpFMjYZXo9vdnU7FZiE/WXu9tZWf7O50Kh5FY9vJZGp0amIstyMG7JcMQydIkphichnF5HK9E0TAF16/3zAycmrErDOy4UiEjg32MzzPAwA67G3MSiRKXR0drKZJM+L1+0OTbneWqS/XyoGZDxjCDQDKOvEyEV3+5uPT/qHe7sTRrk7l49wT5AsFmE1GaBvVAICnWyWkM49xWKOBUa/DcniFD94P255LNH7xq5scMXaG4GaAGYbg5ohx8Es3vn0hMK9qRPTK49bcnCGSzlwvV0lYCq1KpYpITzeL9GSzSKWKSEuhValcJSGSzly/NTdnIKK9AYgIXt+dk/f+eFQtVSX64eeg9CAcpQfhKH3/429SqSrR/dBq1eu7c7J2f08dzeML6G1Wy3yXs11+N7jIR+Nr07WzWCI5fTe4yHe2O+RWq2W+ltnc7nIvt21BlH76NVhOJFOjkgyl2r7EYiEWS7wtCOK8IPxba7DHnjw1MZZLZxPta+mY/fzZ8QVJ4OKJ9Y1iYn2jKAlc/PzZ8YVEOmZPZxPttTz4Gw193gn06rSrAAAAAElFTkSuQmCC",
    "snow": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAA1VJREFUSImllc1PG1cUxc/YY+JhbJqQGRuHjsHQAAoqpbhCabroqpuKTRdZICGkdsE+6Q4KUvMHkL2l2JtKlvDWUldNpUqUhMiW41AaO2WmtjOZ+mPcgO0Zxl+vi2oaAolxnSu9zVy993vv3nPuUIQQhCIRHgAaTYZ4PdyfAJBVSqM2WqcA4OubN4voMSyBcJTz8ILk9YxmaEtzSRgeYoXhIZa2NJcEz2jGwwtSIBzlegYAgI22Wm7M+xnfiHfTTPhGvJufzfsZmrZaej0cAGgbrVMZWV61xK2b1+dmKU3XAQBjI17qQTxBsrK8aqMbVK8A6sefd6rC8BALAG4Xj4tOFgDwslJDvvBv6XPyX7WsUhpdWVwo/V9Az88PRSK8KY6OAKWY8z2MJ24V1DJhGQaHlRoOKzWwDIOCWiYP44lbSjHnO3n7QDjKzVz7KDtzbTZ7ngCsX3613O973xP99JM524N4ghBCqGpNQ0qUyPW5WeqoUv1cfWncTT59zCb299mPp6e1Qf7it2OC8IXr8iDtcl+qXnKwv4QiEd7MnylRo9lq/7ob06VM9raZkDLZ29u7Mb3ZbLUpi2XQlPIzSV67wrk2CiUVhZKKK5xrIy3Jq2+TNNWN0RpNhowL7uyNeT+TOhDr7Rb54cIF2zcAoBtGkLZalybHx/q2d2O6mMt7XxMDIeS1Fdza4oNbW/zp7ynx+Wp8L21oRovc34m199IS2UtL5KftR23NaJHE738YafH52ul9ZwBvAopKfv24QRqPnjy9d38n1taMFikf1kj5sEZMYOxJ+t5xgzREJb9+8oIUIeStCgiEo5x/ZjI3PfGBvVBSUalWAQAetwuDA/0AgPKRBiVfAAA4HQ64uMv4Lf3sOJZMCyuLC6V3GgPdREfAyuJCKbmf8CpqccPNc03dMIIFtUwYux1/H2koH2lg7HYU1DIxjEbQzXNNRS1uJPcfv2r0eT141yZ3VaJAOMrl5BffTV0d70sdiPX3HM6QmRsYcIZSB2J9YszXl5FfrJ32Qdc9MM3I2pk701NXl50OB5wOBz6cmlzutzPfm6Y8s7HbEp30h6jk1/V6m+j1NhGV/Hon/3SUaaeS+WcmcgCFWDIldBrjPQEA/Ddezvtf9wzoNv4BNTqC7Qlmg3wAAAAASUVORK5CYII=",
    "storm": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAMAAADto6y6AAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAADJUExURQAAAOPFQIJgAIBgAJl2BIBgAIBgAIFgAOa6FsCaDoFhAO/DGMKbD4BiALqSDcSeD4NiAMmhEMehEIBdALaQC4BmAIBgAICAAP////X1+ebm6sPDyNPT2fr6/3p6f7y8wvX1+J6fo4+QlYyOk6+vtGhpbaObhpl3Bv/SHNSrE3JfJ4tzLcykEf/YMf/1mvzmb4VsGF9fYLKqlYZlAfjLGv/kW//ykK+PGpyYklhZX1xdYodvKLOOC//whoBgAOa7FvXKGpVzBaqGCU72gNMAAAAYdFJOUwD+PUBzv/53oPtX9PY8YO4n3+MWygpQApCaLtsAAAABYktHRBibaYUeAAAAB3RJTUUH6ggbBhYtkamcCwAAAMhJREFUKM+1kcl2wjAMRUMDpVDmMqiSSbCTUhXoQKFAGMzw/x+FF0ngBLOsjja+Ou/Jfnac/ymAO/wVCS0zIAFoOoP7SMJDAAThp9AXA0ACMA0ggFIuEVBCUkYWa3wjV8YcJQlBggKKBwMMlQrf5PCdmT9G0kucyJNeYOzGk8+v75+puuzwnUBJ+J3N/xbLVZS5brTebHmXe7h9n6v3fMhbAilofTxp/Vi0zJ6YS2Vbis9cqdp4jesNa+zN1ouVu+2O/Z+6vevTGc65FUI/VOTSAAAAAElFTkSuQmCC",
    "sunny": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAg1JREFUSImdlc1u00AQx3+7MuRD+WgO5IbUQui579EeoXdChHppH4GX6KWHRIgjAnGhPAdI3CoqqJRDKZEShyiOE2eHg5MmsdcmyUiWLM//Y3ZnvKtEhHVj2FQCkG+IWpej11bfMlYMhk0l8yq3CRvfuoJtTJI4KtqDZWC+IWpwoara4Qw4BJ7NUlcovpgJ54UTuYtyUg2WTZTiWEFLVyg6JdDZMG9GEPTBdPkrQl3gg0080QDAa6kXOLzPPMkoXd2D7M4s0QP3BgIPMwK/jTDhONeQj2ttEcDgQlWdB/x4uJ8p6scHUH0VZ34/hcDHjGD8i36gqRVeyp8ozNpk7XCmKxR1dQ+0Y10h5d0QmwW9Q0lPObXB7GzhyCmx2JbOuzgmV1mIlCHocgS8iRlExyvfEIXiqc7YC7eFzoCCGsTH1bpFCkKQ10tW9br3rwKIYJ0WxzZaAtfG50C7N5Atx/tgAuj9XOB9QHEN8VG1n0WKy6APBB78/gbDDsg0fIYduP0K0/E9PHAB4bNVKnVMdynOf66kMCMY3+BOAmrF19KJ5q0rKJzInQh1v42YUbq430bEULeJJ65gHl5TPVeali5TcsrhtAAYP9wW4+KKoZ5ryKckjRUD24UyeKsezX6iQ2B/9vkK4XIqnC9XbuNbDaKgNIH/cVd6sJzY5E5IKyzW5E3u23W41rNoU5M0/D8sWgZb9zuqaAAAAABJRU5ErkJggg==",
}

# Final compact, haloed three-drop rain artwork.
CURRENT_ICONS["rainy"] = "iVBORw0KGgoAAAANSUhEUgAAABgAAAAWCAYAAADafVyIAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAztJREFUSIntlV9sU1Ucx7/n3tN2be/W2471j2woyswIBgNGiRGVmTldshD/LYZEXzU+kGAkPJqAvvDKAwm8kKiBmGYDFppCs7gyqSSDkbiwTRTYP/a3Bda19/be3nPP4YXb1AE6E/dg4u/p5Pv9fX+fk995OEQIgbUsaU2n/w/47wHi8VF3TyLdtmYA3ZM7oHG5+2xqoOlfByQSl4Kaic9PDat1OQ0nHL07ObDtHwN6ezO1K7UsE/v7x5VYfaQeM0v0he5UuqX3QnqTwexL35/56dNVA+J9fYGSbE2dvPDzK9W6xdC5oNfIkkRwZdoTWdbkPfMFfHc4UfRpZXx7Jp1WVwUoFtxHfrgm1ZZ0ceLgwWpf8KX7Gq6PLYKIsk2p2HLldmlztGkDfhyy1+fu8mN/CzjdN7B5tiDeNmoicv8t+szT2y7uczzFZ+/7Yqcx/W5zceH9rew3zWA7MlMuNRIJgQbC8njWbo2fz+z8S0B2WRzvHauJxUIK5ljQVzTxpfMeezpaLzZ5fS3bN9qvc7BUfFCLbtrYCACIhkM4NyIalorW0ScCulPplsn7ojkQVCEIQayhDskbNJLj9ldOT2fnS3qtMGZ1g380kXfRQMBfGdQQDePapNF4MtH/zmMB9zTy9flREqlXfQAAQgjuFGpcZYt/Uh2Y1ejexLARVeuUP910XbAOyWEjWDTEN48FcI4XZ5YBxnjFZDbHfEHynk79EnY00xYfDk+VXSv/ES4AzeTI6yKWTCY9jwCEACMAfv19HnPZZdwYX8TdvA435YJJulmBMqJYtsDc4j0UiqWHWYGbt2cAALkCoybxxpx+6hzcVDr78gbePDhleK/fNAAAqhdYp0jzXW1t+UqAokQlAmbZuDw4glq/F4ZpwSxbAICgn9o+qZx9BPCsah/avYW81hjA9pEFqA0KzPbnMR32so+rV+GRyakdz7lbMn+YXs4F8gW94oUUGSE/mWxvb9ccjazcZU9q4I18SezyUYxJuvtcV9erpWr/+NCQS5rIZ3qulrZenTA9Tnx9UMZnbyrTTwVI63sdb916ImA1FY+Puovy4iGT2btNi/gpheGmGK33SXs/6Nh1p7r3AYo0ceHKt1o1AAAAAElFTkSuQmCC"

# Forecasts reuse the richer current-condition source art. Rendering the art
# larger keeps details recognizable on the physical matrix and preserves one
# consistent visual style across both screens.
FORECAST_ICONS = CURRENT_ICONS

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
    if code == 56 or code == 57 or code == 66 or code == 67:
        return "sleet_rain"
    if (code >= 51 and code <= 65) or (code >= 80 and code <= 82):
        return "rainy"
    if (code >= 71 and code <= 77) or (code >= 85 and code <= 86):
        return "snow"
    if code >= 95:
        return "storm"
    return "cloudy"

def current_icon(kind, width = 24, height = 22):
    return render.Image(
        width = width,
        height = height,
        src = base64.decode(CURRENT_ICONS[kind]),
    )

def forecast_icon(kind, width = 11, height = 11):
    return render.Image(
        width = width,
        height = height,
        src = base64.decode(FORECAST_ICONS[kind]),
    )

def temperature_text(value, temperature_color = FORECAST_ORANGE, glow_color = FORECAST_OUTLINE):
    content = str(round_temp(value)) + "°"
    return render.Stack(
        children = [
            render.Padding(
                pad = (0, 2, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (4, 2, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (2, 4, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (1, 2, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = glow_color),
            ),
            render.Padding(
                pad = (3, 2, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = glow_color),
            ),
            render.Padding(
                pad = (2, 1, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = glow_color),
            ),
            render.Padding(
                pad = (2, 3, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = glow_color),
            ),
            render.Padding(
                pad = (2, 2, 0, 0),
                child = render.Text(content = content, font = FONT_TEMP, color = temperature_color),
            ),
        ],
    )

def forecast_temperature_text(value, temperature_color = FORECAST_ORANGE):
    content = str(round_temp(value)) + "°"
    return render.Stack(
        children = [
            render.Padding(
                pad = (0, 2, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (4, 2, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (2, 4, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (3, 1, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (1, 3, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (3, 3, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = BLACK),
            ),
            render.Padding(
                pad = (1, 2, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = FORECAST_OUTLINE),
            ),
            render.Padding(
                pad = (3, 2, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = FORECAST_OUTLINE),
            ),
            render.Padding(
                pad = (2, 1, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = FORECAST_OUTLINE),
            ),
            render.Padding(
                pad = (2, 3, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = FORECAST_OUTLINE),
            ),
            render.Padding(
                pad = (2, 2, 0, 0),
                child = render.Text(content = content, font = FONT_FORECAST_TEMP, color = temperature_color),
            ),
        ],
    )

def small_outlined_text(content, color = OFF_WHITE):
    return render.Stack(
        children = [
            render.Padding(pad = (0, 0, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = FORECAST_OUTLINE)),
            render.Padding(pad = (2, 0, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = FORECAST_OUTLINE)),
            render.Padding(pad = (0, 2, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = FORECAST_OUTLINE)),
            render.Padding(pad = (2, 2, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = FORECAST_OUTLINE)),
            render.Padding(pad = (1, 0, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = BLACK)),
            render.Padding(pad = (0, 1, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = BLACK)),
            render.Padding(pad = (2, 1, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = BLACK)),
            render.Padding(pad = (1, 2, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = BLACK)),
            render.Padding(pad = (1, 1, 0, 0), child = render.Text(content = content, font = FONT_TINY, color = color)),
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

def metric_row(label, value, value_color = OFF_WHITE):
    return render.Row(
        children = [
            render.Text(content = label, font = FONT_TINY, color = MUTED),
            render.Padding(
                pad = (1, 0, 0, 0),
                child = render.Text(content = value, font = FONT_TINY, color = value_color),
            ),
        ],
    )

def forecast_day(daily, timezone, index, width, temperature_color = FORECAST_ORANGE, text_color = MUTED):
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
                render.Padding(pad = (0, 3, 0, 0), child = forecast_icon(weather_kind(code), 20, 23)),
                render.Padding(
                    pad = (4, 0, 0, 0),
                    child = forecast_temperature_text(daily["temperature_2m_max"][index], temperature_color),
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
                                render.Text(content = label, font = FONT_TINY, color = text_color),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def current_screen(current, daily, temperature_color = FORECAST_ORANGE, text_color = OFF_WHITE, wind_suffix = "KT"):
    kind = weather_kind(
        int(current["weather_code"]),
        int(current["is_day"]) == 1,
    )
    humidity = str(int(current["relative_humidity_2m"]))
    wind = str(round_temp(current["wind_speed_10m"]))
    direction = wind_direction(current["wind_direction_10m"])
    high = str(round_temp(daily["temperature_2m_max"][0])) + "°"
    low = str(round_temp(daily["temperature_2m_min"][0])) + "°"

    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Stack(
            children = [
                render.Padding(pad = (0, 0, 0, 0), child = current_icon(kind, 30, 27)),
                render.Padding(
                    pad = (12, 14, 0, 0),
                    child = temperature_text(current["temperature_2m"], temperature_color, FORECAST_OUTLINE),
                ),
                render.Padding(
                    pad = (32, 0, 0, 0),
                    child = render.Box(
                        width = 32,
                        height = 32,
                        child = render.Column(
                            expanded = True,
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Row(
                                    children = [
                                        small_outlined_text(low, temperature_color),
                                        render.Padding(
                                            pad = (0, 0, 0, 0),
                                            child = small_outlined_text("/", MUTED),
                                        ),
                                        small_outlined_text(high, text_color),
                                    ],
                                ),
                                small_outlined_text(humidity + "%", text_color),
                                render.Row(
                                    cross_align = "center",
                                    children = [
                                        small_outlined_text(wind, temperature_color),
                                        small_outlined_text(wind_suffix + " " + direction, text_color),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def forecast_screen(daily, timezone, temperature_color = FORECAST_ORANGE, text_color = MUTED):
    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Row(
            children = [
                forecast_day(daily, timezone, 1, 21, temperature_color, text_color),
                forecast_day(daily, timezone, 2, 21, temperature_color, text_color),
                forecast_day(daily, timezone, 3, 22, temperature_color, text_color),
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
    wind_units = config.get("wind_units", "Knots")
    wind_parameter = "mph" if wind_units == "Miles per hour" else "kn"
    wind_suffix = "MPH" if wind_units == "Miles per hour" else "KT"
    current_temperature_color = selected_color(config, "current_temperature_color", "Warm Orange")
    forecast_temperature_color = selected_color(config, "forecast_temperature_color", "Warm Orange")
    text_color = selected_color(config, "text_color", "Soft White")
    request_url = (
        FORECAST_URL +
        "?latitude=" + str(location["lat"]) +
        "&longitude=" + str(location["lng"]) +
        "&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m" +
        "&daily=weather_code,temperature_2m_max,temperature_2m_min" +
        "&temperature_unit=" + unit_parameter +
        "&wind_speed_unit=" + wind_parameter +
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

    now_screen = current_screen(current, daily, current_temperature_color, text_color, wind_suffix)
    outlook_screen = forecast_screen(daily, timezone, forecast_temperature_color, text_color)

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
            schema.Dropdown(
                id = "wind_units",
                name = "Wind Units",
                desc = "Show wind in knots or miles per hour",
                icon = "wind",
                default = "Knots",
                options = [
                    schema.Option(display = "Knots", value = "Knots"),
                    schema.Option(display = "Miles per hour", value = "Miles per hour"),
                ],
            ),
            schema.Dropdown(
                id = "current_temperature_color",
                name = "Current Temperature Color",
                desc = "Color of the large current temperature",
                icon = "palette",
                default = "Warm Orange",
                options = color_options(),
            ),
            schema.Dropdown(
                id = "forecast_temperature_color",
                name = "Forecast Temperature Color",
                desc = "Color of forecast high temperatures",
                icon = "palette",
                default = "Warm Orange",
                options = color_options(),
            ),
            schema.Dropdown(
                id = "text_color",
                name = "Lettering Color",
                desc = "Color of days and condition numbers",
                icon = "font",
                default = "Soft White",
                options = color_options(),
            ),
        ],
    )
