#!/bin/zsh

set -u

DEFAULT_DOTFILES_REPO_URL="https://codeberg.org/liasis/dotfiles.git"
DOTFILES_REPO_URL="${1:-$DEFAULT_DOTFILES_REPO_URL}"
CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"
CHEZMOI_DATA_FILE="$CHEZMOI_SOURCE_DIR/.chezmoidata.yaml"

info() {
  echo "==> $1"
}

error() {
  echo "ERROR: $1" >&2
}

if [[ "$DOTFILES_REPO_URL" != https://* ]]; then
  error "Repository URL must use https:// (received: $DOTFILES_REPO_URL)"
  error "Use HTTPS now; you can switch to SSH later with: git remote set-url"
  exit 1
fi

yaml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

ensure_chezmoidata() {
  if [ -f "$CHEZMOI_DATA_FILE" ]; then
    info "Found $CHEZMOI_DATA_FILE"
    return
  fi

  info "Missing $CHEZMOI_DATA_FILE"
  echo "This file is required to configure your Git identities and SSH key."
  echo ""
  echo "We'll create it now with your input."
  echo ""

  local default_name default_email default_ssh_key default_private_path
  default_name="$(id -F 2>/dev/null || true)"
  default_email=""
  default_ssh_key="~/.ssh/id_ed25519"
  default_private_path="~/Developer/Private"

  print -n "Full name [${default_name}]: "
  read name_input
  name_input="${name_input:-$default_name}"

  while true; do
    print -n "Email (used for git + ssh key comment): "
    read email_input
    if [ -n "$email_input" ]; then
      break
    fi
    echo "Email is required."
  done

  print -n "Private git root path [${default_private_path}]: "
  read private_path_input
  private_path_input="${private_path_input:-$default_private_path}"

  print -n "Private SSH key path [${default_ssh_key}]: "
  read ssh_key_input
  ssh_key_input="${ssh_key_input:-$default_ssh_key}"

  mkdir -p "$CHEZMOI_SOURCE_DIR"
  cat > "$CHEZMOI_DATA_FILE" <<EOF
---
user:
  name: "$(yaml_escape "$name_input")"
  email: "$(yaml_escape "$email_input")"

git:
  includes:
    - private:
        path: "$(yaml_escape "$private_path_input")"
        ssh_key: "$(yaml_escape "$ssh_key_input")"
EOF

  info "Created $CHEZMOI_DATA_FILE"
}

# Install xcode CLI tools (pre-req for homebrew)
info "Checking Xcode Command Line Tools"
if xcode-select -p 2>&1 | grep -q "error: Unable to get active developer"; then
  info "Xcode Command Line Tools are required for Homebrew. Opening installer UI"
  xcode-select --install
else
  info "Xcode Command Line Tools already installed"
fi

# Install Homebrew (https://brew.sh)
info "Checking Homebrew"
if ! command -v brew &> /dev/null; then
  info "Homebrew missing. Installing"

  if ! sudo -n true 2>/dev/null; then
    echo "Administrator privileges are required to install Homebrew."
    sudo -v || { error "Incorrect password or missing sudo access. Aborting."; exit 1; }
  fi
  
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" "" 
  
  if [ -f "/opt/homebrew/bin/brew" ]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  info "Homebrew already installed"
fi

if ! command -v chezmoi &> /dev/null; then
  info "Installing chezmoi"
  brew install chezmoi
else
  info "chezmoi already installed"
fi

# Initialize dotfiles with chezmoi early, before reading chezmoidata.
if [ ! -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
  info "Initializing chezmoi source from $DOTFILES_REPO_URL"
  chezmoi init "$DOTFILES_REPO_URL" || { error "chezmoi init failed"; exit 1; }
else
  info "chezmoi source already initialized at $CHEZMOI_SOURCE_DIR"
fi

ensure_chezmoidata

# Create SSH key
info "Resolving SSH key settings from chezmoidata"
ssh_comment="$(chezmoi execute-template '{{ .user.email }}' 2>/dev/null | tr -d '\r\n')"
if [ -z "$ssh_comment" ]; then
  error "Could not read user.email from $CHEZMOI_DATA_FILE"
  exit 1
fi

ssh_key_path="$(
  chezmoi execute-template '{{- range .git.includes -}}{{- if hasKey . "private" -}}{{ .private.ssh_key }}{{- end -}}{{- end -}}' 2>/dev/null | tr -d '\r\n'
)"
if [ -z "$ssh_key_path" ]; then
  # Backward-compatible fallback for map-shaped data.
  ssh_key_path="$(chezmoi execute-template '{{ .git.includes.private.ssh_key }}' 2>/dev/null | tr -d '\r\n')"
fi
if [ -z "$ssh_key_path" ]; then
  error "Could not read git.includes.private.ssh_key from $CHEZMOI_DATA_FILE"
  exit 1
fi

ssh_key_path="${ssh_key_path/#\~/$HOME}"
if [ -f "$ssh_key_path" ] || [ -f "$ssh_key_path.pub" ]; then
  info "SSH key already exists at $ssh_key_path. Skipping key generation"
else
  info "Creating SSH key at $ssh_key_path"
  mkdir -p "$(dirname "$ssh_key_path")"
  while true; do
    echo "Create passphrase for SSH key"
    print -n "Enter passphrase: "
    read -s pass1; echo ""
    print -n "Repeat passphrase: "
    read -s pass2; echo ""
    if [ "$pass1" = "$pass2" ]; then
      ssh-keygen -t ed25519 -f "$ssh_key_path" -N "$pass1" -C "$ssh_comment" -q || { error "ssh-keygen failed"; exit 1; }
      unset pass1 pass2
      info "Key created at $ssh_key_path"
      if ssh-add --apple-use-keychain -q "$ssh_key_path"; then
        info "Key added to macOS keychain"
      else
        error "Failed to add SSH key to macOS keychain"
        exit 1
      fi
      break
    else
      echo "Passphrases do not match. Try again."
      echo ""
    fi
  done
fi

info "Bootstrap complete"
