---
title: Sync server
description: Run your own Sumizuri sync server with Docker.
eyebrow: Guide for self-hosters
heading: Run your own sync server
lead: Keep your library the same on every device, on a server you host yourself.
facts:
  - Docker on x86 or ARM
  - SQLite or Postgres
  - Locked before it is sent
---

You host the server yourself. We do not run one for you.

Your library is locked on your device before it is sent, so the server cannot read it. The server keeps your username, and the name, type, app version and last seen time of your devices.

## What you need

- A machine that runs Docker, on x86 or ARM.
- A domain name, and a reverse proxy of your own that gives the server HTTPS. The server speaks plain HTTP on port 8080.

## 1. Get the files

Each release has two files for the server, listed on the [download page](/download) under the sync server files:

- `sumizuri-sync-docker-compose.yml`, which you save as `docker-compose.yml`
- `sumizuri-sync.env.example`, which you save as `sumizuri.env`

Put both in one folder.

## 2. Set it up

Open `sumizuri.env` and change the parts in capitals.

| Setting | What it does |
| --- | --- |
| `SUMIZURI_PUBLIC_URL` | The address people type in the app. It is the address of your reverse proxy, such as `https://sync.example.com`. |
| `SUMIZURI_TRUST_PROXY` | Keep this `on` behind a reverse proxy, so the address of each person is read from the headers the proxy adds. Turn it `off` if the server is reached directly. |
| `SUMIZURI_MAX_UPLOAD_MB` | The biggest batch the server takes, in MB. The default is 100. |
| `SUMIZURI_NAME` | The name the app shows for your server. |
| `SUMIZURI_SIGNUP_MODE` | Who can sign up: `open` for anyone, `invite` for people with an invite from you, or `closed` for no one new. The example uses `invite`. |

A live setting given here is locked in the app. Leave it out to change it from the app instead.

These live settings are not in the example, and you can add them the same way:

| Setting | What it does |
| --- | --- |
| `SUMIZURI_MIN_PASSWORD` | The shortest password allowed. The default is 10, and it can be 8 to 128. |
| `SUMIZURI_WRONG_TRIES` | How many wrong passwords in a row before a pause of 15 minutes. The default is 5, and it can be 3 to 50. |
| `SUMIZURI_USER_STORAGE_MB` | The most space each person may use, in MB. 0 means no limit, which is the default. |
| `SUMIZURI_IDLE_DEVICE_DAYS` | Devices not seen for this many days are signed out. 0 means never, which is the default. |

### Use Postgres

The server keeps its data in one SQLite file in `/data`, which needs nothing else. For many people, or if you already run Postgres, point it at your database:

```
SUMIZURI_DATABASE_URL=postgres://USER:PASSWORD@db:5432/sumizuri
```

The user and password can also go in `SUMIZURI_DATABASE_USER` and `SUMIZURI_DATABASE_PASSWORD` instead. A `sqlite:` address keeps SQLite with another file name.

## 3. Start it

```bash
docker compose up -d
```

The compose file publishes the server on `127.0.0.1:8080`, so only the same machine can reach it. Point your reverse proxy at that address.

- A proxy on the same machine can use `127.0.0.1:8080`.
- A proxy in another container on the same Docker network can reach `sumizuri-sync:8080`. Then you can remove the `ports` lines.
- A proxy on another machine needs the `ports` line changed to publish on an address it can reach.

Your data is kept in the `sumizuri-data` volume, mounted at `/data`.

## 4. Connect the app

In the app, open the sync page, enter the address you set in `SUMIZURI_PUBLIC_URL`, and sign in or sign up.

## Update

```bash
docker compose pull
```

```bash
docker compose up -d
```

## The image

```bash
docker pull ghcr.io/not-akari/sumizuri-sync:latest
```

The image runs as its own user and not as root, and it keeps everything in `/data`.
