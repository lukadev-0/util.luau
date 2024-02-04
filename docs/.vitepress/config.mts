import { defineConfig } from "vitepress";

export default defineConfig({
  title: "util.luau",
  description: "A collection of useful utilities for Luau.",
  cleanUrls: true,
  themeConfig: {
    nav: [{ text: "Docs", link: "/introduction" }],

    sidebar: [
      {
        text: "Guide",
        items: [{ text: "Introduction", link: "/introduction" }],
      },
      {
        text: "Reference",
        items: [{ text: "option", link: "/reference/option" }],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/lukadev-0/util.luau" },
    ],
  },
});
