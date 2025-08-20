#!/usr/bin/env bash

VERSION="${1:-1.11.0}"
URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"

HASH=$(nix-prefetch-url --type sha256 "$URL" 2>/dev/null)

if [ $? -eq 0 ]; then
    # Convertir en SRI
    SRI_HASH=$(nix hash convert --hash-algo sha256 "$HASH")
    echo "${VERSION}:${SRI_HASH}"
else
    echo "❌ Erreur lors du téléchargement"
    exit 1
fi
