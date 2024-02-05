import { defineConfig } from "vitepress";

export default defineConfig({
  title: "util.luau",
  description: "A collection of useful utilities for Luau.",
  cleanUrls: true,
  lastUpdated: true,
  base: "/util.luau/",

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

    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright © 2024-present LukaDev",
    },

    search: {
      provider: "local",
    },

    editLink: {
      pattern: "https://github.com/lukadev-0/util.luau/edit/main/docs/:path",
    },
  },
});
