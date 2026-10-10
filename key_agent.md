### How to add SSH keys to agent at login

* Copy `key_agent.sh` file to `$HOME\.ssh\`
* Add the following to the end of `$HOME\.bashrc`
* Reload the file with `source $HOME\.bashrc`

```
# Cache SSH credentials and set up GPG commit signing when using bash in VSCode
if [ "$TERM_PROGRAM" = "vscode" ]; then
    if [ -f "$HOME/.ssh/key_agent.sh" ]; then
        . "$HOME/.ssh/key_agent.sh"
    fi
fi
```
