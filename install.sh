#!/usr/bin/env bash
set -euo pipefail

# Claude Code installer
# Usage: curl -fsSL https://claude.ai/install.sh | bash

PACKAGE="@anthropic-ai/claude-code"
MIN_NODE_MAJOR=18

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "${BOLD}%s${RESET}\n" "$*"; }
success() { printf "${GREEN}%s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}%s${RESET}\n" "$*" >&2; }
error()   { printf "${RED}Error: %s${RESET}\n" "$*" >&2; exit 1; }

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       error "Unsupported operating system: $(uname -s)" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x64" ;;
    arm64|aarch64) echo "arm64" ;;
    *) error "Unsupported architecture: $(uname -m)" ;;
  esac
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

check_node() {
  if ! has_cmd node; then
    return 1
  fi
  local version major
  version=$(node --version 2>/dev/null | sed 's/^v//')
  major=$(echo "$version" | cut -d. -f1)
  if [ "$major" -lt "$MIN_NODE_MAJOR" ] 2>/dev/null; then
    warn "Node.js $version found, but v${MIN_NODE_MAJOR}+ is required."
    return 1
  fi
  return 0
}

install_node_linux() {
  info "Installing Node.js via NodeSource..."
  if has_cmd apt-get; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
  elif has_cmd dnf; then
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
    sudo dnf install -y nodejs
  elif has_cmd yum; then
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
    sudo yum install -y nodejs
  else
    error "Cannot install Node.js: no supported package manager found (apt-get, dnf, yum)."
  fi
}

install_node_macos() {
  if has_cmd brew; then
    info "Installing Node.js via Homebrew..."
    brew install node
  else
    error "Homebrew is required to install Node.js on macOS. Install it from https://brew.sh and re-run this script."
  fi
}

ensure_node() {
  if check_node; then
    return 0
  fi
  local os
  os=$(detect_os)
  case "$os" in
    linux) install_node_linux ;;
    macos) install_node_macos ;;
  esac
  if ! check_node; then
    error "Node.js installation failed. Please install Node.js v${MIN_NODE_MAJOR}+ manually: https://nodejs.org"
  fi
}

install_claude_cask() {
  info "Installing Claude via Homebrew Cask..."
  brew install --cask claude
}

install_claude_npm() {
  info "Installing Claude Code via npm..."
  local npm_flags="--global --prefer-offline"

  if npm install $npm_flags "$PACKAGE" 2>/dev/null; then
    return 0
  fi

  # Fall back to sudo if the global prefix is system-owned
  warn "Global npm install failed (permission denied?), retrying with sudo..."
  if has_cmd sudo; then
    sudo npm install $npm_flags "$PACKAGE"
  else
    error "Cannot install globally: insufficient permissions and sudo not available."
  fi
}

install_claude() {
  local os
  os=$(detect_os)

  if [ "$os" = "macos" ] && has_cmd brew; then
    install_claude_cask
  else
    ensure_node
    install_claude_npm
  fi
}

verify_install() {
  if has_cmd claude; then
    success "Claude Code installed successfully!"
    printf "Version: %s\n" "$(claude --version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  # Cask installs the .app bundle; CLI symlink may not be on PATH yet
  local cask_cli="/Applications/Claude.app/Contents/MacOS/claude"
  if [ -x "$cask_cli" ]; then
    success "Claude installed via Homebrew Cask."
    warn "'claude' is not yet on your PATH. Add this to your shell profile:"
    warn "  export PATH=\"/Applications/Claude.app/Contents/MacOS:\$PATH\""
    return 0
  fi

  # npm global bin may not be on PATH in this shell session
  local npm_bin
  npm_bin=$(npm bin -g 2>/dev/null || true)
  if [ -n "$npm_bin" ] && [ -x "$npm_bin/claude" ]; then
    success "Claude Code installed to $npm_bin/claude"
    warn "Add $npm_bin to your PATH to use 'claude' directly."
    return 0
  fi

  warn "Installation complete, but 'claude' was not found on PATH."
  warn "You may need to restart your shell or update your PATH."
}

print_next_steps() {
  printf "\n${BOLD}Next steps:${RESET}\n"
  printf "  1. Run ${BOLD}claude${RESET} to start Claude Code\n"
  printf "  2. Log in with your Anthropic account when prompted\n"
  printf "  3. Visit https://claude.ai/code for documentation\n\n"
}

main() {
  info "Claude Code Installer"
  printf "OS: %s / Arch: %s\n\n" "$(detect_os)" "$(detect_arch)"

  install_claude
  verify_install
  print_next_steps
}

main "$@"
