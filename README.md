# r-containers

Pre-configured Docker containers with R, JAGS, INLA, and all dependencies needed to work with the [`abn`](https://github.com/furrer-lab/abn) R package.
The containers eliminate the need to manually install system libraries and R packages — pull an image and start working immediately.

The containers also serve as the CI/CD infrastructure for `abn`, providing reproducible environments for CRAN-style checks and memory diagnostics across multiple compilers and R versions.

## Getting started

The recommended container for general use is `debian-gcc-release`, which ships with the current stable R release:

```bash
docker pull ghcr.io/furrer-lab/r-containers/debian-gcc-release/abn:latest
```

### Interactive R session

```bash
docker run --rm -it ghcr.io/furrer-lab/r-containers/debian-gcc-release/abn:latest R
```

### Working on a local project

Mount your working directory into the container to use `abn` and all its dependencies on your own scripts and data:

```bash
docker run --rm -it -v "$(pwd)":/work -w /work \
  ghcr.io/furrer-lab/r-containers/debian-gcc-release/abn:latest R
```

Inside R, all dependencies are available out of the box:

```r
library(abn)       # ready to use
library(rjags)     # JAGS interface
library(INLA)      # INLA
library(glmmTMB)   # glmmTMB (debian containers)
```

### Running as non-root

CI jobs run the containers with `--user 1001`.
All packages are installed into the system-wide R library, so they work regardless of which user runs the container:

```bash
docker run --rm -it --user 1001 \
  ghcr.io/furrer-lab/r-containers/debian-gcc-release/abn:latest R
```

## Container variants

This repository wraps a selected set of [R-hub base images](https://r-hub.github.io/containers/containers.html) with the system libraries and R packages needed by `abn`. The R-hub image is the build and runtime foundation; the images published by this repository are derived images and are not aliases for the R-hub images.

| Published variant | R-hub base image | OS | Compiler | R version | JAGS | Notes |
|-----------|------------|----|----------|-----------|------|-------|
| `debian-clang-devel` | `ghcr.io/r-hub/containers/ubuntu-clang:latest` | Ubuntu | clang | development | system package | |
| `debian-gcc-release` | `ghcr.io/r-hub/containers/ubuntu-release:latest` | Ubuntu | gcc | release | system package | recommended for general use |
| `fedora-gcc-devel` | `ghcr.io/r-hub/containers/gcc16:latest` | Fedora | gcc 16 | development | built from source | |
| `fedora-valgrind-gcc-devel` | `ghcr.io/r-hub/containers/valgrind:latest` | Fedora-based Valgrind environment | gcc | development | built from source | includes Valgrind + DrMemory |

The three variants labelled `-devel` use R-hub development images. The
`debian-gcc-release` variant intentionally uses the R-hub release image.

These are the only R-hub bases wrapped and published by this repository. We do
not publish derived images for other R-hub bases, including `ubuntu-gcc16`,
`ubuntu-next`, `ubuntu-gcc12`, or the retired `gcc15` image.

Images are available at:

```
ghcr.io/furrer-lab/r-containers/<variant>/<layer>:<tag>
```

### Published image matrix

The links below point to the corresponding GitHub Container Registry package.
Each variant publishes the seven layers listed below, and all production images
receive both the release tag and `latest`.

| Variant | `syslibs` | `jags` | `inla` | `bioc` | `jags-inla` | `jags-inla-bioc` | `abn` |
|---|---|---|---|---|---|---|---|
| `debian-clang-devel` | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fsyslibs) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fjags) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Finla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fbioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fjags-inla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fjags-inla-bioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-clang-devel%2Fabn) |
| `debian-gcc-release` | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fsyslibs) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fjags) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Finla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fbioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fjags-inla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fjags-inla-bioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Fdebian-gcc-release%2Fabn) |
| `fedora-gcc-devel` | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fsyslibs) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fjags) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Finla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fbioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fjags-inla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fjags-inla-bioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-gcc-devel%2Fabn) |
| `fedora-valgrind-gcc-devel` | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fsyslibs) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fjags) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Finla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fbioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fjags-inla) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fjags-inla-bioc) | [package](https://github.com/furrer-lab/r-containers/pkgs/container/r-containers%2Ffedora-valgrind-gcc-devel%2Fabn) |

For efficiency, images within each variant are based on one another where
possible, allowing Docker and the registry to reuse unchanged layers. The
component images branch from `syslibs`; the stacked images extend the JAGS
lineage through `jags-inla`, `jags-inla-bioc`, and finally `abn`.

## Pre-installed R packages

Every container includes these packages installed into the base R library (`.Library`):

**Bayesian / statistical modelling:** rjags, glmmTMB (debian only), INLA

**Bioconductor:** BiocManager, Rgraphviz

**Development tooling:** devtools, remotes, R.rsp, renv, desc, urlchecker

**Code coverage:** covr, DT, htmltools

**Target package dependencies:** all remaining dependencies of `abn` are resolved automatically by cloning the repo and scanning the `DESCRIPTION` file during the build.

## CI/CD pipeline

### Automated builds (`create-publish-docker.yml`)

Containers are rebuilt automatically on two triggers:

- **Push to `main`** — every merge to the default branch triggers a full rebuild
- **Monthly schedule** — runs at 02:12 UTC on the 2nd of every month

The pipeline has four stages:

1. **`increment-tag`** — generates a [calver](https://calver.org/) version tag (`YYYY.MM.N`, e.g., `2025.4.1`)
2. **Layered build jobs** — build and push the four container variants and their component/stacked images to GHCR
3. **`check-images`** — probes the registry to determine which final images were successfully pushed
4. **`container-integrity-and-config`** — pulls each available image, runs it as `--user 1001`, generates `sessionInfo()` and installed-package reports, and commits the results to the `info/` directory

### PR checks (`onlabel_check_build.yml`)

When a pull request is labelled `build::check`, all container variants are built (but not pushed to the registry).
The workflow updates the PR label to `build::passed` or `build::failed` based on the outcome.

### Versioning

New container versions are tagged automatically using [calver](https://calver.org/) — a semver-compatible scheme that encodes the release date: `YYYY.MM.N` where `N` is the release number within that month.
For example, `2025.4.2` is the 2nd release in April 2025.
Every build publishes containers with both the versioned tag and `latest`.

## Repository structure

```
r-containers/
├── .github/workflows/
│   ├── create-publish-docker.yml   # Main CI: build, push, and verify containers
│   └── onlabel_check_build.yml     # PR check: build containers on label trigger
├── containers/
│   ├── debian/Dockerfile.abn       # Final Debian/Ubuntu image
│   ├── debian/Dockerfile.syslibs   # Common Debian/Ubuntu system base
│   ├── debian/Dockerfile.jags      # Reusable JAGS/rjags image
│   ├── debian/Dockerfile.inla      # Reusable INLA image
│   ├── debian/Dockerfile.bioc      # Reusable Bioconductor image
│   ├── debian/Dockerfile.jags-inla      # Stacked JAGS + INLA image
│   └── debian/Dockerfile.jags-inla-bioc # Stacked JAGS + INLA + Bioconductor image
│   ├── fedora/                     # Fedora component and stacked Dockerfiles
│   ├── valgrind/                   # Fedora-based Valgrind component and stacked Dockerfiles
│   ├── shared/                     # Shared INLA, Bioconductor, and tooling installers
│   └── test/Dockerfile             # Minimal test Dockerfile
├── src/
│   └── release_info.tpl            # knitr template for container info reports
├── info/                           # Generated container configuration reports
├── .chglog/                        # git-chglog configuration
├── CHANGELOG.md                    # Auto-generated changelog
└── shell.nix                       # Nix shell providing podman for local builds
```

### Dockerfile architecture

Each variant publishes reusable component images and a stacked build chain:

```text
syslibs
├── jags
├── inla
└── bioc

jags -> jags-inla -> jags-inla-bioc -> abn
```

The published image names are:

```text
<variant>/syslibs:<tag>
<variant>/jags:<tag>
<variant>/inla:<tag>
<variant>/bioc:<tag>
<variant>/jags-inla:<tag>
<variant>/jags-inla-bioc:<tag>
<variant>/abn:<tag>
```

The `jags`, `inla`, and `bioc` images are independent reusable components based
on `syslibs`. The `jags-inla` and `jags-inla-bioc` images are stacked build
bases containing all components required by the final `abn` image. For
efficiency, these images are based on one another so Docker and the registry
can reuse unchanged layers.

All production images are published with both the version tag and `latest`.

Each Dockerfile configures `R_LIBS_USER=" "` to disable the user library
fallback, prevents renv auto-activation, configures a CRAN mirror, and installs
its layer-specific packages into `.Library`.

### Why `R_LIBS_USER=" "` and `lib=.Library`?

The R-hub base images create a root-owned user library at `/root/R/...`.
Without intervention, `install.packages()` defaults to that location.
When the container runs with `--user 1001`, that user cannot see `/root/R/...`, so all installed packages would be invisible.
Setting `R_LIBS_USER` to a single space disables the user library fallback, and every `install.packages()` call explicitly targets `lib=.Library` (e.g., `/opt/R/4.5.3/lib/R/library/`) to ensure packages are accessible to all users.

## Configuration variables

The following GitHub Actions repository variables are used:

| Variable | Description |
|----------|-------------|
| `DOCKER_REGISTRY` | Container registry URL (e.g., `ghcr.io`) |
| `REPO_PATH` | GitHub path to the target R package (e.g., `github.com/furrer-lab/abn`) |
| `PACKAGE_PATH` | Path to the DESCRIPTION file within the repo (default: `./`) |
| `JAGS` | JAGS source tarball name for fedora/valgrind builds |
| `DRMEMORY` | DrMemory version for the valgrind container |
| `CHGLOG_RELEASE` | git-chglog release version |
| `CHGLOG_PATH` | git-chglog binary path |

## License

GPL-3.0 — see [LICENSE](LICENSE).
