#!/usr/bin/env bash
set -e

# ZSH Setup Script für Ubuntu Server
# Installiert: zsh, oh-my-zsh, powerlevel10k, fzf, atuin
#
# Verwendung:
#   curl -fsSL https://raw.githubusercontent.com/ruedigerp/setup-zsh/main/setup-zsh.sh | bash
#   (WICHTIG: "bash" statt "sh" verwenden!)

# ===========================================
# KONFIGURATION - Hier anpassen!
# ===========================================
# URL zur .p10k.zsh (raw GitHub URL)
P10K_CONFIG_URL="https://raw.githubusercontent.com/ruedigerp/setup-zsh/main/.p10k.zsh"

# Optional: Ganzes Dotfiles-Repo klonen
# DOTFILES_REPO="https://github.com/DEIN-USER/dotfiles.git"
# ===========================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf "%b[INFO]%b %s\n" "$CYAN" "$NC" "$1"; }
success() { printf "%b[OK]%b %s\n" "$GREEN" "$NC" "$1"; }
warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"; }

# Root-Check
if [ "$EUID" -eq 0 ]; then
    warn "Script läuft als root - Installation erfolgt für root-User"
fi

log "Starte ZSH Setup..."

# System-Pakete installieren
log "Installiere Abhängigkeiten..."
sudo apt-get update
sudo apt-get install -y zsh git curl wget fontconfig unzip

# Oh-My-Zsh installieren
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installiere Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh-My-Zsh installiert"
else
    warn "Oh-My-Zsh bereits vorhanden"
fi

# Powerlevel10k installieren
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    log "Installiere Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installiert"
else
    warn "Powerlevel10k bereits vorhanden"
fi

# fzf installieren
if [ ! -d "$HOME/.fzf" ]; then
    log "Installiere fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    success "fzf installiert"
else
    warn "fzf bereits vorhanden"
fi

# Atuin installieren
if ! command -v atuin > /dev/null 2>&1 && [ ! -f "$HOME/.atuin/bin/atuin" ]; then
    log "Installiere Atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    success "Atuin installiert"
else
    warn "Atuin bereits vorhanden"
fi

# Nützliche Plugins installieren
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log "Installiere zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installiert"
else
    warn "zsh-autosuggestions bereits vorhanden"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log "Installiere zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installiert"
else
    warn "zsh-syntax-highlighting bereits vorhanden"
fi

# Powerlevel10k Config von Git laden (immer überschreiben)
log "Lade .p10k.zsh von Git..."
if curl -fsSL "$P10K_CONFIG_URL" -o "$HOME/.p10k.zsh"; then
    success ".p10k.zsh heruntergeladen"
else
    warn "Konnte .p10k.zsh nicht laden - nutze 'p10k configure' nach der Installation"
fi

# .zshrc konfigurieren
log "Konfiguriere .zshrc..."
cat > "$HOME/.zshrc" << 'EOF'
# Powerlevel10k instant prompt (vor allem anderen)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh-My-Zsh Konfiguration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    docker
    kubectl
    helm
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# fzf
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Atuin
export PATH="$HOME/.atuin/bin:$PATH"
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias d='docker'
alias dc='docker compose'

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF

success ".zshrc konfiguriert"

# Default Shell ändern
log "Setze zsh als Default-Shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
    success "Default-Shell auf zsh geändert"
else
    warn "zsh ist bereits Default-Shell"
fi

echo ""
success "========================================="
success "ZSH Setup abgeschlossen!"
success "========================================="
echo ""
echo "Nächste Schritte:"
echo "  1. Neue Shell starten: exec zsh"
echo "  2. Atuin einrichten: atuin login (optional für Sync)"
echo ""
echo "Hinweis: Für beste Darstellung MesloLGS NF Font installieren:"
echo "  https://github.com/romkatv/powerlevel10k#fonts"