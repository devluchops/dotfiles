# =============================================================================
# ALIASES - Modern and useful command shortcuts
# =============================================================================

# Git aliases
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git reset'
alias gst='git stash'
alias gstp='git stash pop'

# Navigation aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Directory operations
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'

# File operations
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias ln='ln -iv'

# Modern replacements (install with: brew install bat exa fd ripgrep)
if command -v bat &> /dev/null; then
    alias cat='bat'
    alias catn='bat --style=plain'
fi

if command -v exa &> /dev/null; then
    alias ls='exa --icons'
    alias ll='exa -la --icons --git'
    alias tree='exa --tree --icons'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'

# Kubernetes aliases
alias k='kubectl'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt'

# System monitoring
alias top='htop'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'

# Network
alias ping='ping -c 5'
alias ports='netstat -tulanp'

# Archives
alias untar='tar -zxvf'
alias tar='tar -zcvf'

# Development
alias serve8000='python3 -m http.server 8000'
# JSON pretty print function is defined in functions.zsh

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias o='open'
    alias finder='open -a Finder'
    alias flush='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
    alias cleanup='sudo rm -rf /System/Library/Caches/* /Library/Caches/* ~/Library/Caches/*'
    alias hidedesktop='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
    alias showdesktop='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'
fi

# Quick edits
alias zshrc='$EDITOR ~/.zshrc'
alias vimrc='$EDITOR ~/.vimrc'
alias nvimrc='$EDITOR ~/.config/nvim/init.lua'

# Reload shell
alias reload='source ~/.zshrc'

# Personal shortcuts
alias g='git'
alias activate_venv='source /Users/luisvalencia/.venv/bin/activate'
