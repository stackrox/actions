# Various GitHub Actions

* [Infra / Create Cluster](infra/create-cluster/README.md)
* [Release / Wait for Image](release/wait-for-image/README.md)
* [Test](test/README.md)

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
