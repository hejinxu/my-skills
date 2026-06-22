#!/bin/bash

# My Skills Installer for Linux/Mac
# Usage: ./install.sh [--target claude|opencode|all] [--skip-config]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source directory
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directories
GLOBAL_CONFIG_DIR="$HOME/.skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skills"
OPENCODE_COMMANDS_DIR="$HOME/.config/opencode/commands"

# Default target
TARGET="all"
SKIP_CONFIG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --skip-config)
      SKIP_CONFIG=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--target claude|opencode|all] [--skip-config]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

write_step() {
  echo -e "\n${CYAN}>> $1${NC}"
}

write_success() {
  echo -e "   ${GREEN}$1${NC}"
}

write_warning() {
  echo -e "   ${YELLOW}$1${NC}"
}

write_error() {
  echo -e "   ${RED}Error: $1${NC}"
}

check_node() {
  if command -v node &> /dev/null; then
    return 0
  else
    return 1
  fi
}

install_global_config() {
  write_step "Setting up global configuration"
  
  if [ ! -d "$GLOBAL_CONFIG_DIR" ]; then
    mkdir -p "$GLOBAL_CONFIG_DIR"
    write_success "Created config directory: $GLOBAL_CONFIG_DIR"
  fi
  
  local config_file="$GLOBAL_CONFIG_DIR/config.json"
  
  if [ -f "$config_file" ]; then
    write_warning "Config file already exists at: $config_file"
    read -p "   Do you want to overwrite it? (y/N): " overwrite
    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
      write_warning "Keeping existing config"
      return
    fi
  fi
  
  if [ "$SKIP_CONFIG" = true ]; then
    write_warning "Skipping interactive config (using template)"
    cat > "$config_file" << EOF
{
  "jira": {
    "base_url": "",
    "pat": "",
    "default_project": ""
  }
}
EOF
  else
    echo ""
    echo "   Please provide your Jira configuration:"
    echo "   (Press Enter to skip any field)"
    echo ""
    
    read -p "   Jira Base URL (e.g., https://jira.company.com): " base_url
    read -p "   Personal Access Token: " pat
    read -p "   Default Project Key (optional): " default_project
    
    cat > "$config_file" << EOF
{
  "jira": {
    "base_url": "$base_url",
    "pat": "$pat",
    "default_project": "$default_project"
  }
}
EOF
  fi
  
  write_success "Configuration saved to: $config_file"
}

install_lib_files() {
  write_step "Installing library files"
  
  local lib_target_dir="$GLOBAL_CONFIG_DIR/lib"
  if [ ! -d "$lib_target_dir" ]; then
    mkdir -p "$lib_target_dir"
  fi
  
  cp -r "$SOURCE_DIR/lib/"* "$lib_target_dir/"
  write_success "Library files installed to: $lib_target_dir"
}

install_skill() {
  local skill_name="$1"
  local target_dir="$2"
  
  local skill_source_dir="$SOURCE_DIR/skills/$skill_name"
  local skill_target_dir="$target_dir/$skill_name"
  
  if [ ! -d "$skill_target_dir" ]; then
    mkdir -p "$skill_target_dir"
  fi
  
  # Copy SKILL.md and replace placeholder with actual path
  local jira_skills_home="${GLOBAL_CONFIG_DIR//\\//}"
  sed "s|{JIRA_SKILLS_HOME}|$jira_skills_home|g" "$skill_source_dir/SKILL.md" > "$skill_target_dir/SKILL.md"
  
  write_success "Installed skill: $skill_name -> $skill_target_dir"
}

install_claude_skills() {
  write_step "Installing skills for Claude Code"
  
  if [ ! -d "$CLAUDE_SKILLS_DIR" ]; then
    mkdir -p "$CLAUDE_SKILLS_DIR"
  fi
  
  for skill in jira-issues jira-projects jira-sprint code-security-check; do
    install_skill "$skill" "$CLAUDE_SKILLS_DIR"
  done
}

install_opencode_skills() {
  write_step "Installing skills for OpenCode"
  
  if [ ! -d "$OPENCODE_SKILLS_DIR" ]; then
    mkdir -p "$OPENCODE_SKILLS_DIR"
  fi
  
  for skill in jira-issues jira-projects jira-sprint code-security-check; do
    install_skill "$skill" "$OPENCODE_SKILLS_DIR"
  done
}

install_opencode_commands() {
  write_step "Installing commands for OpenCode"
  
  if [ ! -d "$OPENCODE_COMMANDS_DIR" ]; then
    mkdir -p "$OPENCODE_COMMANDS_DIR"
  fi
  
  local commands_source_dir="$SOURCE_DIR/commands"
  if [ -d "$commands_source_dir" ]; then
    cp "$commands_source_dir/"* "$OPENCODE_COMMANDS_DIR/"
    write_success "Commands installed to: $OPENCODE_COMMANDS_DIR"
  else
    write_warning "No commands directory found in source"
  fi
}

verify_installation() {
  write_step "Verifying installation"
  
  # Check Node.js
  if check_node; then
    local node_version=$(node --version)
    write_success "Node.js installed: $node_version"
  else
    write_error "Node.js is not installed. Please install Node.js first."
    return 1
  fi
  
  # Check config file
  local config_file="$GLOBAL_CONFIG_DIR/config.json"
  if [ -f "$config_file" ]; then
    local base_url=$(grep -o '"base_url": *"[^"]*"' "$config_file" | cut -d'"' -f4)
    local pat=$(grep -o '"pat": *"[^"]*"' "$config_file" | cut -d'"' -f4)
    if [ -n "$base_url" ] && [ -n "$pat" ]; then
      write_success "Configuration is set up"
    else
      write_warning "Configuration is incomplete (base_url or pat missing)"
    fi
  else
    write_warning "No configuration file found"
  fi
  
  # Check lib files
  if [ -f "$GLOBAL_CONFIG_DIR/lib/jira-client.js" ]; then
    write_success "Library files installed"
  else
    write_error "Library files not found"
    return 1
  fi
  
  return 0
}

# Main installation
echo -e "\n========================================"
echo -e "  ${CYAN}Jira Skills Installer${NC}"
echo -e "========================================"

# Check Node.js
if ! check_node; then
  write_error "Node.js is required but not installed."
  echo -e "   ${YELLOW}Please install Node.js from https://nodejs.org/${NC}"
  exit 1
fi

# Install global config and lib
install_global_config
install_lib_files

# Install skills based on target
case $TARGET in
  claude)
    install_claude_skills
    ;;
  opencode)
    install_opencode_skills
    install_opencode_commands
    ;;
  all)
    install_claude_skills
    install_opencode_skills
    install_opencode_commands
    ;;
  *)
    write_error "Invalid target: $TARGET (use claude, opencode, or all)"
    exit 1
    ;;
esac

# Verify installation
if verify_installation; then
  echo -e "\n========================================"
  echo -e "  ${GREEN}Installation Complete!${NC}"
  echo -e "========================================"
  echo ""
  echo "Installed to:"
  echo "  Config:   $GLOBAL_CONFIG_DIR"
  echo "  Lib:      $GLOBAL_CONFIG_DIR/lib"
  if [ "$TARGET" = "claude" ] || [ "$TARGET" = "all" ]; then
    echo "  Claude:   $CLAUDE_SKILLS_DIR"
  fi
  if [ "$TARGET" = "opencode" ] || [ "$TARGET" = "all" ]; then
    echo "  OpenCode: $OPENCODE_SKILLS_DIR"
  fi
  echo ""
  echo -e "${YELLOW}Restart Claude Code or OpenCode to use the new skills.${NC}"
else
  echo -e "\n${RED}Installation completed with errors. Please check the messages above.${NC}"
  exit 1
fi
