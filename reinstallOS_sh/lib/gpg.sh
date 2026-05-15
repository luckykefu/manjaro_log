gen_gpg(){
    local name=$1 email=$2 passphrase=$3
    gpg --list-keys "$email" &>/dev/null && echo "GPG key for $email already exists" || {
        local batch_file="/tmp/batch-gen-key-$email"
        cat > "$batch_file" << BATCHEOF
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $name
Name-Email: $email
Expire-Date: 0
Passphrase: $passphrase
%commit
BATCHEOF
        gpgconf --kill gpg-agent 2>/dev/null || true
        gpg --batch --gen-key "$batch_file" && echo "GPG key generated for $name <$email>" || { echo "error: gpg key generation failed" >&2; rm -f "$batch_file"; return 1; }
        rm -f "$batch_file"
    }
    echo "GPG done"
}

gpg_cfg() {
    local name="${1:-kefu}" email="${2:-19157521820@163.com}" passphrase="${3:-lkf.Gpg.mima3}"
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    gen_gpg "$name" "$email" "$passphrase"
}
