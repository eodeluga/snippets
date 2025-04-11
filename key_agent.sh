#!/bin/bash
SSH_HOME="$HOME/.ssh"

function find_agent {
  for sock in /tmp/ssh-*/agent.*; do
    export SSH_AUTH_SOCK=$sock
    if ssh-add -l > /dev/null 2>&1; then
      echo "Reconnected to existing SSH agent."
      return 0
    fi
  done
  return 1
}

# Function to start a new SSH agent
function start_agent {
  eval "$(ssh-agent -s)" > /dev/null
}

# Function to check if the SSH agent is running
function agent_running {
  pgrep -u "$USER" ssh-agent > /dev/null
}

function add_missing_keys {
  echo "Checking for loaded keys..."
  
  # Get fingerprints of currently loaded keys
  loaded_fingerprints=$(ssh-add -l 2>/dev/null | awk '{print $2}')

  # Iterate over private keys in ~/.ssh
  find "$SSH_HOME" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' | while read -r keyfile; do
    # Get the fingerprint of the key to compare with loaded keys
    key_fingerprint=$(ssh-keygen -lf "$keyfile" | awk '{print $2}')

    # Check if the fingerprint matches any loaded key
    if ! echo "$loaded_fingerprints" | grep -q "$key_fingerprint"; then
      echo "Adding key: $keyfile"
      while true; do
        # Add the key with explicit terminal passphrase entry
        SSH_ASKPASS= ssh-add "$keyfile" </dev/tty
        if [ $? -eq 0 ]; then
          echo "Successfully added key: $keyfile"
          break
        else
          echo "Failed to add key: $keyfile."
          echo "Would you like to retry? (yes/no)"
          read -r retry </dev/tty
          if [[ "$retry" != "yes" ]]; then
            echo "Skipping key: $keyfile"
            break
          fi
        fi
      done
    fi
  done
}

# Main logic to manage SSH agent and keys
if agent_running; then
  echo "SSH agent already running."
  if ! find_agent; then
    echo "Could not reconnect to existing agent. Starting a new one."
    start_agent
  fi
else
  echo "Starting SSH agent..."
  start_agent
fi

add_missing_keys
echo "Completed."
