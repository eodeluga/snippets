#!/bin/bash

SSH_HOME="$HOME/.ssh"
AGENT_ENV_FILE="$SSH_HOME/agent_env"

function reconnect_existing_agent {
  for sock in /tmp/ssh-*/agent.*; do
    if SSH_AUTH_SOCK="$sock" ssh-add -l &>/dev/null; then
      export SSH_AUTH_SOCK="$sock"
      export SSH_AGENT_PID=$(lsof -t "$sock" | head -n 1)
      echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$AGENT_ENV_FILE"
      echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$AGENT_ENV_FILE"
      chmod 600 "$AGENT_ENV_FILE"
      echo "Reconnected to existing SSH agent."
      return 0
    fi
  done
  return 1
}

function start_new_agent {
  eval "$(ssh-agent -s)" > /dev/null
  echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$AGENT_ENV_FILE"
  echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$AGENT_ENV_FILE"
  chmod 600 "$AGENT_ENV_FILE"
  echo "Started new SSH agent."
}

function add_missing_keys {
  echo "Checking for loaded keys..."

  loaded_fingerprints=$(ssh-add -l 2>/dev/null | awk '{print $2}')

  find "$SSH_HOME" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' | while read -r keyfile; do
    key_fingerprint=$(ssh-keygen -lf "$keyfile" | awk '{print $2}')
    if ! echo "$loaded_fingerprints" | grep -q "$key_fingerprint"; then
      echo "Adding key: $keyfile"
      SSH_ASKPASS= ssh-add "$keyfile" </dev/tty
    fi
  done
}

# Main agent logic
if ! reconnect_existing_agent; then
  start_new_agent
fi

add_missing_keys
