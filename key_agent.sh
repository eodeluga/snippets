#!/usr/bin/env bash
# Source from a VS Code Bash terminal. Execute with --ssh for background Git.
# Compatible with Bash 3.2+ (including Apple's Bash); no GNU-only utilities.

_key_agent_alive() {
    local status
    [ -n "${1:-}" ] || return 1
    if SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1; then
        return 0
    else
        status=$?
        [ "$status" -eq 1 ] # A reachable agent with no identities is reusable.
    fi
}

_key_agent_platform() {
    case "$(uname -s)" in
        Darwin) printf 'macos\n' ;;
        Linux)
            if grep -qi microsoft /proc/sys/kernel/osrelease; then
                printf 'wsl\n'
            else
                printf 'ubuntu\n'
            fi ;;
        *) printf 'Unsupported key-agent platform.\n' >&2; return 1 ;;
    esac
}

_key_agent_resolve() {
    case "$(_key_agent_platform)" in
        macos) SSH_AUTH_SOCK=$(launchctl getenv SSH_AUTH_SOCK) || return 1 ;;
        ubuntu)
            local session_environment
            session_environment=$(systemctl --user show-environment) || return 1
            SSH_AUTH_SOCK=$(printf '%s\n' "$session_environment" |
                sed -n 's/^SSH_AUTH_SOCK=//p') ;;
        wsl) SSH_AUTH_SOCK="$HOME/.ssh/vscode-agent.sock" ;;
        *) return 1 ;;
    esac
    export SSH_AUTH_SOCK
    unset SSH_AGENT_PID
    _key_agent_alive "$SSH_AUTH_SOCK"
}

_key_agent_add_keys() {
    local key fingerprint loaded
    for key in "$HOME"/.ssh/id_*; do
        [ -f "$key" ] || continue
        case "$key" in *.pub|*-cert.pub) continue ;; esac
        # Prefer the public half: never request a passphrase to fingerprint a key.
        if [ -f "$key.pub" ]; then
            fingerprint=$(ssh-keygen -lf "$key.pub" 2>/dev/null | awk '{print $2}')
        else
            fingerprint=$(ssh-keygen -lf "$key" </dev/null 2>/dev/null | awk '{print $2}')
        fi
        [ -n "$fingerprint" ] || continue
        loaded=$(ssh-add -l 2>/dev/null | awk '{print $2}')
        if ! printf '%s\n' "$loaded" | grep -Fqx -- "$fingerprint"; then
            printf 'Unlocking SSH key: %s\n' "$key"
            if [ "$(uname -s)" = Darwin ]; then
                /usr/bin/ssh-add --apple-use-keychain "$key" || return 1
            else
                SSH_ASKPASS_REQUIRE=never ssh-add "$key" </dev/tty || return 1
            fi
        fi
    done
}

# Keep the existing GPG cache check; GNU timeout is standard on Ubuntu/WSL.
_key_agent_gpg_key_cached() {
    local grip
    grip=$(gpg --with-colons --with-keygrip --list-secret-keys "$1" 2>/dev/null |
        awk -F: '/^grp:/{print $10; exit}')
    [ -n "$grip" ] || return 1
    if [ "$(uname -s)" = Darwin ]; then
        gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null
    else
        timeout 2 gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null
    fi | grep -q "KEYINFO $grip .* 1 "
}

_key_agent_gpg() {
    local signing_key format
    gpgconf --launch gpg-agent || return 1
    format=$(git config --global --get gpg.format 2>/dev/null) || format=openpgp
    [ "$format" = openpgp ] || return 0
    signing_key=$(git config --global --get user.signingkey 2>/dev/null) || return 0
    if [ -n "$signing_key" ] && ! _key_agent_gpg_key_cached "$signing_key"; then
        # Only called from an interactive VS Code terminal with a TTY.
        gpg --local-user "$signing_key" --clearsign --output /dev/null - \
            <<< "warmup" >/dev/null 2>&1 || return 1
    fi
}

_key_agent_start_wsl() (
    # Only agent creation is locked. Closing this subshell releases the lock.
    umask 077
    mkdir -p "$HOME/.ssh" || exit 1
    exec 9>"$HOME/.ssh/.vscode-key-agent.flock" || exit 1
    flock -w 5 9 || return 1
    # Another terminal may have started it while we waited.
    _key_agent_alive "$SSH_AUTH_SOCK" && return 0
    rm -f "$SSH_AUTH_SOCK" || return 1
    ssh-agent -a "$SSH_AUTH_SOCK" -s 9>&- >/dev/null || return 1
    _key_agent_alive "$SSH_AUTH_SOCK"
)

_key_agent_terminal() {
    if ! _key_agent_resolve; then
        if [ "$(_key_agent_platform)" = wsl ]; then
            _key_agent_start_wsl || {
                printf 'WSL SSH agent startup failed; retry with _keys_unlock.\n' >&2
                return 1
            }
        else
            printf 'The native SSH agent is unavailable; check your desktop session.\n' >&2
            return 1
        fi
    fi
    _key_agent_add_keys || printf 'SSH unlock incomplete; retry with _keys_unlock.\n' >&2
    _key_agent_gpg || printf 'GPG unlock incomplete; retry with _keys_unlock.\n' >&2
}

_keys_unlock() {
    [ "${TERM_PROGRAM:-}" = vscode ] || return 0
    case $- in *i*) ;; *) return 0 ;; esac
    [ -t 0 ] && [ -t 1 ] || return 0
    GPG_TTY=$(tty)
    export GPG_TTY
    _key_agent_terminal
}

# Global Git may call this outside VS Code too. Reconnection has no prompts.
# VS Code Git SSH uses unlocked keys; other Git retains normal SSH prompting.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ "${1:-}" = --ssh ]; then
        shift
        if ! _key_agent_resolve; then
            printf 'SSH agent unavailable; open a VS Code terminal to initialise key setup.\n' >&2
            exit 1
        fi
        # The Git extension may supply its askpass variables without TERM_PROGRAM.
        if [ "${TERM_PROGRAM:-}" = vscode ] ||
            [ -n "${VSCODE_GIT_ASKPASS_NODE:-}${VSCODE_IPC_HOOK_CLI:-}" ]; then
            exec ssh -o BatchMode=yes "$@"
        fi
        exec ssh "$@"
    fi
    printf 'Source this script from a VS Code Bash terminal.\n' >&2
    exit 2
fi

_keys_unlock
