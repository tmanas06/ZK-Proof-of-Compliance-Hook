# How to Use Foundry - Important Notes

## ✅ Foundry is Installed!

Foundry version **1.4.4-stable** is successfully installed in your Git Bash environment.

## ⚠️ Important: Use Git Bash, Not PowerShell

Foundry commands (`forge`, `cast`, `anvil`) only work in **Git Bash**, not in PowerShell.

### Why?
- Foundry is installed in your Git Bash PATH (`~/.foundry/bin`)
- PowerShell has a different PATH and doesn't see Git Bash executables
- This is normal and expected behavior

## 🚀 How to Use Foundry

### Step 1: Open Git Bash
- Open Git Bash terminal (not PowerShell)
- Navigate to your project:
  ```bash
  cd ~/Desktop/uniswap
  ```

### Step 2: Compile Contracts
```bash
forge build
```

### Step 3: Run Tests
```bash
forge test
```

### Step 4: Run Tests with Verbose Output
```bash
forge test -vvv
```

### Step 5: Format Code
```bash
forge fmt
```

## 📋 Common Commands

```bash
# Compile
forge build

# Test
forge test
forge test -vvv          # Verbose
forge test --gas-report  # With gas report

# Deploy
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# Start local node
anvil

# Format code
forge fmt

# Install dependencies (if needed)
forge install <package>
```

## 🔧 If You Want Foundry in PowerShell

If you really need Foundry in PowerShell, you can:

1. **Add to PowerShell PATH:**
   ```powershell
   $env:Path += ";$env:USERPROFILE\.foundry\bin"
   ```

2. **Or create a PowerShell alias:**
   ```powershell
   function forge { & bash -c "forge $args" }
   ```

But it's **much easier** to just use Git Bash for Foundry commands!

## ✅ Quick Test

In Git Bash, run:
```bash
cd ~/Desktop/uniswap
forge build
```

This should compile all your contracts successfully!

