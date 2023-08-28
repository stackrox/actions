# Retags and pushes an image. Optionally logs into the registry first

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

| Input                    | Description                                                          | Default  |
| -------------------------| -------------------------------------------------------------------- | -------- |
| [src-image](#src-image)  | The name of the original image                                       |          |
| [dst-image](#dst-image)  | Where the image is pushed to                                         |          |
| [username](#username)    | The docker registry username                                         |          |
| [password](#password)    | The docker registry password                                         |          |

### Detailed options

#### src-image

The original image name with the tag.

Example: `"quay.io/rhacs-eng/main:3.76.1"`

Default value: unset

#### dst-image

The destination image name with the tag.

Example: `"quay.io/stackrox-io/main:3.76.1"`

Default value: unset

### username

The docker registry username

Example: `"employee"`

Default value: unset

### password

The docker registry password

Example: `"12345"`

Default value: uset

## Usage

```yaml
name: Push image to quay.io/stackrox-io

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/images/retag-and-push@main
      with:
        src-image: rhacs-eng/main:4.1.0
        dst-image: quay.io/rhacs-eng/main:4.1.0
        username: ${{ secrets.QUAY_STACKROX_IO_RW_USERNAME }}
        password: ${{ secrets.QUAY_STACKROX_IO_RW_PASSWORD }}
```
