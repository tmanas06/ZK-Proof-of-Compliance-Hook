# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Considerations

### Known Limitations

1. **Mock Brevis Verifier**: The current implementation uses a mock Brevis verifier for demonstration. In production, replace with actual Brevis Network contracts.

2. **Proof Generation**: Proof generation is simulated in the frontend. In production, integrate with Brevis SDK and backend services.

3. **Admin Controls**: The admin has significant control over the hook. Ensure admin keys are stored securely.

### Security Best Practices

1. **Access Control**: 
   - Admin functions are protected with `onlyAdmin` modifier
   - Hook functions can only be called by the pool manager
   - Users can only submit proofs for themselves

2. **Replay Protection**:
   - Proofs can only be used once
   - Proof hash tracking prevents reuse

3. **Input Validation**:
   - All inputs are validated before processing
   - Proof expiration is checked (30 days)

4. **Error Handling**:
   - Comprehensive error messages
   - Proper revert conditions

## Reporting a Vulnerability

If you discover a security vulnerability, please follow these steps:

1. **Do NOT** open a public issue
2. Email security details to: [security@example.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work with you to address the issue.

## Security Audit

Before deploying to mainnet:

1. ✅ Code review completed
2. ⚠️ External security audit recommended
3. ⚠️ Formal verification recommended for critical paths
4. ⚠️ Bug bounty program recommended

## Responsible Disclosure

We follow responsible disclosure practices. Security researchers who report vulnerabilities will be credited (if desired) after the issue is resolved.

