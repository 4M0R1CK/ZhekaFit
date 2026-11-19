import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, expect, test, vi } from 'vitest'
import App from '../App'

const api = vi.hoisted(() => ({
  getPrograms: vi.fn().mockResolvedValue([]),
  getTrainers: vi.fn().mockResolvedValue([]),
  getPlans: vi.fn().mockResolvedValue([]),
  getSessions: vi.fn().mockResolvedValue([]),
  getProfile: vi.fn().mockResolvedValue(null),
  getClubImage: vi.fn((path: string) => `https://example.supabase.co/storage/v1/object/public/club-media/${path}`),
}))

vi.mock('../services/fitnessApi', () => api)
vi.mock('../lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
    },
  },
}))

afterEach(() => {
  cleanup()
  window.history.replaceState({}, '', '/')
})

function renderAt(path: string) {
  window.history.replaceState({}, '', path)
  return render(<App />)
}

test('home and public navigation render without fixture content', async () => {
  renderAt('/')
  expect(await screen.findByRole('heading', { name: /Сильнее/ })).toBeTruthy()
  await userEvent.click(screen.getAllByRole('link', { name: 'Программы' })[0])
  expect(await screen.findByRole('heading', { name: 'Программы' })).toBeTruthy()
  expect(screen.getByText('Нет опубликованных программ, подходящих под фильтр.')).toBeTruthy()
})

test('catalog and pricing show database empty states instead of demo records', async () => {
  renderAt('/pricing')
  expect(await screen.findByRole('heading', { name: 'Тарифы клуба' })).toBeTruthy()
  expect(screen.getByText(/Опубликованных тарифов пока нет/)).toBeTruthy()
  expect(screen.queryByText(/2 900/)).toBeNull()
})

test('guest account routes redirect to Supabase sign-in', async () => {
  renderAt('/account')
  expect(await screen.findByRole('heading', { name: 'Вход' })).toBeTruthy()
  expect(screen.getByLabelText('Email')).toBeTruthy()
  expect(screen.getByLabelText('Пароль')).toBeTruthy()
})

test('registration form is available without a demo account', async () => {
  renderAt('/register')
  expect(await screen.findByRole('heading', { name: 'Регистрация' })).toBeTruthy()
  expect(screen.getByLabelText('Имя')).toBeTruthy()
  expect(screen.getByLabelText('Email')).toBeTruthy()
  expect(screen.getByLabelText('Пароль')).toBeTruthy()
  expect(screen.queryByText(/demo@|fit2026/i)).toBeNull()
  fireEvent.change(screen.getByLabelText('Телефон'), { target: { value: '+7 900 000-00-00' } })
  expect((screen.getByLabelText('Телефон') as HTMLInputElement).value).toBe('+7 900 000-00-00')
})
