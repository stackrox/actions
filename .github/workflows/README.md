# Workflows

## Create demo clusters for version

### All options

| Input                                       | Description                                | Default        |
| ------------------------------------------- | ------------------------------------------ | -------------- |
| [version](#version)                         | Main image version                         |                |
| [create-k8s-cluster](#create-k8s-cluster)   | Whether to create GKE cluster              | `"false"`      |
| [create-os4-cluster](#create-os4-cluster)   | Whether to create Open Shift 4 cluster     | `"false"`      |
| [create-long-cluster](#create-long-cluster) | Whether to create GKE long-running cluster | `"false"`      |
| [dry-run](#dry-run)                         | Whether it is a dry-run                    | `"false"`      |
| [workflow-ref](#workflow-ref)                         | Reference of the called workflow                    |       |

### Detailed options

#### version

Default value: unset

#### create-k8s-cluster

Default value: `false`

#### create-os4-cluster

Default value: `false`

#### create-long-cluster

Default value: `false`

#### dry-run

Default value: `false`

#### workflow-ref

Default value: unset

Must match the reference of the workflow in the `uses` keyword.

### Usage

```yaml
name: Create demo clusters for release candidate
jobs:
  create-clusters:
    name: Setup clusters
    uses: stackrox/actions/.github/workflows/create-cluster.yml@v1
    secrets: inherit
    with:
      version: ${{github.event.inputs.version}}
      create-k8s-cluster: ${{github.event.inputs.create-k8s-cluster == 'true'}}
      create-os4-cluster: ${{github.event.inputs.create-os4-cluster == 'true'}}
      create-long-cluster: ${{github.event.inputs.create-long-cluster == 'true'}}
      dry-run: ${{github.event.inputs.dry-run == 'true'}}
      workflow-ref: v1
```
