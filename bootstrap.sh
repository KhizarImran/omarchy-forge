#!/bin/bash

set -e

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================="
echo "   Omarchy Forge - Bootstrapper"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install all applications
install_apps() {
    log_info "Installing applications..."
    
    for app_script in "$FORGE_DIR"/apps/*.sh; do
        if [ -f "$app_script" ]; then
            log_info "Running $(basename "$app_script")..."
            bash "$app_script"
        fi
    done
    
    log_success "Applications installed"
}

# Deploy configurations
deploy_configs() {
    log_info "Deploying configurations..."
    
    if [ -d "$FORGE_DIR/configs" ]; then
        for config in "$FORGE_DIR"/configs/*; do
            if [ -e "$config" ]; then
                config_name=$(basename "$config")
                target="$HOME/.config/$config_name"
                
                if [ -e "$target" ]; then
                    log_info "Backing up existing $config_name..."
                    cp -r "$target" "$target.backup.$(date +%Y%m%d%H%M%S)"
                fi
                
                log_info "Deploying $config_name..."
                cp -r "$config" "$target"
            fi
        done
    fi
    
    log_success "Configurations deployed"
}

# Setup Omarchy hooks
setup_hooks() {
    log_info "Setting up Omarchy hooks..."
    
    if [ -d "$FORGE_DIR/hooks" ]; then
        for hook in "$FORGE_DIR"/hooks/*; do
            if [ -f "$hook" ]; then
                hook_name=$(basename "$hook")
                target="$HOME/.config/omarchy/hooks/$hook_name"
                
                log_info "Installing hook: $hook_name..."
                cp "$hook" "$target"
                chmod +x "$target"
            fi
        done
    fi
    
    log_success "Hooks installed"
}

# Run utility scripts
run_scripts() {
    log_info "Running utility scripts..."
    
    for script in "$FORGE_DIR"/scripts/*.sh; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            log_info "Running $(basename "$script")..."
            bash "$script"
        fi
    done
    
    log_success "Scripts executed"
}

# Main execution
main() {
    echo "Starting Omarchy Forge setup..."
    echo ""
    
    # Run each step
    install_apps
    echo ""
    deploy_configs
    echo ""
    setup_hooks
    echo ""
    run_scripts
    echo ""
    
    log_success "Omarchy Forge setup complete!"
    echo ""
    echo "Your Omarchy environment has been configured."
}

# Show usage if --help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --apps-only      Install applications only"
    echo "  --configs-only   Deploy configurations only"
    echo "  --hooks-only     Setup hooks only"
    echo "  --scripts-only   Run scripts only"
    echo "  -h, --help       Show this help message"
    exit 0
fi

# Handle options
case "$1" in
    --apps-only)
        install_apps
        ;;
    --configs-only)
        deploy_configs
        ;;
    --hooks-only)
        setup_hooks
        ;;
    --scripts-only)
        run_scripts
        ;;
    *)
        main
        ;;
esac
