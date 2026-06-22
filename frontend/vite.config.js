import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  build: {
    // 关键核心修改：将打包产物直接输出到后端的静态资源文件夹
    outDir: '../backend/src/main/resources/static',
    emptyOutDir: true // 打包前清空该目录
  }
})