# mywork

MyWork — multilingual virtual avatar project.

## Priya Avatar

**Priya** is a female virtual assistant that speaks:

- **English** (`en-IN`)
- **Hindi** (`hi-IN`)
- **Gujarati** (`gu-IN`)

### Project layout

```
avatars/priya/
  config.json          # Avatar metadata and language settings (source)
  assets/avatar.png    # Avatar portrait
public/
  avatars/priya/       # Deployed copy used by the web UI
  index.html           # Interactive avatar UI
  css/style.css
  js/avatar.js
```

### Run on your laptop

**Linux / macOS**

```bash
chmod +x host.sh
./host.sh
```

**Windows**

```bat
host.bat
```

The script syncs avatar files, starts a local server, and opens your browser at [http://127.0.0.1:8080](http://127.0.0.1:8080).

Optional environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `127.0.0.1` | Bind address |
| `OPEN_BROWSER` | `1` | Set to `0` to skip opening the browser |

Example:

```bash
PORT=3000 ./host.sh
```

**Manual start**

```bash
python3 -m http.server 8080 --directory public
```

### How it works

- Avatar settings live in `avatars/priya/config.json`.
- The web UI loads that config and uses the browser **Web Speech API** for text-to-speech.
- Switch between English, Hindi, and Gujarati with the language tabs.
- Type a message or click **Greet me** to hear Priya speak.

> Hindi and Gujarati voice quality depends on voices installed on your system or browser.
