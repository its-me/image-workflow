# image-workflow

Template repository for experimenting with GitHub Actions image build and deploy workflows.

## Repository structure

- `Dockerfile` — standalone single-stage image built from busybox (title `workflow-single-stage`)
- `Dockerfile.chain-link-1` — extends the single-stage image, first link in a multi-stage chain
- `Dockerfile.chain-link-2` — extends `chain-link-1`, second link in the chain
- `Dockerfile.simple` — extends the single-stage image, built for a single platform only, no matrix/digest-assemble steps
- `HUB.md` — Docker Hub descriptions; first line is `<!-- short description -->`, rest is the full overview (markdown). References `media/chain.svg` and relative Dockerfile links to demonstrate `its-me/action.hub.description`'s `url-completion` input, which is enabled in `descriptions.yaml`.
- `QUAY.md` — Quay.io long description (markdown). References `media/chain.svg` and relative Dockerfile links to demonstrate `its-me/action.quay.description`'s `url-completion` input, which is enabled in `descriptions.yaml`.
- `media/chain.svg` — diagram of the single-stage → chain-link-1 → chain-link-2 build chain, embedded in `HUB.md` and `QUAY.md`

All four images share one container repository (`ghcr.io/its-me/workflow`, `1tsme/workflow`, `quay.io/itsme/workflow`), distinguished only by tag prefix.

## Release flow

None of the build workflows trigger on ordinary pushes or PRs — every build is tied to a `v*` semver tag (or a manual dispatch naming one).

**check-release.yaml** — daily schedule + manual dispatch, `ubuntu-slim`. Lists every stable release of [its-me/dummy.releases](https://github.com/its-me/dummy.releases) and, for each one at or above this repo's oldest `v*` tag that has no `vX.Y.Z` tag here yet, dispatches all three build workflows below via `gh workflow run <file> -f tag="vX.Y.Z"` (fire-and-forget, no waiting). Looking at all releases rather than only upstream's latest means several releases published between two checks are all built. It does not create tags itself (`contents: read`).

**Repository tags** are created by `workflow.yaml`'s final `tag` job on `workflow_dispatch` runs, once its Docker Hub and Quay.io pushes succeed (skipped if the tag already exists, e.g. a pushed tag). So a manual dispatch also leaves a tag behind, and a failed release has no tag and is re-dispatched by the next check. The tag is created with `GITHUB_TOKEN`, so it does not re-trigger the tag-push builds. `chain` and `simple` never create tags.

## Workflows

### workflow (Release)

The foundational workflow. Builds `Dockerfile` (single Dockerfile, no inheritance), matrix over 8 platforms, push-by-digest to GHCR, assemble into a multi-arch manifest, then copy to Docker Hub and Quay.io. Mirrors the structure used in `image.zizmor`.

**Tags:** `<version>` always; additionally the bare `latest` tag when the version is the highest stable upstream release (compared via `sort -V`).

### chain

Demonstrates a multi-stage image chain built on top of `workflow`'s output.

**Job chain:**
1. `build-link-1` (matrix: 8 platforms) — builds `Dockerfile.chain-link-1` (`FROM ghcr.io/its-me/workflow:latest`), pushes by digest to GHCR
2. `assemble-link-1` — collects digests, creates multi-arch manifest in GHCR
3. `push-link-1-hub` / `push-link-1-quay` — copies manifest to Docker Hub and Quay.io
4. `build-link-2` (matrix: 8 platforms) — builds `Dockerfile.chain-link-2` (`FROM ghcr.io/its-me/workflow:chain-link-1`), pushes by digest
5. `assemble-link-2` — creates multi-arch manifest for link 2 in GHCR
6. `push-link-2-hub` / `push-link-2-quay` — copies manifest to Docker Hub and Quay.io

**Tags:** `chain-link-1-<version>` / `chain-link-2-<version>` always; additionally the bare `chain-link-1` / `chain-link-2` tag when the version is the highest stable upstream release.

**Dependency note:** since `Dockerfile.chain-link-1` builds `FROM ghcr.io/its-me/workflow:latest`, this workflow assumes `workflow` has already published that tag for the same (or an earlier) version — `check-release.yaml` dispatches both without waiting, so a very first release could race; not an issue on subsequent releases since `latest` already exists.

### simple

The simplest flavor: a single job, no matrix, no QEMU, no digest-assemble dance — modeled after the repository's historical `single-architecture` tag, minus its deprecated `environment:` blocks. Builds `Dockerfile.simple` (`FROM ghcr.io/its-me/workflow:latest`) for `linux/amd64` only, pushes directly, then copies to Docker Hub and Quay.io.

**Tags:** `simple-<version>` always; additionally the bare `simple` tag when the version is the highest stable upstream release.

### descriptions (Repository Descriptions Update)

Triggers on pushes to `main` that touch `HUB.md` or `QUAY.md`, and on manual dispatch. Runs on `ubuntu-slim`.

- `hub` — extracts short description from the first-line comment of `HUB.md`, sends full content as overview via Docker Hub REST API
- `quay` — sends full content of `QUAY.md` as description via Quay.io REST API

### zizmor

Lints this repository's own GitHub Actions workflows for security issues using [its-me/action.zizmor](https://github.com/its-me/action.zizmor). Triggers on every push and PR, plus manual dispatch.

## Common patterns across workflow, chain, and simple

- **Version resolution:** a `resolve-version` job derives the version from the pushed tag (`refs/tags/vX.Y.Z`) or the `workflow_dispatch` `tag` input, rejects anything that isn't a dotted number, then computes `is_latest` by comparing against the highest stable `its-me/dummy.releases` release via `sort -V`. Upstream is the reference rather than this repo's tags because several versions may build concurrently and tags only appear once a release succeeds.
- **Run naming / concurrency:** `run-name` shows the tag being built, and a `<workflow>-<tag>` concurrency group queues duplicate runs of the same version instead of running them in parallel.
- **Runners:** `resolve-version` (workflow, chain) uses `ubuntu-latest`, since resolving the platform matrix needs `docker buildx imagetools inspect`; matrix build jobs use `ubuntu-latest` or `ubuntu-24.04-arm` (native) with QEMU for the rest; assemble jobs use `ubuntu-latest` (need Docker daemon for `setup-buildx-action`); deploy jobs use `ubuntu-slim` (`imagetools create` works via registry API without a daemon).
- **Platforms** (workflow, chain): resolved at run time from `busybox:latest`'s upstream manifest against a known list of `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`, `linux/386`, `linux/ppc64le`, `linux/s390x`, `linux/riscv64` — mirrors the dynamic platform-matrix pattern used in `image.debian`/`image.alpine`. In `chain`, both `build-link-1` and `build-link-2` reuse the single matrix resolved in `resolve-version` rather than re-inspecting their own (internally-published) parent image.
- **OCI labels:** `version` (the resolved release version), `source`, `title`, `description`, `licenses`, `authors`. Images that extend another image also carry `base.name`.

## Registries

| Registry | Repository |
|---|---|
| GHCR | `ghcr.io/its-me/workflow` |
| Docker Hub | `hub.docker.com/r/1tsme/workflow` |
| Quay.io | `quay.io/repository/itsme/workflow` |

## Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `HUB_USERNAME` | build workflows, descriptions | Docker Hub username |
| `HUB_TOKEN` | workflow, chain, simple | Docker Hub access token for registry push |
| `HUB_PASSWORD` | descriptions | Docker Hub account password for REST API login |
| `QUAY_USERNAME` | build workflows, descriptions | Quay.io robot account username |
| `QUAY_TOKEN` | workflow, chain, simple | Quay.io robot account token for registry push |
| `QUAY_API_TOKEN` | descriptions | Quay.io OAuth application token for REST API |
