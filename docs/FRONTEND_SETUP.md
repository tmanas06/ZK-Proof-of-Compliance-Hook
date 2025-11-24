# Frontend Setup Guide

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- npm or yarn
- MetaMask browser extension
- Anvil running on `http://localhost:8545`

### Installation

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies (use --legacy-peer-deps to fix version conflicts)
npm install --legacy-peer-deps

# Start development server
npm run dev
```

The frontend will be available at `http://localhost:5173` (or the port shown in terminal).

## 🔧 Configuration

### Update Contract Addresses

Edit `frontend/src/App.tsx` and update the addresses:

```typescript
const HOOK_ADDRESS = '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853'
const VERIFIER_ADDRESS = '0x0165878A594ca255338adfa4d48449f69242Eb8F'
```

### Configure Network

The frontend connects to `http://localhost:8545` by default. To change:

1. Update `frontend/src/App.tsx`
2. Modify the provider initialization:
   ```typescript
   const provider = new ethers.BrowserProvider(window.ethereum)
   // Or for custom RPC:
   const provider = new ethers.JsonRpcProvider('YOUR_RPC_URL')
   ```

## 📱 Using the Frontend

### 1. Connect Wallet

1. Click "Connect Wallet" button
2. Approve connection in MetaMask
3. Ensure you're on the correct network (localhost:8545)

### 2. Check Compliance Status

- The app automatically checks if your wallet is marked as compliant
- Green checkmark = Compliant ✅
- Red X = Not Compliant ❌

### 3. Generate Proof

1. Click "Generate Proof" button
2. A mock ZK proof will be created
3. Proof details will be displayed

### 4. Submit Proof

1. Click "Submit Proof" button
2. Approve transaction in MetaMask
3. Wait for confirmation
4. Proof status will update

### 5. Interact with Pool

Once proof is submitted:
- You can simulate swap operations
- You can simulate liquidity provision
- All operations will check your proof first

## 🛠️ Development

### Project Structure

```
frontend/
├── src/
│   ├── App.tsx              # Main application component
│   ├── components/
│   │   ├── WalletConnection.tsx
│   │   ├── ComplianceStatus.tsx
│   │   ├── ProofGenerator.tsx
│   │   ├── PoolInteraction.tsx
│   │   ├── EigenLayerStatus.tsx
│   │   └── FhenixIntegration.tsx
│   └── main.tsx            # Entry point
├── package.json
└── vite.config.ts
```

### Available Scripts

```bash
# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Lint code
npm run lint
```

### Adding New Features

1. Create component in `src/components/`
2. Import and use in `App.tsx`
3. Add styling in corresponding `.css` file

## 🔍 Troubleshooting

### Wallet Won't Connect
- **Issue**: MetaMask not detected
- **Solution**: Ensure MetaMask is installed and enabled

### Wrong Network
- **Issue**: Connected to wrong network
- **Solution**: Switch to localhost:8545 in MetaMask

### Contract Calls Fail
- **Issue**: Contract addresses incorrect
- **Solution**: Update addresses in `App.tsx`

### Proof Submission Fails
- **Issue**: User not marked as compliant
- **Solution**: Run `forge script script/InteractWithContracts.s.sol` to set user as compliant

## 📦 Building for Production

```bash
# Build
npm run build

# Output will be in dist/
# Deploy dist/ to your hosting service
```

## 🎨 Customization

### Styling
- Edit `src/App.css` for global styles
- Edit component-specific `.css` files for component styles

### Components
- All components are in `src/components/`
- Each component is self-contained with its own CSS

### Contract Interaction
- Update ABIs in `App.tsx` if contract interfaces change
- In production, import ABIs from `out/` directory

## 🔐 Security Notes

⚠️ **Important**: This is a development/demo frontend. For production:

1. **Validate all inputs** on frontend
2. **Never trust frontend validation alone** - always verify on-chain
3. **Use environment variables** for sensitive data
4. **Implement proper error handling**
5. **Add loading states** for better UX
6. **Consider using wagmi** for better wallet integration

## 📚 Next Steps

1. **Integrate Real ABIs**: Import from `out/` directory
2. **Add Error Handling**: Better user feedback
3. **Add Loading States**: Show transaction progress
4. **Add Transaction History**: Show past proofs and transactions
5. **Improve UI/UX**: Better design and user experience

---

For more information, see the main [README.md](../README.md) and [USER_GUIDE.md](USER_GUIDE.md).

