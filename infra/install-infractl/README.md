# Install `infractl`

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

This action doesn't require any options.

## Usage

```yaml
name: Install `infractl`

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/infra/install-infractl@main
    - run: infractl version >> "$GITHUB_STEP_SUMMARY"
```
