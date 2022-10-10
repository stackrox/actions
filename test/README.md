# Test action

## Recommended permissions

The action itself doesn't require any specific permission, but it may call a
script from the repository, which might require some. Please check the according
documentation.

```yaml
permissions: {}
```

## All options

| Input             | Description                                     | Default        |
| ----------------- | ----------------------------------------------- | -------------- |
| [script](#script) | Script name with path relative to the repo root | `test/test.sh` |
| [args](#args)     | A string with JSON array with script arguments  |                |

### Detailed options

#### script

The name of the script with the path, relative to the root of the repository,
e.g. `infra/create-cluster/create-cluster.sh`.

Default value: `test/test.sh`

#### args

A string with JSON array with script arguments.
Example: `'[ "arg1", "arg2" ]'`

Default value: unset

## Usage

```yaml
name: Call test script with a couple of arguments

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/test@main
      with:
        script: test/test.sh
        args: '[ "arg1", "arg2" ]'
```
