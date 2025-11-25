# Powers of Tau Generation Guide

## Understanding the Process

The **powers of tau** generation is a computationally intensive process that creates the trusted setup parameters for zk-SNARK circuits. This is a one-time process per power level.

### Time Estimates

- **Power 12**: ~5-10 minutes (suitable for testing)
- **Power 14**: ~1-3 hours (recommended for production)
- **Power 16+**: Several hours (for very large circuits)

### Why It Takes So Long

The powers of tau ceremony involves:
1. Generating cryptographic parameters (tau, alpha, beta)
2. Computing elliptic curve points (G1, G2)
3. Creating structured reference strings (SRS)

This is **normal and expected**. The process is CPU-intensive and cannot be significantly accelerated.

## Options

### Option 1: Wait for Completion (Recommended for Production)

**For Power 14:**
- Estimated time: 1-3 hours
- Best for: Production deployments
- Security: Highest

**What to do:**
- Let the script run
- Monitor CPU usage (should be high)
- The process will complete automatically

### Option 2: Use Fast Mode (For Testing)

**For Power 12:**
- Estimated time: 5-10 minutes
- Best for: Development and testing
- Security: Good enough for testing

**Steps:**
1. Press `Ctrl+C` to stop the current process
2. Run: `.\scripts\generate-groth16-verifier-fast.ps1`
3. This uses Power 12 which generates much faster

**Note:** Power 12 is sufficient for testing but Power 14+ is recommended for production.

### Option 3: Use Pre-Generated Powers of Tau

If you have access to pre-generated powers of tau files:

1. Download from trusted sources (e.g., Hermez ceremony)
2. Place the file in `circuits/` folder as `pot14_final.ptau`
3. The script will automatically detect and use it

**Security Note:** Only use powers of tau from trusted, audited ceremonies.

## Monitoring Progress

The script shows debug output indicating progress:
- `[DEBUG] snarkJS: Calculating First Challenge Hash` - Initial setup
- `[DEBUG] snarkJS: Calculate Initial Hash: tauG1` - Generating tau parameters
- Hash values - Progress indicators

**The process is working correctly if you see these messages.**

## Troubleshooting

### Process Appears Stuck

**This is normal!** The process is CPU-bound and may appear frozen, but it's working.

**Check if it's actually running:**
```powershell
Get-Process | Where-Object {$_.CPU -gt 10} | Select-Object ProcessName, CPU
```

If you see `node` or `snarkjs` processes with high CPU, it's working.

### Out of Memory

If you get memory errors:
- Close other applications
- Use Power 12 instead of Power 14
- Increase virtual memory if possible

### Want to Resume Later

The process cannot be paused/resumed. If interrupted:
- Delete partial files: `circuits/pot14_0000.ptau`, `circuits/pot14_0001.ptau`
- Restart the script
- Or use the fast mode script for quicker completion

## Recommendation

**For Development/Testing:**
- Use `generate-groth16-verifier-fast.ps1` (Power 12)
- Takes 5-10 minutes
- Sufficient for testing proof generation

**For Production:**
- Use `generate-groth16-verifier.ps1` (Power 14)
- Let it run for 1-3 hours
- Provides production-grade security

## After Generation

Once complete, the powers of tau file (`pot14_final.ptau`) can be reused for:
- Future circuit compilations
- Team members (share the file securely)
- CI/CD pipelines

**Store this file securely** - it's needed for all future verifier generations.

