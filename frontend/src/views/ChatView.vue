<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import TopBar from '../components/TopBar.vue'

const props = defineProps({ bandId: String, characterId: String })
const router = useRouter()
const authStore = useAuthStore()

const bandName = computed(() => {
  const map = { crychic: 'CRYCHIC', mygo: 'MyGO!!!!!', avemujica: 'Ave Mujica' }
  return map[props.bandId] || props.bandId
})

const charName = computed(() => {
  const map = {
    tomori: '高松灯', anon: '千早爱音', rana: '要乐奈', soyo: '长崎素世', taki: '椎名立希',
    sakiko: '丰川祥子', mutsumi: '若叶睦', umiri: '八幡海铃', uika: '三角初华', nyamu: '祐天寺喵梦'
  }
  return map[props.characterId] || props.characterId
})

const centerTitle = computed(() => `${bandName.value} - ${charName.value}`)

// 消息存储：每条 { type, sender, content, timestamp }
// type: 'user' | 'stream' | 'reply' | 'event'
const messages = ref([])
const inputText = ref('')
const isConnected = ref(false)
const chatContainer = ref(null)
let ws = null
let credentialsSent = false
const sessionId = ref('session-' + Math.random().toString(36).slice(2, 10))

function connectWs() {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  const wsUrl = `${protocol}//${window.location.host}/ws/chat/${sessionId.value}`
  ws = new WebSocket(wsUrl)

  ws.onopen = () => {
    isConnected.value = true
    credentialsSent = false
  }
  ws.onclose = () => { isConnected.value = false }

  ws.onmessage = (event) => {
    try {
      const msg = JSON.parse(event.data)
      // 跳过空流片段和纯事件
      if (msg.type === 'stream' && (!msg.content || msg.content.length === 0)) return

      // 流式 token：追加到最后一个 stream 或 reply 消息中
      if (msg.type === 'stream') {
        const last = messages.value[messages.value.length - 1]
        if (last && last.type === 'stream') {
          last.content += msg.content
        } else {
          messages.value.push({ type: 'stream', sender: msg.sender || charName.value,
            content: msg.content, timestamp: msg.timestamp || '' })
        }
        scrollToBottom()
        return
      }

      // 完整回复：替换之前的 stream 消息
      if (msg.type === 'reply') {
        // 移除所有 stream 片段
        while (messages.value.length > 0 && messages.value[messages.value.length - 1].type === 'stream') {
          messages.value.pop()
        }
        messages.value.push({ type: 'reply', sender: charName.value,
          content: msg.content, timestamp: msg.timestamp || '' })
        scrollToBottom()
        return
      }

      // 错误事件
      if (msg.type === 'event') {
        messages.value.push({ type: 'event', sender: '系统',
          content: msg.content, timestamp: msg.timestamp || '' })
        scrollToBottom()
        return
      }
    } catch { /* ignore malformed */ }
  }
}

function sendMessage() {
  const text = inputText.value.trim()
  if (!text || !ws || ws.readyState !== WebSocket.OPEN) return

  const payload = {
    content: text,
    sender: 'user',
    type: 'message',
    bandId: props.bandId,
    characterId: props.characterId
  }

  // 首次消息携带凭证
  if (!credentialsSent && authStore.apiKey) {
    payload.modelUrl = authStore.modelUrl
    payload.apiKey = authStore.apiKey
    payload.modelName = authStore.modelName
    credentialsSent = true
  }

  ws.send(JSON.stringify(payload))

  // 仅在前端本地显示用户消息（后端不回显）
  messages.value.push({ type: 'user', sender: '你', content: text, timestamp: new Date().toISOString() })
  inputText.value = ''
  scrollToBottom()
}

function handleKeydown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    sendMessage()
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (chatContainer.value) {
      chatContainer.value.scrollTop = chatContainer.value.scrollHeight
    }
  })
}

// 重新生成：删除最后一条 reply 及其 stream，重发最后一条 user 消息
function regenerate() {
  // 移除最后一条 reply
  while (messages.value.length > 0) {
    const last = messages.value[messages.value.length - 1]
    if (last.type === 'reply' || last.type === 'stream') {
      messages.value.pop()
    } else {
      break
    }
  }
  // 找到最后一条用户消息重发
  for (let i = messages.value.length - 1; i >= 0; i--) {
    if (messages.value[i].type === 'user') {
      const payload = { content: messages.value[i].content, sender: 'user',
        type: 'message', bandId: props.bandId, characterId: props.characterId }
      ws?.send(JSON.stringify(payload))
      break
    }
  }
}

// 回退：删除最后一对 user+reply
function rollback() {
  // 移除所有 stream + reply
  while (messages.value.length > 0) {
    const last = messages.value[messages.value.length - 1]
    if (last.type === 'reply' || last.type === 'stream') {
      messages.value.pop()
    } else {
      break
    }
  }
  // 移除最后一条 user
  if (messages.value.length > 0 && messages.value[messages.value.length - 1].type === 'user') {
    messages.value.pop()
  }
}

function goBack() {
  router.push({ name: 'bands' })
}

onMounted(() => { connectWs() })
onUnmounted(() => { ws?.close() })
watch(() => messages.value.length, () => scrollToBottom())
</script>

<template>
  <div class="flex flex-col h-full">
    <TopBar :centerText="centerTitle" :showBack="true" @back="goBack" />

    <!-- 消息列表 -->
    <div ref="chatContainer" class="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-2"
         style="background: radial-gradient(circle at 20% 15%, rgba(216,192,118,0.12), transparent 55%),
                      radial-gradient(circle at 80% 85%, rgba(216,192,118,0.1), transparent 60%),
                      rgba(12,11,9,0.6);">
      <div v-for="(msg, idx) in messages" :key="idx"
           :class="['flex flex-col w-full', msg.type === 'user' ? 'items-end' : 'items-start']">
        <!-- 气泡 -->
        <div :class="['max-w-[75%] px-4 py-3 rounded-2xl border text-sm leading-relaxed',
                      msg.type === 'user'
                        ? 'bg-gold/10 border-gold/30'
                        : 'bg-black/40 border-white/5']">
          <div class="text-xs mb-1.5" style="color: var(--muted);">
            {{ msg.sender }}
          </div>
          <div v-html="msg.content.replace(/\n/g, '<br/>')"></div>
        </div>

        <!-- AI 回复的操作按钮 -->
        <div v-if="msg.type === 'reply'" class="flex gap-1 mt-1 px-1.5">
          <button v-if="idx === messages.length - 1"
                  @click="regenerate"
                  title="重新生成"
                  class="w-5 h-5 p-0 rounded-full border flex items-center justify-center transition-colors hover:text-gold hover:border-gold"
                  style="background: rgba(18,18,14,0.85); border-color: rgba(216,192,118,0.2); color: var(--muted); cursor: pointer;">
            <svg viewBox="0 0 24 24" class="w-2.5 h-2.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="23 4 23 10 17 10"/>
              <path d="M20.5 15a9 9 0 1 1 2.12-9.36"/>
            </svg>
          </button>
          <button @click="rollback"
                  title="回退到此"
                  class="w-5 h-5 p-0 rounded-full border flex items-center justify-center transition-colors hover:text-gold hover:border-gold"
                  style="background: rgba(18,18,14,0.85); border-color: rgba(216,192,118,0.2); color: var(--muted); cursor: pointer;">
            <svg viewBox="0 0 24 24" class="w-2.5 h-2.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="9 14 4 9 9 4"/>
              <path d="M20 20v-7a4 4 0 0 0-4-4H4"/>
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- 输入区 -->
    <div class="flex gap-3 px-4 py-3 border-t shrink-0"
         style="background: rgba(16,15,11,0.95); border-color: var(--line);">
      <textarea v-model="inputText" @keydown="handleKeydown"
                placeholder="输入消息，Enter 发送，Shift+Enter 换行"
                class="flex-1 min-h-[42px] max-h-[120px] resize-none rounded-xl border px-3.5 py-2.5 outline-none text-sm"
                style="background: rgba(8,8,6,0.9); border-color: rgba(216,192,118,0.2); color: var(--text);"
                rows="1"></textarea>
      <button @click="sendMessage" class="btn btn-primary self-end" :disabled="!isConnected">
        发送
      </button>
    </div>
  </div>
</template>
