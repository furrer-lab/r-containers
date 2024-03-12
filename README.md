# r-containers

This is a selection of Docker container that provide r-environments for testing purposes.

## Configuration

### Releasing new versions

New registry entries are triggered by tagging the specific commit.
For the image to be built the tag needs to be a valid
[semver](https://semver.org/), i.e. of the form `[MAJOR].[MINOR].[PATCH]`
(e.g. `1.3.0`).
In this particular case we use [calver](https://calver.org/) which is a semver
compatible versioning that uses the release date in the version string:
`year.month.release# in this month`, so `2024.3.2` is the 2nd release in
March 2024.

### Triggering new releases

We should regularly build new containers as (some of) the dependencies they
install will be updated.
However, since we want to create containers that reflect typical R
environments, building new containers does not need to target the nightly
builds of all dependencies.
Therefore, we do not need to rebuild the containers daily or even weekly.

Instead, the containers undergo a scheduled monthly upgrade, in combination
with an upgrade of the latest version whenever we have code changes in the
default branch.
