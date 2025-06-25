#!/bin/bash
# AUR Package Installer Script
# Usage: ./aur_install.sh [username] [pkglist.txt]

set -euo pipefail

# Configuration
USER="${1:-$USER}"  # Default to current user
PKGLIST="${2:-aur_pkglist.txt}"
BUILD_DIR="/home/$USER/aur_builds"
LOG_FILE="/home/$USER/aur_install.log"

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n=== AUR Installation Started $(date) ==="

# Verify user exists
if ! id -u "$USER" >/dev/null 2>&1; then
  echo "Error: User $USER does not exist"
  exit 1
fi

# Create build directory
echo "Creating build directory..."
sudo mkdir -p "$BUILD_DIR"
sudo chown "$USER:$USER" "$BUILD_DIR"
sudo chmod 755 "$BUILD_DIR"

# Process package list
echo "Processing package list..."
if [[ ! -f "$PKGLIST" ]]; then
  echo "Error: Package list $PKGLIST not found"
  exit 1
fi

# Read and validate package list
mapfile -t packages < <(grep -E '^[a-zA-Z0-9-]+$' "$PKGLIST")

# Install packages
changed=false
for pkg in "${packages[@]}"; do
  pkg_name="${pkg%-bin}"  # Handle -bin packages
  pkg_dir="$BUILD_DIR/$pkg"
  
  # Skip if binary already exists
  if command -v "$pkg_name" >/dev/null 2>&1; then
    echo "Skipping $pkg (already installed)"
    continue
  fi

  echo "Installing $pkg..."
  
  # Clone and build
  if [[ ! -d "$pkg_dir" ]]; then
    sudo -u "$USER" git clone "https://aur.archlinux.org/$pkg.git" "$pkg_dir"
  fi

  if (cd "$pkg_dir" && sudo -u "$USER" makepkg -si --noconfirm --needed); then
    changed=true
    echo "Successfully installed $pkg"
  else
    echo "Failed to install $pkg"
    # Clean failed build
    rm -rf "$pkg_dir"
  fi
done

# Cleanup if successful
if $changed; then
  echo "Cleaning up build directory..."
  sudo rm -rf "$BUILD_DIR"
fi

echo "=== AUR Installation Completed $(date) ==="