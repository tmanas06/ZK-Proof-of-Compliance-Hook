import React from 'react'
import ReactDOM from 'react-dom/client'
import './utils/suppressExtensionErrors' // Suppress harmless browser extension errors
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)

