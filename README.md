# Image Workflow

Template repository demonstrating a multi-arch Docker image CI/CD workflow with GitHub Actions.

## Workflow

- A daily check for new releases of [its-me/dummy.releases](https://github.com/its-me/dummy.releases) tags this repo and triggers all builds below
- Every build is tied to a `v*` semver tag (or a manual dispatch naming one) — no build-only/test runs on ordinary pushes or PRs
- `build-and-deploy` and `chain` support 8 platforms: `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`, `linux/386`, `linux/ppc64le`, `linux/s390x`, `linux/riscv64`; `simple` supports `linux/amd64` only

## Images

| Tag | Description |
|---|---|
| `X.Y.Z` | Standalone single-stage image, built from busybox |
| `latest` | Latest standalone single-stage image |
| `chain-link-1-X.Y.Z` | First link of a multi-stage chain, extends the single-stage image |
| `chain-link-1` | Latest first-link image |
| `chain-link-2-X.Y.Z` | Second link, extends `chain-link-1` |
| `chain-link-2` | Latest second-link image |
| `simple-X.Y.Z` | Minimal single-platform build, extends the single-stage image |
| `simple` | Latest single-platform image |

## Registries

| Registry | Repository |
|---|---|
| GitHub Container Registry | [ghcr.io/its-me/workflow](https://ghcr.io/its-me/workflow) |
| Docker Hub | [hub.docker.com/r/1tsme/workflow](https://hub.docker.com/r/1tsme/workflow) |
| Quay.io | [quay.io/repository/itsme/workflow](https://quay.io/repository/itsme/workflow) |

## License

[MIT](LICENSE)
