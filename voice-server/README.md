# Voice meal logging

Tap the widget microphone to start recording in Hebrew. Recording stops after about 2.4 seconds of silence after speech, or when you tap the large microphone. You can also type a description. The service uses OpenAI to transcribe recordings and extract food, dates, eaten/planned status, and explicitly stated nutrition. It first checks the personal food catalog in Settings, then matching diary entries for foods outside the catalog, and uses USDA data for remaining values. Personal foods are saved on the device. The optional `MARKEAT_PERSONAL_FOOD_SEED` build setting takes a base64-encoded JSON array of initial foods with `id` (UUID), `name`, `calories`, optional `protein`, and optional `defaultGrams`. When `defaultGrams` is set, nutrition is per 100 g. A saved catalog takes precedence over the seed. The diary itself stays in the app's SwiftData store shared with its widget.

## Run on the Mac

1. Download the SR Legacy and optionally the FNDDS CSV ZIPs from [USDA FoodData Central](https://fdc.nal.usda.gov/download-datasets/).
2. Put the Python files in a directory the service account can read. Generate the local catalog beside `server.py` with `python3 import_usda.py usda-foods.json SR_LEGACY.zip FNDDS.zip`. Leave out the second ZIP if you only downloaded SR Legacy.
3. Set `OPENAI_API_KEY` in the server environment or let the service read the existing ContentRoom server credentials from its default location. Set `USDA_API_KEY` for API lookups if available. Without it, API lookups use the limited USDA demo key.
4. Run `python3 server.py --login YOUR_TAILSCALE_LOGIN`. The service binds to localhost and checks the identity supplied by Tailscale Serve.
5. Run `tailscale serve --bg --set-path /markeat http://127.0.0.1:8769`. Use the resulting HTTPS address in the app's **Voice server** settings or set the `MARKEAT_VOICE_ENDPOINT` build setting. The iPhone needs to be on the same tailnet and signed in with the configured login.

Recordings and transcripts are not logged or stored by the Mac service. Audio and text are sent to OpenAI for processing. For matching, the app sends personal and recent food names and nutrition values to the Mac service. The service includes the food names in the OpenAI extraction request. For online USDA lookups, the service sends the food search terms.
