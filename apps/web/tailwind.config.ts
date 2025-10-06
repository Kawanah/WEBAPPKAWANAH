import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        primary: "#1D4ED8",
        secondary: "#FF6638",
        success: "#10B981",
        warning: "#F59E0B",
        danger: "#EF4444",
        neutral: {
          900: "#111827",
          600: "#6B7280",
          200: "#F3F4F6",
          0: "#FFFFFF"
        }
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "system-ui", "sans-serif"],
        mono: ["Roboto Mono", "monospace"]
      },
      boxShadow: {
        sm: "0 1px 2px rgba(0,0,0,0.05)",
        md: "0 4px 6px rgba(0,0,0,0.1)",
        lg: "0 10px 15px rgba(0,0,0,0.15)"
      },
      borderRadius: {
        lg: "12px"
      }
    },
  },
  plugins: [require("@tailwindcss/forms")]
};

export default config;
