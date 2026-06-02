# bonds

Kubernetes CronJob that backs up Persistent Volume Claims to S3-compatible storage using [restic](https://restic.net/).

## How it works

A lightweight Alpine-based container runs `restic` to snapshot a mounted volume, prune old snapshots according to the retention policy, and print a summary. It is designed to be deployed as a Kubernetes `CronJob` that mounts a PVC read-only.

## Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `RESTIC_REPOSITORY` | yes | — | Restic repository URL (e.g. `s3:https://…/bucket`) |
| `RESTIC_PASSWORD` | yes | — | Encryption password for the repository |
| `AWS_ACCESS_KEY_ID` | yes | — | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | yes | — | S3 secret key |
| `BACKUP_PATH` | no | `/data` | Path inside the container to back up |
| `BACKUP_TAG` | no | `bonds` | Restic tag applied to each snapshot |
| `RETENTION_KEEP_LAST` | no | `7` | Number of snapshots to keep |

## Kubernetes deployment

A ready-to-use manifest is provided in [`cronjob.yaml`](cronjob.yaml). It includes a `Secret` and a `CronJob` that runs daily at 02:00.

1. Edit the manifest and replace the placeholder values (`changeme`, `my-namespace`, `my-pvc`, `my-bucket`).
2. Apply it:

```sh
kubectl apply -f cronjob.yaml
```

## Docker image

The image is published to the GitHub Container Registry on every release:

```
ghcr.io/dwesh163/bonds:latest
ghcr.io/dwesh163/bonds:<version>
```

To build locally:

```sh
docker build -t bonds .
```

## Versioning

The version is read from the `.version` file. Bumping it and merging to `main` triggers a new GitHub release and pushes a tagged image to GHCR.
