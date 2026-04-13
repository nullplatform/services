#!/bin/bash

# Ensure curl is available (needed for binary downloads)
if ! command -v curl &>/dev/null; then
    apk add --no-cache curl
fi

# Ensure openssl is installed (used for password generation)
if ! command -v openssl &>/dev/null; then
    apk add --no-cache openssl
fi

# Ensure jq is installed (used for JSON processing)
if ! command -v jq &>/dev/null; then
    apk add --no-cache jq
fi

# Ensure kubectl is installed
if ! command -v kubectl &>/dev/null; then
    apk add --no-cache kubectl 2>/dev/null || {
        KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
        curl -fsSL -o /usr/local/bin/kubectl \
            "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        chmod +x /usr/local/bin/kubectl
    }
fi

# Ensure helm is installed
if ! command -v helm &>/dev/null; then
    apk add --no-cache helm 2>/dev/null || {
        HELM_VERSION="v3.17.3"
        curl -fsSL -o /tmp/helm.tar.gz \
            "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
        tar -xzf /tmp/helm.tar.gz -C /tmp
        mv /tmp/linux-amd64/helm /usr/local/bin/helm
        chmod +x /usr/local/bin/helm
        rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
    }
fi

# Ensure gomplate is installed (not available in apk repos)
if ! command -v gomplate &>/dev/null; then
    GOMPLATE_VERSION="v3.11.7"
    curl -fsSL -o /usr/local/bin/gomplate \
        "https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64"
    chmod +x /usr/local/bin/gomplate
fi
