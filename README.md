# Various GitHub Actions

## How to use

As this is an internal repository, it can be accessed with the default GitHub
token from any repository workflow under stackrox organization.

Example: create a `qa-demo` cluster.

```yaml
jobs:
  infra:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/infra/create-cluster@main
      with:
        token: ${{ secrets.INFRA_TOKEN }}
        flavor: qa-demo
        name: qa-demo-test-cluster
        lifespan: 48h
        args: main-image=quay.io/rhacs-eng/main:3.75.4
        wait: "false"
```

## Testing

### Test action

Test action may be used to call any script from the repository as an action:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/test@main
      with:
        script: test/test.sh # the script to run
        args: '[ "arg1", "arg2" ]' # JSON array of arguments in a string
```

### Local run

One may execute the scripts from the repository locally via `test/local-env.sh`,
e.g.:

```sh
$ test/local-env.sh test/test.sh arg1 arg2
::notice::Test script called on ref main
Test script arguments:
* `arg1`
* `arg2`
```
