#!/bin/bash

# DaemonStraight Signing Certificate Script
# Creates the self-signed certificate that release builds are signed with. Run it only once:
# macOS ties the Accessibility permission to the certificate, so with a new one
# everybody has to grant the permission again after updating.
#
# Usage: ./scripts/create_signing_certificate.sh <backup-folder-outside-the-repository>
#
# The private key is imported into the login keychain and saved as a password-protected
# .p12 file in the backup folder. The password is kept in the login keychain as well.

set -e  # Exit on error

IDENTITY="DaemonStraight Self-Signed"
PASSWORD_SERVICE="DaemonStraight signing certificate backup"
VALID_DAYS=7300

fail() { echo "❌ $1"; exit 1; }

BACKUP_DIR="$1"
[ -n "$BACKUP_DIR" ] || fail "Usage: $0 <backup-folder-outside-the-repository>"
mkdir -p "$BACKUP_DIR"
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$BACKUP_DIR/" in "$REPO_ROOT"/*) fail "The backup folder must be outside the repository" ;; esac

BACKUP="$BACKUP_DIR/DaemonStraight-signing.p12"
security find-certificate -c "$IDENTITY" >/dev/null 2>&1 && fail "\"$IDENTITY\" is already in the keychain"
[ ! -e "$BACKUP" ] || fail "$BACKUP already exists"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/cert.conf" <<CONF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $IDENTITY
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
CONF

# The system OpenSSL writes .p12 files that the security tool can import
export P12_PASSWORD="$(/usr/bin/openssl rand -base64 32)"
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days "$VALID_DAYS" -config "$WORK/cert.conf" \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" 2>/dev/null
(umask 077 && /usr/bin/openssl pkcs12 -export -name "$IDENTITY" -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -passout env:P12_PASSWORD -out "$BACKUP")

security add-generic-password -a "$USER" -s "$PASSWORD_SERVICE" -w "$P12_PASSWORD"
security import "$BACKUP" -f pkcs12 -P "$P12_PASSWORD" -T /usr/bin/codesign >/dev/null

echo "✅ Created \"$IDENTITY\""
echo "   SHA-1:  $(/usr/bin/openssl x509 -in "$WORK/cert.pem" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)"
echo "   Backup: $BACKUP"
echo "   Show the backup password with: security find-generic-password -s \"$PASSWORD_SERVICE\" -w"
