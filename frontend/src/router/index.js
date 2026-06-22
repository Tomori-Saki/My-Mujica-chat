import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { guest: true }
  },
  {
    path: '/bands',
    name: 'bands',
    component: () => import('../views/BandSelectionView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/bands/:bandId/characters',
    name: 'characters',
    component: () => import('../views/CharacterSelectionView.vue'),
    meta: { requiresAuth: true },
    props: true
  },
  {
    path: '/chat/:bandId/:characterId',
    name: 'chat',
    component: () => import('../views/ChatView.vue'),
    meta: { requiresAuth: true },
    props: true
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  if (to.meta.requiresAuth && !authStore.isLoggedIn) {
    next({ name: 'login' })
  } else if (to.meta.guest && authStore.isLoggedIn) {
    next({ name: 'bands' })
  } else {
    next()
  }
})

export default router
