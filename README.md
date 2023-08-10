# Various GitHub Actions

* [Infra / Create Cluster](infra/create-cluster/README.md)
* [Infra / Install `infractl`](infra/install-infractl/README.md)
* [Release / Wait for Image](release/wait-for-image/README.md)
* [Release / Tag](release/tag/README.md)
* [Test](test/README.md)

## Workflows

* [`create-rc-clusters`](.github/workflows/README.md)

## Usage

As this is an internal repository, it can be accessed with the default GitHub
token from any repository workflow under stackrox organization.

Example:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/test@main
```

## Testing in local

One may execute the scripts from the repository locally via `test/local-env.sh`,
e.g.:

```sh
$ test/local-env.sh test/test.sh arg1 arg2
::notice::Test script called on ref main
Test script arguments:
* `arg1`
* `arg2`
```

## Versioning

If you publish a new action or make another change that warrants a new release of this repository, create and push a new tag following SemVer.

```bash
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

A Github action will create a short version, in this example `v1`, or move the `v1` tag to your new tag.
