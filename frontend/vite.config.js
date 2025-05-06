import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'


// import { defineConfig } from 'vite'
// import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true, 
    port: 5173, 
    // allowedHosts: ['frontend'],
    allowedHosts: true,
    cors: true, 
    strictPort: true, 
    open: false, 
  },
})

