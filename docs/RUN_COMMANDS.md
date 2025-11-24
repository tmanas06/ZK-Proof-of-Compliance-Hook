# Run These Commands in Git Bash

Since Foundry only works in Git Bash, run these commands there:

## Step 1: Install forge-std

```bash
cd ~/Desktop/uniswap
forge install foundry-rs/forge-std
```

## Step 2: Build Contracts

```bash
forge build
```

## Step 3: Run Tests

```bash
forge test
```

## Step 4: Run Tests with Verbose Output

```bash
forge test -vvv
```

## OR: Run All at Once

I've created a setup script. Run this in Git Bash:

```bash
cd ~/Desktop/uniswap
bash setup-forge-std.sh
```

This will:
1. Initialize git (if needed)
2. Install forge-std
3. Build contracts
4. Run tests
5. Run tests with verbose output

