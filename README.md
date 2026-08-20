# utserver_api

**Modern Bash client for the classic µTorrent / uTorrent WebUI API**

A complete rewrite of the original 2017 script. Clean, robust, shellcheck-friendly, uses `jq` for proper JSON handling, supports configuration files, and works with both torrent indexes and info-hashes.

## Features

- List torrents (human table or JSON)
- Get any field by name (`name`, `percent`, `status`, `folder`, ...)
- Start / stop / pause / recheck / remove / queue management
- Set properties (label, rate limits, seed ratio, etc.)
- Add torrents by magnet link or HTTP(S) URL
- Get detailed torrent properties
- Status bitfield decoder
- Config file + environment variable support
- Proper temporary files + automatic cleanup
- Works with both classic uTorrent Server and desktop µTorrent WebUI

## Requirements

- Bash 4+
- `curl`
- `jq`

```bash
# Debian/Ubuntu
sudo apt install curl jq

# Fedora
sudo dnf install curl jq

# Arch
sudo pacman -S curl jq
```

## Installation

```bash
curl -fsSL -o utserver_api https://raw.githubusercontent.com/nhsqr/utserver_api/master/utserver_api.sh
chmod +x utserver_api
sudo mv utserver_api /usr/local/bin/   # optional
```

Or just clone the repo and use the script directly.

## Configuration

Create `~/.config/utserver_api.conf`:

```bash
UTORRENT_URL="http://127.0.0.1:8080/gui/"
UTORRENT_USER="admin"
UTORRENT_PASS="yourpassword"
```

You can also use environment variables (they override the config file):

```bash
export UTORRENT_URL="http://192.168.1.50:8080/gui/"
export UTORRENT_USER="admin"
export UTORRENT_PASS="secret"
```

## Usage

```bash
utserver_api --help
```

### List torrents

```bash
utserver_api list
utserver_api list --json
```

### Get information

```bash
# By 1-based index
utserver_api get name 1
utserver_api get percent 3
utserver_api get folder 2

# By (partial) hash
utserver_api get name A1B2C3D4

# All torrents
utserver_api get name all
utserver_api get hash all
```

### Actions

```bash
utserver_api start 1
utserver_api stop A1B2C3D4E5...
utserver_api pause 2
utserver_api unpause 2
utserver_api forcestart 1
utserver_api recheck 3
utserver_api remove 4          # remove torrent only
utserver_api removedata 4      # remove torrent + data

# Queue
utserver_api set queuetop 1
utserver_api set queuebottom 5
```

### Set properties

```bash
utserver_api set label=Movies 1
utserver_api set ulrate=102400 2      # bytes/s
utserver_api set dlrate=0 2           # unlimited
utserver_api set seed_ratio=2000 1    # 2.000
```

### Add a torrent

```bash
utserver_api add "magnet:?xt=urn:btih:..."
utserver_api add "https://example.com/file.torrent"
```

### Detailed properties

```bash
utserver_api props 1
utserver_api props --json 1
```

### Decode status bitfield

```bash
utserver_api status 201
# → Loaded+Queued+Checked+Started
```

## Legacy interface (still supported)

The old `--get` / `--set` style continues to work for basic use:

```bash
utserver_api --get name 1
utserver_api -g percent all
utserver_api --set start 2
```

## Notes

- The WebUI token authentication + cookie handling is implemented correctly.
- Indexes are **1-based** (same as the original script).
- You can use a full or partial info-hash instead of an index (recommended).
- The original fragile `awk`/`grep` parsing has been completely replaced by `jq`.

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

---

Original script (2017) by [nhsqr](https://github.com/nhsqr).  
Completely rewritten and modernized in 2026.
