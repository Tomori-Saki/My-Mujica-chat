import { defineStore } from 'pinia'
import { ref } from 'vue'
import { saveCredentials, loadCredentials, clearCredentials } from '../utils/crypto'

export const useAuthStore = defineStore('auth', () => {
  const modelUrl = ref('')
  const modelName = ref('')
  const apiKey = ref('')       // 内存中明文（仅当前会话）
  const isLoggedIn = ref(false)

  /**
   * 登录：加密存储凭证，标记已登录。
   */
  async function login(url, name, key) {
    modelUrl.value = url
    modelName.value = name
    apiKey.value = key
    isLoggedIn.value = true
    await saveCredentials({ url, name, key })
  }

  /**
   * 从 localStorage 恢复加密凭证（用于一键登录）。
   */
  async function restore() {
    const creds = await loadCredentials()
    if (creds && creds.url && creds.key) {
      modelUrl.value = creds.url
      modelName.value = creds.name || ''
      apiKey.value = creds.key
      isLoggedIn.value = true
      return true
    }
    return false
  }

  /**
   * 登出：清除凭证。
   */
  function logout() {
    modelUrl.value = ''
    modelName.value = ''
    apiKey.value = ''
    isLoggedIn.value = false
    clearCredentials()
  }

  return { modelUrl, modelName, apiKey, isLoggedIn, login, restore, logout }
})
