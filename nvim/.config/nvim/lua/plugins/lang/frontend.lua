-- Frontend utvikling for Vue, Next.js, React, TypeScript

return {
  -- TypeScript støtte (tsserver, eslint, prettier)
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- Vue.js støtte
  { import = "lazyvim.plugins.extras.lang.vue" },

  -- Tailwind CSS støtte
  { import = "lazyvim.plugins.extras.lang.tailwind" },

  -- Språkserver konfigurasjon
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript (vtsls er raskere enn tsserver)
        vtsls = {
          settings = {
            typescript = {
              -- Inlay hints - vis typer inline
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
              -- Relativ import (ikke @/...)
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
          },
        },
        -- ESLint for feilsjekking
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
        -- Vue Language Server
        volar = {
          init_options = {
            vue = {
              hybridMode = true,  -- Bedre ytelse
            },
          },
        },
      },
    },
  },

  -- Installer frontend-verktøy
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vtsls",                      -- TypeScript språkserver
        "eslint-lsp",                 -- ESLint
        "prettier",                   -- Formattering
        "vue-language-server",        -- Vue
        "css-lsp",                    -- CSS
        "cssmodules-language-server", -- CSS Modules
        "html-lsp",                   -- HTML
        "json-lsp",                   -- JSON
        "tailwindcss-language-server", -- Tailwind
        "graphql-language-service-cli", -- GraphQL
      })
    end,
  },

  -- Frontend filer i treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vue",
        "svelte",
        "css",
        "scss",
        "html",
        "json",
        "jsonc",
        "graphql",
      })
    end,
  },

  -- Prettier for formattering av frontend-filer
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },
    },
  },

  -- Vis npm-pakkeversjoner i package.json
  -- Nyttig for å se om pakker er outdated
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
    ft = "json",
    keys = {
      { "<leader>ns", "<cmd>lua require('package-info').show()<cr>", desc = "Vis pakkeversjon" },
      { "<leader>nc", "<cmd>lua require('package-info').hide()<cr>", desc = "Skjul pakkeversjon" },
      { "<leader>nt", "<cmd>lua require('package-info').toggle()<cr>", desc = "Toggle pakkeinfo" },
      { "<leader>nu", "<cmd>lua require('package-info').update()<cr>", desc = "Oppdater pakke" },
      { "<leader>nd", "<cmd>lua require('package-info').delete()<cr>", desc = "Slett pakke" },
      { "<leader>ni", "<cmd>lua require('package-info').install()<cr>", desc = "Installer pakke" },
      { "<leader>np", "<cmd>lua require('package-info').change_version()<cr>", desc = "Endre pakkeversjon" },
    },
  },
}
