#!/usr/bin/env bash
set -euo pipefail

# Claude Code CLI installer
# Usage: curl -L https://installer.anthropic.com/install-claude-code.sh | bash

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

has_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       error "Unsupported operating system: $(uname -s)" ;;
  esac
}

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

install_node() {
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      if has_cmd brew; then
        info "Installing Node.js via Homebrew..."
        brew install node
      else
        error "Node.js v${MIN_NODE_MAJOR}+ is required. Install it from https://nodejs.org or install Homebrew (https://brew.sh) first."
      fi
      ;;
    linux)
      if has_cmd apt-get; then
        info "Installing Node.js via NodeSource (apt)..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
      elif has_cmd dnf; then
        info "Installing Node.js via NodeSource (dnf)..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo dnf install -y nodejs
      elif has_cmd yum; then
        info "Installing Node.js via NodeSource (yum)..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo yum install -y nodejs
      else
        error "Cannot install Node.js: no supported package manager found (apt-get, dnf, yum). Install Node.js v${MIN_NODE_MAJOR}+ manually: https://nodejs.org"
      fi
      ;;
  esac
}

ensure_node() {
  if check_node; then
    return 0
  fi
  install_node
  if ! check_node; then
    error "Node.js installation failed. Please install Node.js v${MIN_NODE_MAJOR}+ manually: https://nodejs.org"
  fi
}

install_claude_code() {
  info "Installing Claude Code CLI..."
  local npm_flags="--global"

  if npm install $npm_flags "$PACKAGE" 2>/dev/null; then
    return 0
  fi

  warn "Global npm install failed (permission denied?), retrying with sudo..."
  if has_cmd sudo; then
    sudo npm install $npm_flags "$PACKAGE"
  else
    error "Cannot install globally: insufficient permissions and sudo not available."
  fi
}

verify_install() {
  if has_cmd claude; then
    success "Claude Code CLI installed successfully!"
    printf "Version: %s\n" "$(claude --version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  local npm_bin
  npm_bin=$(npm bin -g 2>/dev/null || true)
  if [ -n "$npm_bin" ] && [ -x "$npm_bin/claude" ]; then
    success "Claude Code CLI installed to $npm_bin/claude"
    warn "Add the following to your shell profile to use 'claude' directly:"
    warn "  export PATH=\"$npm_bin:\$PATH\""
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
  info "Claude Code CLI Installer"
  printf "OS: %s\n\n" "$(detect_os)"

  ensure_node
  install_claude_code
  verify_install
  print_next_steps
}

main "$@"
