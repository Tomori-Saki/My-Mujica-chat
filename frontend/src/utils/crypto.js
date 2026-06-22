/**
 * API Key 加密存储工具。
 * 使用 Web Crypto API (AES-GCM) 对 APIKey 加密后存入 localStorage，
 * 读取时自动解密。密钥基于浏览器指纹 + 固定盐值派生。
 */

const STORAGE_KEY = 'bangchat_secure'
const SALT = 'bangchat_v1_salt_2026'

/**
 * 派生 AES-GCM 加密密钥（基于固定盐值）。
 */
async function deriveKey() {
  const enc = new TextEncoder()
  const keyMaterial = await crypto.subtle.importKey(
    'raw', enc.encode(SALT), 'PBKDF2', false, ['deriveKey']
  )
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt: enc.encode(SALT), iterations: 100000, hash: 'SHA-256' },
    keyMaterial,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  )
}

/**
 * 加密并保存凭证到 localStorage。
 */
export async function saveCredentials(credentials) {
  const key = await deriveKey()
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const enc = new TextEncoder()
  const ciphertext = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    enc.encode(JSON.stringify(credentials))
  )
  // Base64(IV + ciphertext)
  const combined = new Uint8Array(iv.length + ciphertext.byteLength)
  combined.set(iv)
  combined.set(new Uint8Array(ciphertext), iv.length)
  localStorage.setItem(STORAGE_KEY, btoa(String.fromCharCode(...combined)))
}

/**
 * 从 localStorage 读取并解密凭证。
 * @returns 凭证对象或 null
 */
export async function loadCredentials() {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (!stored) return null
  try {
    const key = await deriveKey()
    const combined = Uint8Array.from(atob(stored), c => c.charCodeAt(0))
    const iv = combined.slice(0, 12)
    const ciphertext = combined.slice(12)
    const dec = new TextDecoder()
    const plaintext = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv },
      key,
      ciphertext
    )
    return JSON.parse(dec.decode(plaintext))
  } catch {
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}

/**
 * 清除保存的凭证。
 */
export function clearCredentials() {
  localStorage.removeItem(STORAGE_KEY)
}
