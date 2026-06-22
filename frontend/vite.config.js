import { fileURLToPath, URL } from 'node:url' // 👉 关键：补上这行导入
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  // 保持你原有的插件配置，别忘了把 tailwindcss() 也加上（我看你之前写在 import 里但下面没传）
  plugins: [
    vue(),
    tailwindcss()
  ],
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