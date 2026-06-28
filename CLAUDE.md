# image-workflow

Template repository for experimenting with GitHub Actions image build and deploy workflows.

## Repository structure

- `Dockerfile.base` — minimal image built from busybox
- `Dockerfile.successor` — extends base, demonstrating image inheritance
- `HUB.md` — Docker Hub descriptions; first line is `<!-- short description -->`, rest is the full overview (markdown)
- `QUAY.md` — Quay.io long description (markdown)

## Workflows

### build-images

Builds and deploys images on every push (except changes to `HUB.md`, `QUAY.md`, `README.md`, `LICENSE`) and on manual dispatch.

- `build-base` → builds `base` image, pushes to GHCR, creates semver tag if on a `v*` tag
- `push-base-hub` / `push-base-quay` → deploys base tags to Docker Hub and Quay.io
- `build-successor` → builds `successor` image (FROM base on GHCR), pushes to GHCR
- `push-successor-hub` / `push-successor-quay` → deploys successor tags to Docker Hub and Quay.io

Tags pushed: always `base` / `successor`; additionally `base-<semver>` / `successor-<semver>` on version tag pushes (leading `v` stripped).

Images carry `org.opencontainers.image.version` label with the commit SHA.

### update-descriptions

Updates repository descriptions on Docker Hub and Quay.io. Triggers on pushes to `main` that touch `HUB.md` or `QUAY.md`, and on manual dispatch.

- `update-hub` → extracts short description from the first-line comment of `HUB.md`, sends full content as overview
- `update-quay` → sends full content of `QUAY.md` as description

## Registries

| Registry | Repository |
|---|---|
| GHCR | `ghcr.io/its-me/workflow` |
| Docker Hub | `hub.docker.com/r/1tsme/workflow` |
| Quay.io | `quay.io/repository/itsme/workflow` |

## Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `HUB_USERNAME` | both workflows | Docker Hub username (`1tsme`) |
| `HUB_TOKEN` | build-images | Docker Hub access token for registry push |
| `HUB_PASSWORD` | update-descriptions | Docker Hub password for Hub REST API login |
| `QUAY_USERNAME` | build-images | Quay.io robot account username (`itsme+github`) |
| `QUAY_TOKEN` | build-images | Quay.io robot account token for registry push |
| `QUAY_API_TOKEN` | update-descriptions | Quay.io OAuth application token for REST API |
