# Step 1-5: one-time SSH key & auth setup

setup() {
  local ip="$1" key="$2"

  # Step 1: ensure local key
  sinfo "[1/5] check local SSH key: $key"
  [[ ! -f "$key" ]] && { sinfo "  generating..."; ssh-keygen -t ed25519 -f "$key" -N "" || return 1; }
  sinfo "  key exists: $key"

  # Step 2: clean old remote host key
  sinfo "[2/5] clean old host key for $ip"
  ssh-keygen -R "$ip" 2>/dev/null || true

  # Step 3: push local pub key to remote
  sinfo "[3/5] push pub key to root@$ip"
  ssh-copy-id -o StrictHostKeyChecking=accept-new -i "${key}.pub" "root@${ip}" || return 1

  # Step 4: ensure remote key
  sinfo "[4/5] check remote SSH key"
  ssh "root@${ip}" "[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''" || return 1

  # Step 5: add remote pub key to local authorized_keys
  sinfo "[5/5] add remote pub key to local authorized_keys"
  local remote_pub
  remote_pub=$(ssh "root@${ip}" "cat ~/.ssh/id_ed25519.pub") || return 1
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  grep -qF "$remote_pub" ~/.ssh/authorized_keys 2>/dev/null && sinfo "  remote key already present" && return 0
  echo "$remote_pub" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sinfo "  remote key added"

  sinfo "setup complete"
}
