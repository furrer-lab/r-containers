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

All containers are built on top of [R-hub base images](https://r-hub.github.io/containers/containers.html) and published to the GitHub Container Registry (GHCR).

| Container | Base image | OS | Compiler | R version | JAGS | Notes |
|-----------|------------|----|----------|-----------|------|-------|
| `debian-clang-devel` | `rhub/ubuntu-clang` | Ubuntu 22.04 | clang | devel | system package | |
| `debian-gcc-devel` | `rhub/ubuntu-gcc12` | Ubuntu 22.04 | gcc 12 | devel | system package | |
| `debian-gcc-release` | `rhub/ubuntu-release` | Ubuntu 24.04 | gcc | release | system package | recommended for general use |
| `debian-gcc-patched` | `rhub/ubuntu-next` | Ubuntu 22.04 | gcc | patched | system package | |
| `fedora-gcc-devel` | `rhub/gcc15` | Fedora | gcc 15 | devel | built from source | allow-failure |
| `fedora-gcc16-devel` | `rhub/gcc16` | Fedora | gcc 16 | devel | built from source | allow-failure |
| `valgrind-gcc-devel` | `rhub/valgrind` | Fedora | gcc | devel | built from source | includes valgrind + DrMemory |

Images are available at:

```
ghcr.io/furrer-lab/r-containers/<container>/abn:<tag>
```

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
2. **`build-and-push`** — builds all 7 container variants in parallel and pushes to GHCR
3. **`check-images`** — probes the registry to determine which images were successfully pushed (handles `allow-failure` containers gracefully)
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
│   ├── debian/Dockerfile           # Debian/Ubuntu containers (apt-get, system JAGS)
│   ├── fedora/Dockerfile           # Fedora containers (dnf, JAGS from source)
│   ├── valgrind/Dockerfile         # Valgrind container (Fedora + valgrind + DrMemory)
│   ├── shared/install_r_packages.sh  # Common R package installation (used by all)
│   └── test/Dockerfile             # Minimal test Dockerfile
├── src/
│   └── release_info.tpl            # knitr template for container info reports
├── info/                           # Generated container configuration reports
├── .chglog/                        # git-chglog configuration
├── CHANGELOG.md                    # Auto-generated changelog
└── shell.nix                       # Nix shell providing podman for local builds
```

### Dockerfile architecture

Each Dockerfile follows the same pattern:

1. Start `FROM rhub/<base-image>` (parameterised via `RHUB_IMAGE` build arg)
2. Install OS-level system libraries (compilers, dev headers, JAGS dependencies)
3. Set `ENV R_LIBS_USER=" "` to disable the user library fallback
4. Set `ENV RENV_CONFIG_AUTOLOADER_ENABLED=false` to prevent renv auto-activation
5. Configure a CRAN mirror in the R profile
6. Install JAGS — via `apt-get` on debian, built from source on fedora/valgrind
7. Install container-specific R packages (rjags, glmmTMB)
8. Run `shared/install_r_packages.sh` for all common R packages
9. Verify all key packages are loadable (build fails if any are missing)

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
| `CONTAINER_SOURCE` | Registry path prefix for pulling images in integrity checks |

## License

GPL-3.0 — see [LICENSE](LICENSE).
