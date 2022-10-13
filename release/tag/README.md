# Tag current branch

## Recommended permissions

The action requires a permission to push to the branch.

```yaml
permissions:
  id-token: write
```

## All options

| Input               | Description             | Default        |
| ------------------- | ----------------------- | -------------- |
| [token](#token)     | GitHub token            | `github.token` |
| [tag](#tag)         | Tag                     |                |
| [dry-run](#dry-run) | Whether it is a dry-run | `"false"`      |

### Detailed options

#### token

GitHub token.

Default value: unset

#### tag

Tag to be set on the empty commit.

Example: `"3.76.1"`

Default value: unset

#### dry-run

Whether it is a dry-run. The action won't push to the branch if `dry-run` is set to `"true"`.

Default value: `"false"`

## Usage

```yaml
name: Tag the branch as 3.72.3

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/release/tag@main
      with:
        tag: 3.72.3
```
