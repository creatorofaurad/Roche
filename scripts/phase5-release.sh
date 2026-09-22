#!/usr/bin/env bash
# scripts/phase5-release.sh: GitHub Release Publication
set -euo pipefail

echo "============================================================"
echo "ROCHE v1.5.0 :: PHASE 5 - GITHUB RELEASE PUBLICATION"
echo "============================================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TAG_NAME="v1.5.0"
RELEASE_TITLE="Roche v1.5.0: Production-Ready EVM Invariant Engine"
NOTES_FILE="RELEASE_NOTES.md"
ARCHIVE_PATH="./dist/roche-v1.5.0-x86_64.tar.gz"
CHECKSUM_FILE="roche.sha256"

if [ ! -f "$NOTES_FILE" ]; then
    echo "[-] ERROR: Missing $NOTES_FILE" >&2
    exit 1
fi

echo "[1/3] Checking available GitHub publishing interfaces..."
if command -v gh >/dev/null 2>&1; then
    echo "[+] Found GitHub CLI ('gh'). Initiating release creation via gh..."
    
    # Check if release already exists
    if gh release view "$TAG_NAME" >/dev/null 2>&1; then
        echo "[!] Release $TAG_NAME already exists on GitHub. Uploading missing assets..."
        if [ -f "$ARCHIVE_PATH" ]; then
            gh release upload "$TAG_NAME" "$ARCHIVE_PATH" --clobber
        fi
        if [ -f "$CHECKSUM_FILE" ]; then
            gh release upload "$TAG_NAME" "$CHECKSUM_FILE" --clobber
        fi
    else
        echo "[+] Creating new release on GitHub..."
        gh release create "$TAG_NAME" \
            --title "$RELEASE_TITLE" \
            --notes-file "$NOTES_FILE" \
            "$ARCHIVE_PATH" \
            "$CHECKSUM_FILE"
    fi
    echo "[+] Release published successfully: https://github.com/creatorofaurad/Roche/releases/tag/$TAG_NAME"

elif [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "[+] Using GITHUB_TOKEN environment variable with curl API..."
    REPO="creatorofaurad/Roche"
    BODY_CONTENT=$(cat "$NOTES_FILE" | jq -s -R .)
    
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO/releases" \
        -d "{
            \"tag_name\": \"$TAG_NAME\",
            \"target_commitish\": \"main\",
            \"name\": \"$RELEASE_TITLE\",
            \"body\": $BODY_CONTENT,
            \"draft\": false,
            \"prerelease\": false
        }")
    
    echo "[+] API Response:"
    echo "$RESPONSE" | grep -E '"html_url"|"id"|"tag_name"' || echo "$RESPONSE"

else
    echo "[-] NOTICE: Neither 'gh' CLI nor 'GITHUB_TOKEN' is configured in the environment."
    echo "[*] To publish manually, run:"
    echo "    gh release create $TAG_NAME --title '$RELEASE_TITLE' --notes-file $NOTES_FILE $ARCHIVE_PATH $CHECKSUM_FILE"
    echo "    OR navigate to: https://github.com/creatorofaurad/Roche/releases/new"
fi

echo "============================================================"
echo "[+] PHASE 5 COMPLETE: Release publication workflow executed."
echo "============================================================"
