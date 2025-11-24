/// <reference types="vite/client" />

interface Window {
  ethereum?: {
    isMetaMask?: boolean
    request: (args: { method: string; params?: any[] }) => Promise<any>
    send: (method: string, params?: any[]) => Promise<any>
  }
}

