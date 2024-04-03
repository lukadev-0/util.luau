import { defineConfig } from "vitepress";

export default defineConfig({
  title: "util.luau",
  description: "A collection of useful utilities for Luau.",
  cleanUrls: true,
  lastUpdated: true,
  base: "/util.luau/",

  themeConfig: {
    nav: [
      { text: "Docs", link: "/docs/getting-started", activeMatch: "/docs/" },
      { text: "Reference", link: "/reference/", activeMatch: "/reference/" },
    ],

    sidebar: {
      "/docs/": [
        {
          text: "Introduction",
          items: [
            { text: "Getting Started", link: "/docs/getting-started" },
            { text: "Supported Runtimes", link: "/docs/supported-runtimes" },
          ],
        },
        {
          text: "Guide",
          items: [
            { text: "Optional Values", link: "/docs/optional-values" },
            { text: "Error Handling", link: "/docs/error-handling" },
            { text: "Async with Futures", link: "/docs/async-with-futures" },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            {
              text: "Overview",
              link: "/reference/",
            },
          ],
        },
        {
          text: "Packages",
          items: [
            { text: "future", link: "/reference/future" },
            { text: "option", link: "/reference/option" },
            { text: "result", link: "/reference/result" },
            { text: "std", link: "/reference/std" },
            { text: "threadpool", link: "/reference/threadpool" },
            { text: "timer", link: "/reference/timer" },
          ],
        },
      ],
    },

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
