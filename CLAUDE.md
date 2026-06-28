# image-workflow

Template repository for experimenting with GitHub Actions image build and deploy workflows.

## Repository structure

- `Dockerfile.base` — minimal image built from busybox
- `Dockerfile.successor` — extends base, demonstrating image inheritance
- `HUB.md` — Docker Hub descriptions; first line is `<!-- short description -->`, rest is the full overview (markdown)
- `QUAY.md` — Quay.io long description (markdown)

## Workflows

### build-images

Triggers on every push (except changes to `HUB.md`, `QUAY.md`, `README.md`, `LICENSE`), on pull requests, and on manual dispatch.

**Job chain:**
1. `build-base` (matrix: 8 platforms) — builds `base` image per platform, pushes by digest to GHCR
2. `assemble-base` — collects digests, creates multi-arch manifest in GHCR
3. `push-base-hub` / `push-base-quay` — copies manifest from GHCR to Docker Hub and Quay.io
4. `build-successor` (matrix: 8 platforms) — builds `successor` image per platform (FROM base in GHCR), pushes by digest
5. `assemble-successor` — creates multi-arch manifest for successor in GHCR
6. `push-successor-hub` / `push-successor-quay` — copies manifest from GHCR to Docker Hub and Quay.io

**Registry push is conditional:** assemble and deploy jobs only run on `main` branch or `v*` tag pushes. Build jobs run on all triggers but use `type=cacheonly` output on non-main/non-tag refs (build verification only, nothing pushed).

`build-successor` uses `if: always() && (needs.assemble-base.result == 'success' || needs.assemble-base.result == 'skipped')` so it runs even when `assemble-base` is skipped (non-main).

**Tags pushed:** always `base` / `successor`; additionally `base-<semver>` / `successor-<semver>` on `v*` tag pushes (leading `v` stripped).

**Platforms:** `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`, `linux/386`, `linux/ppc64le`, `linux/s390x`, `linux/riscv64`. Native runners for amd64 and arm64/arm; QEMU for the rest.

**Runners:** build jobs use matrix runners (`ubuntu-latest` or `ubuntu-24.04-arm`); assemble jobs use `ubuntu-latest` (need Docker daemon for `setup-buildx-action`); deploy jobs use `ubuntu-slim` (`imagetools create` works via registry API without a daemon).

**OCI labels on both images:** `version` (commit SHA), `source`, `title`, `description`, `licenses`, `authors`. `Dockerfile.successor` also carries `base.name`.

### update-descriptions

Triggers on pushes to `main` that touch `HUB.md` or `QUAY.md`, and on manual dispatch. Runs on `ubuntu-slim`.

- `update-hub` — extracts short description from the first-line comment of `HUB.md`, sends full content as overview via Docker Hub REST API
- `update-quay` — sends full content of `QUAY.md` as description via Quay.io REST API

## Registries

| Registry | Repository |
|---|---|
| GHCR | `ghcr.io/its-me/workflow` |
| Docker Hub | `hub.docker.com/r/1tsme/workflow` |
| Quay.io | `quay.io/repository/itsme/workflow` |

## Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `HUB_USERNAME` | both workflows | Docker Hub username |
| `HUB_TOKEN` | build-images | Docker Hub access token for registry push |
| `HUB_PASSWORD` | update-descriptions | Docker Hub account password for REST API login |
| `QUAY_USERNAME` | build-images | Quay.io robot account username |
| `QUAY_TOKEN` | build-images | Quay.io robot account token for registry push |
| `QUAY_API_TOKEN` | update-descriptions | Quay.io OAuth application token for REST API |
