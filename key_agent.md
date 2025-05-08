### How to add SSH keys to agent at login

* Copy `key_agent.sh` file to `$HOME\.ssh\`
* Add the following to the end of `$HOME\.bashrc`
* Reload the file with `source $HOME\.bashrc`

```
# Only run in an interactive SSH session
if [[ $- == *i* && -n "$SSH_CONNECTION" ]]; then
  if [[ -f "$HOME/.ssh/agent_env" ]]; then
    source "$HOME/.ssh/agent_env" > /dev/null 2>&1
  fi

  if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
    if [[ -f "$HOME/.ssh/key_agent.sh" ]]; then
      source "$HOME/.ssh/key_agent.sh"
      source "$HOME/.ssh/agent_env"
    fi
  fi
fi
```
