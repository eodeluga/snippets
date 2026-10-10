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
    git config --global core.sshCommand "ssh -o IdentityAgent=$SSH.AUTH.SOCK"
   
    # GPG set up
    export GPG_TTY=$(tty)
    gpgconf --launch gpg-agent

    # True when the signing key's passphrase is already cached by gpg-agent
    _gpg_key_cached() {
        local grip
        grip=$(gpg --with-colons --with-keygrip --list-secret-keys "$1" 2>/dev/null \
               | awk -F: '/^grp:/{print $10; exit}')
        [ -n "$grip" ] || return 1
        timeout 2 gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null \
            | grep -q "KEYINFO $grip .* 1 "
    }

    # Warm the cache once from the first interactive terminal only; agent/headless
    # terminals never prompt, so they can't block waiting for a passphrase.
    GPG_KEYID="$(git config --global --get user.signingkey)"
    if [ -n "$GPG_KEYID" ] && ! _gpg_key_cached "$GPG_KEYID"; then
        if [ -t 0 ] && [ -t 1 ] && [[ $- == *i* ]]; then
            gpg --local-user "$GPG_KEYID" --clearsign --output /dev/null - <<< "warmup" \
                >/dev/null 2>&1
        fi
    fi
fi
```
