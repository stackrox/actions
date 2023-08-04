# Create Clusters

## Recommended permissions

The action requires ...

```yaml
permissions:
  id-token: write
```

## All options

| Input                                       | Description                                | Default        |
| ------------------------------------------- | ------------------------------------------ | -------------- |
| [version](#version)                         | Main image version                         |                |
| [create-k8s-cluster](#create-k8s-cluster)   | Whether to create GKE cluster              | `"false"`      |
| [create-os4-cluster](#create-os4-cluster)   | Whether to create Open Shift 4 cluster     | `"false"`      |
| [create-long-cluster](#create-long-cluster) | Whether to create GKE long-running cluster | `"false"`      |
| [dry-run](#dry-run)                         | Whether it is a dry-run                    | `"false"`      |

### Detailed options

#### Version

#### create-k8s-cluster

#### create-os4-cluster

#### create-long-cluster

## Usage

The action requires the repository to be checked out.

```yaml
name: Create demo clusters

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        repository: stackrox/stackrox
        fetch-depth: 0
    - uses: stackrox/actions/release/create-clusters@main
      with:
        version: 4.3.2-rc.1
        create-k8s-cluster: "true"
        create-os4-cluster: "true"
        create-long-cluster: "true"
        token: "${{ secrets.ROX_GITHUB_TOKEN }}
```
