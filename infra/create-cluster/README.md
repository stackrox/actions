# Create Cluster

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

| Input                 | Description                               | Default   |
| ----------------------| ------------------------------------------| --------- |
| [token](#token)       | Infra token                               |           |
| [flavor](#flavor)     | Cluster flavor                            |           |
| [name](#name)         | Cluster name                              |           |
| [lifespan](#lifespan) | Lifespan                                  | `48h`     |
| [args](#args)         | Arguments                                 |           |
| [wait](#wait)         | Whether to wait for the cluster readiness | `'false'` |

### Detailed options

#### token

Default value: unset

#### flavor

Default value: unset

#### name

Default value: unset

Must comply to the regex: `[a-z][a-z0-9-]{1,26}[a-z0-9]`.

#### lifespan

Default value: `48h`

#### args

Default value: unset

#### wait

Default value: `'false'`

## Usage

```yaml
name: Create a qa-demo cluster with 48h lifespan

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
