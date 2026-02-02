#!/usr/bin/env bash
set -e

# ZSH Setup Script für Linux und macOS
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

# OS erkennen
OS="$(uname -s)"
log "Erkanntes Betriebssystem: $OS"

# Root-Check (nur für Linux relevant)
if [ "$OS" = "Linux" ] && [ "$EUID" -eq 0 ]; then
    warn "Script läuft als root - Installation erfolgt für root-User"
fi

log "Starte ZSH Setup..."

# System-Pakete installieren
log "Installiere Abhängigkeiten..."
if [ "$OS" = "Darwin" ]; then
    # macOS mit Homebrew
    if ! command -v brew > /dev/null 2>&1; then
        warn "Homebrew nicht gefunden - installiere Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh git curl wget fontconfig unzip
elif [ "$OS" = "Linux" ]; then
    # Linux mit apt
    sudo apt-get update
    sudo apt-get install -y zsh git curl wget fontconfig unzip
else
    warn "Unbekanntes Betriebssystem: $OS - überspringe Paketinstallation"
fi

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

# Atuin konfigurieren
log "Konfiguriere Atuin..."
mkdir -p "$HOME/.config/atuin"
cat > "$HOME/.config/atuin/config.toml" << 'EOF'
sync_address = "https://atuin.dev.kuepper.nrw"
EOF
success "Atuin konfiguriert"

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

# ZSH Config-Dateien herunterladen
ZSH_CONFIG_DIR="$HOME/.zsh.d"
REPO_ZSH_URL="https://raw.githubusercontent.com/ruedigerp/setup-zsh/main/zsh"

log "Lade ZSH Config-Dateien..."
mkdir -p "$ZSH_CONFIG_DIR"

# Liste der Config-Dateien (erweiterbar)
for config_file in aliases functions; do
    if curl -fsSL "$REPO_ZSH_URL/$config_file" -o "$ZSH_CONFIG_DIR/$config_file"; then
        success "$config_file heruntergeladen"
    else
        warn "Konnte $config_file nicht laden"
    fi
done

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

# Lade alle Config-Dateien aus ~/.zsh.d/
if [[ -d ~/.zsh.d ]]; then
    for config in ~/.zsh.d/*; do
        [[ -f "$config" ]] && source "$config"
    done
fi

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF

success ".zshrc konfiguriert"

# Default Shell ändern
log "Setze zsh als Default-Shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    if [ "$OS" = "Darwin" ]; then
        chsh -s "$(which zsh)"
    else
        sudo chsh -s "$(which zsh)" "$USER"
    fi
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