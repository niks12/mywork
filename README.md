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

### Install on Linux

#### 1. Install required tools

You need **Git**, **Python 3**, and a web browser (Chrome or Firefox recommended).

**Ubuntu / Debian**
```bash
sudo apt update
sudo apt install -y git python3
```

**Fedora**
```bash
sudo dnf install -y git python3
```

**Arch Linux**
```bash
sudo pacman -S git python
```

Check Python:
```bash
python3 --version
```

#### 2. Get the project

If you already have the repo:
```bash
cd ~/mywork
git checkout cursor/female-multilingual-avatar-d1ec
```

Or clone it fresh:
```bash
git clone https://github.com/niks12/mywork.git
cd mywork
git checkout cursor/female-multilingual-avatar-d1ec
```

#### 3. Start the avatar app

```bash
chmod +x host.sh
./host.sh
```

Your browser should open at [http://127.0.0.1:8080](http://127.0.0.1:8080).

If the browser does not open automatically:
```bash
xdg-open http://127.0.0.1:8080
```

#### 4. Stop the server

Press `Ctrl+C` in the terminal where `./host.sh` is running.

#### Optional: better Hindi/Gujarati voices

Speech uses your browser's text-to-speech. For better voices on Linux:

**Ubuntu / Debian**
```bash
sudo apt install -y speech-dispatcher espeak-ng
```

Then use **Chrome** or **Chromium** for the best multilingual voice support.

#### Troubleshooting

| Problem | Fix |
|---------|-----|
| `python3: command not found` | Install Python 3 (step 1) |
| `Permission denied` for `host.sh` | Run `chmod +x host.sh` |
| Port `8080` already in use | Run `PORT=3000 ./host.sh` |
| Avatar page loads but no voice | Use Chrome/Firefox and allow audio in the browser |
| Hindi/Gujarati sound wrong | Switch language tab first, then click **Greet me** |

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
