# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Update window size automatically
shopt -s checkwinsize

# Make less more friendly
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable for chroot (used in prompt)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# Set the prompt
export PS1="❭\w "

# --- ALIASES ---
alias ff='fastfetch --logo small'
alias notificacion='notify-send "¡Acabado!"'
alias serve='npx live-server'
alias instagram_45192314M_640875852='sudo /usr/local/bin/focus-break'
alias ls='eza --icons --hyperlink'
alias ll='eza -l --header --icons --hyperlink'
alias la='eza -a --icons --hyperlink'
alias lt='eza -T --level=2 --icons --hyperlink'
alias ltt='eza -T --icons --hyperlink'
alias q='exit'
alias sync='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean && dpkg -l | grep "^rc" | awk "{print \$2}" | xargs -r sudo dpkg --purge && flatpak update -y && flatpak uninstall --unused -y && sudo journalctl --vacuum-time=7d'
alias v='nvim'
alias cat='batcat'
alias f='fzf'
alias wttr='curl wttr.in/Palma'
alias clock='tty-clock -c -C 7 -s -d 1000 -f "%A, %B %d, %Y" -b'
alias c='clear'
alias bluetooth='sudo systemctl start bluetooth'
# yazi
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

export VISUAL='nvim'
export EDITOR='nvim'

# Enable bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- SHELL INTEGRATION ---
eval "$(zoxide init bash)"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export PATH=/usr/local/go/bin:$PATH
. "$HOME/.cargo/env"

