# Move a tag to a new position

## Recommended permissions

The action requires a permission to push to the branch.

```yaml
permissions:
  id-token: write
```

## All options

| Input                       | Description                  | Default        |
| --------------------------- | ---------------------------- | -------------- |
| [sliding-tag](#sliding-tag) | Tag to move                  |                |
| [ref-name](#ref-name)       | Reference to move the tag to |                |
| [token](#token)             | Github token                 | `github.token` |
| [dry-run](#dry-run)         | Whether it is a dry-run      | `"false"`      |

### Detailed options

#### sliding-tag

Sliding tag that is moved to a new position.

Default value: unset

#### ref-name

Name of the reference where the sliding tag should point. This might be another tag, branch name or commit hash.

Example: `"v1.0.1"`

Default value: unset

#### token

GitHub token.

Default value: `github.token`

#### dry-run

Whether it is a dry-run. The action won't push the sliding tag if `dry-run` is set to `"true"`.

Default value: `"false"`

## Usage

The action requires the repository to be checked out.

```yaml
name: Move the v1 tag to v1.0.1

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        repository: stackrox/stackrox
        fetch-depth: 0
    - uses: stackrox/actions/release/move-tag@main
      with:
        sliding-tag: v1
        ref-name: v1.0.1
        token: "${{ secrets.ROX_GITHUB_TOKEN }}
```
