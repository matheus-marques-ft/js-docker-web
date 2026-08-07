# JumpServer Web

JumpServer's LB Nginx build project, bundling Lina, Luna, and a few static installer package files.

## Docker Build

```bash
VERSION=dev
docker buildx build --build-arg VERSION=${VERSION} -t ghcr.io/matheus-marques-ft/web:${VERSION} . --load
```

## Repository Layout

This repo produces the `web` image consumed by [js-installer](https://github.com/matheus-marques-ft/js-installer)'s `compose/web.yml` — it doesn't contain frontend source itself, it assembles the pre-built [js-lina](https://github.com/matheus-marques-ft/js-lina) (admin console) and [js-luna](https://github.com/matheus-marques-ft/js-luna) (end-user web terminal) apps behind an nginx reverse proxy/LB, plus a set of Windows/macOS installer packages used by remote-app connections.

- **`Dockerfile`** — the CE image. Builds `lina`/`luna` as named build contexts (see `docker-bake.hcl`) from their own repos, copies the built assets into an `nginx:1.31-trixie` base, and lays down the nginx config (`nginx.conf`, `default.conf`, `http_server.conf`, `includes/`).
- **`docker-bake.hcl`** — drives the multi-stage build via `docker buildx bake`. Targets `lina` and `luna` build from remote git contexts (`https://github.com/matheus-marques-ft/js-lina.git`/`js-luna.git`); target `ce` builds this repo's `Dockerfile` and substitutes those two as named contexts by exact FROM-line string match.
- **`includes/*.conf`** — one nginx `location` block per backend component (`core`, `koko`, `lion`, `chen`, plus disabled `.conf.disabled` stubs for Enterprise-only components like `razor`/`facelive`/`kotl`). `init.sh` enables/disables these at container start based on `*_ENABLED` env vars.
- **`init.sh`** — the container entrypoint script (`/docker-entrypoint.d/40-init-config.sh`). Picks HTTP vs HTTPS vs Helm-mounted nginx config, applies `SERVER_NAME`/`CLIENT_MAX_BODY_SIZE`/IPv6/gzip settings from env vars, and toggles per-component `includes/*.conf` files.
- **`Dockerfile-static`** + **`prepare.sh`** + **`versions.txt`** — a separate pipeline (built by `build-static-image.yml`) that downloads third-party tools bundled for remote-app launches: browser/Python portable runtimes, DBeaver, the JumpServer desktop client installers (from [js-client](https://github.com/matheus-marques-ft/js-client)), and some FIT2CLOUD-hosted assets (`glyptodon-enterprise-player`, `Tinker_Installer`) that require access to `jms-pkg.fit2cloud.com` — those two are private infrastructure this fork doesn't have access to.
- **`Dockerfile-ee`** and the `ee` bake target from the upstream project (Enterprise/xpack build) were removed here — this fork only targets the Community Edition.

## CI → GHCR mapping

| Workflow | Publishes |
|---|---|
| `build-release-image.yml` | `ghcr.io/matheus-marques-ft/web:<tag>` (and `:<tag>-ce`) — triggered on `v*` tags, runs `docker buildx bake ce` |
| `build-static-image.yml` | `ghcr.io/matheus-marques-ft/web-static:<timestamp>` — triggered by changes to `versions.txt`/`prepare.sh`/`Dockerfile-static` on `pr*`/`osm` branches |
| `build-nginx-image.yml` | `ghcr.io/matheus-marques-ft/nginx:<tag>` — manual dispatch only |
| `check-deps-versions.yml` | no image; opens a PR bumping `CLIENT_VERSION`/`TINKER_VERSION` in `versions.txt` on a daily schedule |
