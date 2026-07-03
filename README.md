## Setup

1. Create a free API key at [openweathermap.org](https://openweathermap.org/api).
2. Copy the local secrets file and add your key:

   ```bash
   cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
   ```

   Then edit `Config/Secrets.xcconfig` and replace `YOUR_API_KEY_HERE` with your key.

   `Config/Secrets.xcconfig` is gitignored and will not be committed.

3. Open `WeatherApp.xcodeproj` in Xcode.
4. Select an iPhone simulator and run.

The shared Xcode scheme passes `OPENWEATHER_API_KEY` from `Secrets.xcconfig` into the app at launch via an environment variable. The app reads the key from `ProcessInfo`, not from a hardcoded `Info.plist` value.

### Security

- Do not commit `Config/Secrets.xcconfig`.
- If a key was ever shared in chat, email, or a public repo, rotate it at [openweathermap.org/api_keys](https://home.openweathermap.org/api_keys).
- For CI, inject `OPENWEATHER_API_KEY` as a protected environment variable or generate `Secrets.xcconfig` during the build.