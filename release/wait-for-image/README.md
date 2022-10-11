# Wait for image tag on [Quay.io](quay.io)

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

| Input                 | Description                                                          | Default  |
| --------------------- | -------------------------------------------------------------------- | -------- |
| [token](#token)       | [Quay.io](quay.io) authorization token                               |          |
| [image](#image)       | Image name with the tag                                              |          |
| [interval](#interval) | Time interval in seconds with which to check for the image tag       | `"30"`   |
| [limit](#limit)       | Polling time limit in seconds after which to fail if no image found  | `"2400"` |

### Detailed options

#### token

Authorization token for accessing [Quay.io](quay.io) API.

Default value: unset

#### image

Image name with the tag.

Example: `"rhacs-eng/main:3.76.1"`

Default value: unset

#### interval

Time interval in seconds with which to check for the image tag.

Default value: `"30"`

#### limit

Polling time limit in seconds after which to fail if no image found.

Default value: `"2400"`

## Usage

```yaml
name: Wait for main:3.72.3 to appear on Quay.io

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/release/wait-for-image@main
      with:
        token: ${{ secrets.QUAY_BEARER_TOKEN }}
        image: rhacs-eng/main:3.75.3
```
