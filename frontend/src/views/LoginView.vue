<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const url = ref('')
const key = ref('')
const model = ref('')
const errorMsg = ref('')
const loading = ref(false)
const remember = ref(false)

onMounted(async () => {
  const restored = await authStore.restore()
  if (restored) {
    // 已有保存的凭证，自动登录跳转
    url.value = authStore.modelUrl
    model.value = authStore.modelName
    remember.value = true
    router.push({ name: 'bands' })
  }
})

async function handleLogin() {
  errorMsg.value = ''
  if (!url.value.trim()) { errorMsg.value = '请输入模型 API 地址'; return }
  if (!key.value.trim()) { errorMsg.value = '请输入 API Key'; return }

  loading.value = true
  try {
    await authStore.login(url.value.trim(), model.value.trim(), key.value.trim())
    router.push({ name: 'bands' })
  } catch (e) {
    errorMsg.value = '加密存储失败: ' + e.message
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex items-center justify-center h-full">
    <div class="w-[420px] max-w-[90vw] rounded-2xl p-8 shadow-2xl flex flex-col gap-5"
         style="background: rgba(18,16,12,0.95); border: 1px solid var(--line);">
      <h2 class="m-0 text-2xl tracking-wide" style="font-family: var(--font-display);">连接 AI</h2>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs" style="color: var(--muted);">模型 API 地址</label>
        <input v-model="url" placeholder="https://api.openai.com/v1"
               class="w-full px-3.5 py-2.5 rounded-xl border outline-none text-sm"
               style="background: rgba(8,8,6,0.9); border-color: rgba(216,192,118,0.2); color: var(--text);" />
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs" style="color: var(--muted);">API Key</label>
        <input v-model="key" type="password" placeholder="sk-..."
               class="w-full px-3.5 py-2.5 rounded-xl border outline-none text-sm"
               style="background: rgba(8,8,6,0.9); border-color: rgba(216,192,118,0.2); color: var(--text);" />
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs" style="color: var(--muted);">模型名称</label>
        <input v-model="model" placeholder="gpt-4o-mini"
               class="w-full px-3.5 py-2.5 rounded-xl border outline-none text-sm"
               style="background: rgba(8,8,6,0.9); border-color: rgba(216,192,118,0.2); color: var(--text);" />
      </div>

      <p class="text-xs leading-relaxed" style="color: var(--muted);">
        API Key 使用 AES-256-GCM 加密存储，仅保存在本浏览器中。
      </p>

      <div v-if="errorMsg" class="text-xs py-2 px-3 rounded-lg"
           style="color: var(--danger); background: rgba(196,107,107,0.12);">
        {{ errorMsg }}
      </div>

      <button @click="handleLogin" :disabled="loading"
              class="btn btn-primary w-full py-3 text-base">
        {{ loading ? '连接中...' : '登录' }}
      </button>
    </div>
  </div>
</template>
