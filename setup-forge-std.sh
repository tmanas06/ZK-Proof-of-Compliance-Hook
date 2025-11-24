#!/bin/bash

# Setup script to install forge-std and run tests
# Run this in Git Bash: bash setup-forge-std.sh

echo "Setting up forge-std library..."

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
fi

# Install forge-std
echo "Installing forge-std..."
forge install foundry-rs/forge-std

# Build contracts
echo ""
echo "Building contracts..."
forge build

# Run tests
echo ""
echo "Running tests..."
forge test

# Run tests with verbose output
echo ""
echo "Running tests with verbose output..."
forge test -vvv

echo ""
echo "Done!"

