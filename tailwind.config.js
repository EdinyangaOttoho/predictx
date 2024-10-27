/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        midnight: {
          50: '#f6f6f7',
          100: '#e1e3e7',
          200: '#c2c7cf',
          300: '#9ba3b0',
          400: '#787f8f',
          500: '#606575',
          600: '#4c505d',
          700: '#3d414b',
          800: '#2b2d35',
          900: '#1a1b21',
          950: '#121316',
        },
        neon: {
          400: '#ff47b5',
          500: '#ff1a9d',
          600: '#ff008c',
        },
      },
    },
  },
  plugins: [],
};