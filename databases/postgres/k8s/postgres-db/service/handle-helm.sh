#!/bin/bash
export WORKING_DIRECTORY_ORIGINAL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORKING_DIRECTORY_ORIGINAL

# Check if Helm is installed, install if not
if ! command -v helm &> /dev/null; then
    echo "Helm not found. Installing Helm on Alpine Linux..."
    apk add --no-cache curl
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    echo "Helm installation completed."
fi

source ./project.sh
echo "Starting helm installation for db: $PROJECT"
# Add Bitnami Helm repo if not already added
echo "Updating helm for db: $PROJECT"

helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update bitnami

# Get parameters
USAGE_TYPE=$ACTION_PARAMETERS_USAGE_TYPE
PII_ENABLED=${ACTION_PARAMETERS_PII:-false}
DB_NAME="${USAGE_TYPE:-app}_db"

# Generate random password for PostgreSQL superuser
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "Create secret for db: $PROJECT"
# Create secret with database credentials
kubectl create secret generic $PROJECT-postgres-credentials \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=username=postgres \
  --from-literal=password="$POSTGRES_PASSWORD" \
  --from-literal=database="$DB_NAME" \
  -n postgres-db \
  --dry-run=client -o yaml | kubectl apply -f -

echo '{"projectName":"'"$PROJECT"'","usageType":"'"$USAGE_TYPE"'","piiEnabled":'"$PII_ENABLED"',"dbName":"'"$DB_NAME"'","postgresPassword":"'"$POSTGRES_PASSWORD"'"}' > /tmp/context-$PROJECT.json

gomplate \
  --context .=/tmp/context-$PROJECT.json \
  -f values.yaml.tpl > /tmp/values-$PROJECT.yaml


#releases=$(helm list -n postgres-db --short)
#if [ -n "$releases" ]; then
#  echo "$releases" | xargs -n1 helm uninstall -n postgres-db
#else
#  echo "No hay releases en el namespace postgres-db"
#fi


echo "Installing chart: $PROJECT"
# Install using Bitnami PostgreSQL chart
helm upgrade --install -n postgres-db $PROJECT-postgres bitnami/postgresql -f /tmp/values-$PROJECT.yaml --create-namespace --wait > /dev/null