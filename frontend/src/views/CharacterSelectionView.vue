<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import TopBar from '../components/TopBar.vue'

const props = defineProps({ bandId: String })
const router = useRouter()

const bandName = computed(() => {
  const map = { crychic: 'CRYCHIC', mygo: 'MyGO!!!!!', avemujica: 'Ave Mujica' }
  return map[props.bandId] || props.bandId
})

const allCharacters = [
  { id: 'tomori', name: '高松灯', initials: 'TT', band: 'mygo', crychic: true, color: '#2d2f3a' },
  { id: 'anon', name: '千早爱音', initials: 'AC', band: 'mygo', crychic: false, color: '#c97234' },
  { id: 'rana', name: '要乐奈', initials: 'RK', band: 'mygo', crychic: false, color: '#d6c27a' },
  { id: 'soyo', name: '长崎素世', initials: 'SN', band: 'mygo', crychic: true, color: '#a88663' },
  { id: 'taki', name: '椎名立希', initials: 'TS', band: 'mygo', crychic: true, color: '#1f2024' },
  { id: 'sakiko', name: '丰川祥子', initials: 'ST', band: 'avemujica', crychic: true, color: '#a7acb7' },
  { id: 'mutsumi', name: '若叶睦', initials: 'MW', band: 'avemujica', crychic: true, color: '#3b2b59' },
  { id: 'umiri', name: '八幡海铃', initials: 'UY', band: 'avemujica', crychic: false, color: '#283a66' },
  { id: 'uika', name: '三角初华', initials: 'UM', band: 'avemujica', crychic: false, color: '#d59ab2' },
  { id: 'nyamu', name: '祐天寺喵梦', initials: 'NY', band: 'avemujica', crychic: false, color: '#d8b45d' }
]

const characters = computed(() => {
  if (props.bandId === 'crychic') {
    return allCharacters.filter(c => c.crychic)
  }
  return allCharacters.filter(c => c.band === props.bandId)
})

function selectCharacter(char) {
  router.push({ name: 'chat', params: { bandId: props.bandId, characterId: char.id } })
}

function goBack() {
  router.push({ name: 'bands' })
}
</script>

<template>
  <div class="flex flex-col h-full">
    <TopBar :centerText="bandName" :showBack="true" @back="goBack" />

    <!-- PC: 网格 5 列 / 移动端: 单列纵向排列 -->
    <div class="char-grid flex-1 grid gap-3 p-6 content-start overflow-y-auto">
      <div v-for="char in characters" :key="char.id"
           @click="selectCharacter(char)"
           class="char-card flex items-center gap-4 p-4 rounded-2xl border cursor-pointer transition-all duration-200 hover:-translate-y-1.5 hover:shadow-xl"
           style="background: rgba(20,18,12,0.8); border-color: var(--line);">
        <div class="w-12 h-12 rounded-full flex items-center justify-center text-sm font-bold shadow-inner tracking-wider shrink-0"
             style="background: radial-gradient(circle at top, rgba(216,192,118,0.15), rgba(0,0,0,0.4));">
          <span style="color: var(--gold); font-family: var(--font-display);">
            {{ char.initials }}
          </span>
        </div>
        <span class="text-sm tracking-wide" style="color: var(--text);">{{ char.name }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* PC: 最多 5 列网格，卡片纵向居中 */
.char-grid {
  grid-template-columns: repeat(5, 1fr);
}

.char-card {
  flex-direction: column;
  justify-content: center;
  text-align: center;
  min-height: 140px;
}

/* 移动端: 单列，横向排列（头像左 + 名字右） */
@media (max-width: 639px) {
  .char-grid {
    grid-template-columns: 1fr;
  }
  .char-card {
    flex-direction: row;
    min-height: auto;
    text-align: left;
  }
}
</style>
