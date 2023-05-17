/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./**/*.{html,js,erb}"],
  theme: {
    extend: {
      fontFamily: {
        heading: ["var(--heading-font), ui-serif, serif"],
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
