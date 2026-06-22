<script setup>
import { useAuthStore } from '../stores/auth'

defineProps({
  centerText: { type: String, default: '' },
  showBack: { type: Boolean, default: false }
})

const emit = defineEmits(['back'])
const authStore = useAuthStore()
</script>

<template>
  <header class="flex items-center justify-between h-14 px-5 border-b shrink-0"
          style="background: rgba(20,18,12,0.9); border-color: var(--line);">
    <!-- 左侧：项目名 -->
    <div class="flex items-center gap-3 min-w-[140px]">
      <button v-if="showBack" @click="$emit('back')"
              class="text-xs px-3 py-1.5 rounded-xl border transition-all hover:border-gold"
              style="color: var(--text); border-color: var(--line);">
        ← 返回
      </button>
      <span class="text-lg tracking-wider" style="font-family: var(--font-display);">BanGChat</span>
    </div>

    <!-- 中间：页面标题 -->
    <div class="flex-1 text-center text-sm tracking-wide" style="color: var(--gold);">
      {{ centerText }}
    </div>

    <!-- 右侧：当前模型 -->
    <div class="min-w-[140px] text-right text-xs" style="color: var(--muted);">
      {{ authStore.modelName || '未连接' }}
    </div>
  </header>
</template>
