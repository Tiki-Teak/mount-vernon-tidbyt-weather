# Mount Vernon WX for Tidbyt

A custom two-screen weather app designed for Greg's Tidbyt Gen 2. It
automatically alternates between:

- A clean current-conditions screen with a large photorealistic icon, blue
  overlapping temperature, today's high and low side-by-side, humidity, and
  wind speed/direction in knots
- A dedicated three-day forecast screen where each day repeats the main visual
  style: weather image with its blue high temperature overlapping the lower
  right and a small day label below

Mount Vernon, Washington is the default. The Tidbyt settings screen can change
the location or switch between Fahrenheit and Celsius. Weather data comes from
[Open-Meteo](https://open-meteo.com/) and requires no API key.

The uploaded full-resolution weather art was cropped, reduced, sharpened, and
palette-optimized into separate 24x22 current-condition and 12x12 forecast
assets. Those optimized images are embedded in the app, so there are no extra
asset files to install. Each screen remains visible for about four seconds.

## Install locally

1. Install Pixlet by following Tidbyt's official instructions:
   <https://tidbyt.dev/docs/build/installing-pixlet>
2. Preview the app:

   ```sh
   pixlet render mount_vernon_weather.star
   pixlet serve mount_vernon_weather.star
   ```

3. Push it to the Tidbyt (replace the placeholders with the values from your
   Tidbyt developer settings):

   ```sh
   pixlet push --api-token YOUR_API_TOKEN --installation-id mount-vernon-weather \
     YOUR_DEVICE_ID mount_vernon_weather.webp
   ```

The app can also be submitted to Tidbyt Community Apps for normal installation
through the Tidbyt mobile app.

## Data and compatibility

- Canvas: standard Tidbyt 64x32, compatible with Tidbyt Gen 2 firmware 1.353.94
- Weather cache: 10 minutes when cloud-hosted; Tidbyt controls the precise
  server render timing
- Forecast source: Open-Meteo best-match forecast model
- Credentials: none

## Automatic cloud updates with GitHub Actions

The included GitHub Actions workflow renders the latest weather and updates a
single, persistent Tidbyt installation every five minutes. The Mac can remain
off, and Tidbyt Plus is not required.

Add these two encrypted repository secrets before running the workflow:

- `TIDBYT_DEVICE_ID`
- `TIDBYT_API_TOKEN`

Both values are available in the Tidbyt mobile app under the device's settings:
**General > Get API Key**. Never commit the API token to the repository.
