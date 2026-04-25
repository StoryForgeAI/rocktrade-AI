import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        ink: '#0b0b0c',
        ember: '#f97316',
        sand: '#f7efe6',
        panel: '#151515',
        line: 'rgba(255,255,255,0.08)',
      },
      boxShadow: {
        glow: '0 20px 80px rgba(249,115,22,0.22)',
      },
    },
  },
  plugins: [],
};

export default config;
