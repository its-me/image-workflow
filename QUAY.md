# Image Workflow

Template repository demonstrating a multi-arch Docker image CI/CD workflow with GitHub Actions.

Source: [github.com/its-me/image-workflow](https://github.com/its-me/image-workflow)

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

## Platforms

`X.Y.Z`, `latest`, `chain-*`: `linux/amd64` · `linux/arm64` · `linux/arm/v7` · `linux/arm/v6` · `linux/386` · `linux/ppc64le` · `linux/s390x` · `linux/riscv64`

`simple*`: `linux/amd64` only

## Registries

- [GitHub Container Registry](https://ghcr.io/its-me/workflow)
- [Docker Hub](https://hub.docker.com/r/1tsme/workflow)
- [Quay.io](https://quay.io/repository/itsme/workflow)
