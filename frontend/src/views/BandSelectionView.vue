<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import TopBar from '../components/TopBar.vue'

const router = useRouter()
const hovered = ref(null)

const bands = [
  { id: 'crychic', name: 'CRYCHIC', gradient: 'linear-gradient(135deg, rgba(90,70,140,0.55), rgba(40,30,70,0.7))' },
  { id: 'mygo', name: 'MyGO!!!!!', gradient: 'linear-gradient(135deg, rgba(70,110,210,0.5), rgba(30,50,100,0.7))' },
  { id: 'avemujica', name: 'Ave Mujica', gradient: 'linear-gradient(135deg, rgba(210,80,90,0.5), rgba(100,20,40,0.7))' }
]

function selectBand(band) {
  router.push({ name: 'characters', params: { bandId: band.id } })
}
</script>

<template>
  <div class="flex flex-col h-full">
    <TopBar />

    <!-- 斜线分割区域：PC 横向 / 移动端纵向 -->
    <div class="band-container flex-1 flex flex-row max-sm:flex-col overflow-hidden">
      <div v-for="(band, i) in bands" :key="band.id"
           :class="['band-panel', 'band-panel-' + i]"
           :style="{
             background: band.gradient,
             transform: hovered === band.id ? 'scale(1.03)' : 'scale(1)',
             zIndex: hovered === band.id ? 2 : 1
           }"
           @mouseenter="hovered = band.id"
           @mouseleave="hovered = null"
           @click="selectBand(band)">
        <div class="band-name-bg"
             :style="{ transform: hovered === band.id ? 'translateY(-8px)' : 'translateY(0)' }">
          {{ band.name }}
        </div>
        <div class="band-label"
             :style="{ opacity: hovered === band.id ? 1 : 0, transform: hovered === band.id ? 'translateY(0)' : 'translateY(20px)' }">
          {{ band.name }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ====== PC 端：横向排列，垂直斜线分割 ====== */
.band-container {
  flex-direction: row;
}

.band-panel {
  flex: 1;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.5s;
  overflow: hidden;
}

/* PC clip-path: 左→右的垂直斜线 */
.band-panel-0 { clip-path: polygon(0 0, 100% 0, 85% 100%, 0 100%); }
.band-panel-1 { clip-path: polygon(15% 0, 100% 0, 85% 100%, 0 100%); }
.band-panel-2 { clip-path: polygon(15% 0, 100% 0, 100% 100%, 0 100%); }

.band-name-bg {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
  letter-spacing: 0.1em;
  font-weight: 700;
  user-select: none;
  transition: transform 0.3s;
  font-family: var(--font-display);
  color: rgba(255,255,255,0.25);
}

.band-label {
  position: absolute;
  bottom: 2rem;
  text-align: center;
  transition: all 0.3s;
  font-size: 1.5rem;
  letter-spacing: 0.1em;
  font-family: var(--font-display);
  color: var(--gold);
}

/* ====== 移动端 (< 640px)：纵向排列，水平斜线分割 ====== */
@media (max-width: 639px) {
  .band-container {
    flex-direction: column;
  }

  .band-panel {
    min-height: 30vh;
  }

  /* 移动端 clip-path: 上→下的水平斜线 */
  .band-panel-0 { clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%); }
  .band-panel-1 { clip-path: polygon(0 15%, 100% 0, 100% 85%, 0 100%); }
  .band-panel-2 { clip-path: polygon(0 15%, 100% 0, 100% 100%, 0 100%); }

  .band-name-bg {
    font-size: 2rem;
  }
}
</style>
