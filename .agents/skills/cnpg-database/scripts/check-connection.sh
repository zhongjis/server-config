#!/usr/bin/env bash
# check-connection.sh - Read-only CNPG/app DB readiness checks for server-config.
# Usage: check-connection.sh <app-namespace> [cluster-name]

set -euo pipefail

APP_NS="${1:?Usage: check-connection.sh <app-namespace> [cluster-name]}"
CLUSTER_NAME="${2:-${APP_NS}-cnpg-cluster}"
SECRET_NAME="${CLUSTER_NAME}-app"

printf '=== Flux HelmRelease ===\n'
flux get helmrelease "${CLUSTER_NAME}" -n "${APP_NS}" || true

printf '\n=== CNPG Cluster ===\n'
kubectl get clusters.postgresql.cnpg.io "${CLUSTER_NAME}" -n "${APP_NS}"

printf '\n=== CNPG Cluster Conditions ===\n'
kubectl get clusters.postgresql.cnpg.io "${CLUSTER_NAME}" -n "${APP_NS}" \
  -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" reason="}{.reason}{"\n"}{end}'
printf '\n'

printf '\n=== CNPG Pods ===\n'
kubectl get pods -n "${APP_NS}" -l "cnpg.io/cluster=${CLUSTER_NAME}" -o wide

printf '\n=== Generated App Secret ===\n'
kubectl get secret "${SECRET_NAME}" -n "${APP_NS}"

printf '\n=== Optional manual connection test ===\n'
printf 'kubectl run -n %s pg-test --rm -it --image=postgres:17 -- psql "postgresql://<user>:[REDACTED]@<host>:<port>/<dbname>"\n' "${APP_NS}"
