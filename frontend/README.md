# Frontend - ZK Proof of Compliance

React + TypeScript frontend for the ZK Proof of Compliance Uniswap v4 Hook.

## 🚀 Quick Start

### Install Dependencies

```bash
npm install --legacy-peer-deps
```

**Note**: We use `--legacy-peer-deps` because `wagmi@2.x` requires `viem@2.x`, but we're using `viem@2.0.0` which has some peer dependency conflicts. This flag allows npm to install despite the conflicts.

### Start Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:5173` (or the port shown in terminal).

## 📝 Configuration

### Update Contract Addresses

Edit `src/App.tsx` and update:

```typescript
const HOOK_ADDRESS = '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853'
const VERIFIER_ADDRESS = '0x0165878A594ca255338adfa4d48449f69242Eb8F'
```

## 🛠️ Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 📦 Dependencies

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Ethers.js 6** - Ethereum interaction
- **Viem 2** - Ethereum utilities
- **Wagmi 2** - React hooks for Ethereum
- **Lucide React** - Icons

## 🔧 Troubleshooting

### Dependency Conflicts

If you see dependency conflicts, use:
```bash
npm install --legacy-peer-deps
```

### Port Already in Use

If port 5173 is taken, Vite will automatically use the next available port.

### MetaMask Not Detected

- Ensure MetaMask is installed
- Refresh the page
- Check browser console for errors

### Contract Calls Fail

- Verify contract addresses are correct
- Ensure contracts are deployed
- Check that Anvil is running on localhost:8545

## 📚 More Information

See the main [README.md](../README.md) and [docs/FRONTEND_SETUP.md](../docs/FRONTEND_SETUP.md) for more details.

