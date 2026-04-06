-- Go utviklingsoppsett
-- Konfigurasjon for Go programmering i Neovim

return {
  -- LazyVim sin Go-støtte gir grunnleggende LSP
  { import = "lazyvim.plugins.extras.lang.go" },

  -- Gopls (Go språkserver) med gode instillinger
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              -- Bruk gofumpt som er strengere enn gofmt
              gofumpt = true,
              -- Kodelinser (små knapper i koden)
              codelenses = {
                gc_details = false,
                generate = true,           -- For generate directives
                regenerate_cgo = true,
                run_govulncheck = true,    -- Sikkerhetssjekk
                test = true,               -- Kjør test fra koden
                tidy = true,               -- go mod tidy
                upgrade_dependency = true, -- Oppgrader pakker
                vendor = true,             -- go mod vendor
              },
              -- Inlay hints - vis typer inline
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              -- Statisk analyse
              analyses = {
                fieldalignment = true,  -- Sjekk struct størrelse
                nilness = true,         -- Sjekk nil feil
                unusedparams = true,    -- Ubrukte parametere
                unusedwrite = true,     -- Ubrukte skrivinger
                useany = true,          -- Foreslå any istedenfor interface{}
              },
              -- Sett inn plassholdere for parametere
              usePlaceholders = true,
              -- Fullfør imports automatisk
              completeUnimported = true,
              -- Kjør staticcheck for bedre analyser
              staticcheck = true,
              -- Ignorer disse mappene
              directoryFilters = { "-node_modules", "-vendor", "-.git" },
              ui = {
                semanticTokens = true,
              },
            },
          },
        },
      },
    },
  },

  -- Installer Go-verktøy automatisk
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "gopls",           -- Go språkserver
        "delve",           -- Debugger
        "gofumpt",         -- Bedre formattering
        "goimports",       -- Auto-import
        "gomodifytags",    -- Redigere struct tags
        "impl",            -- Generere interface implementations
        "gotests",         -- Generere tester
        "golangci-lint",   -- Linting
        "buf",             -- Protocol Buffers
        "protolint",       -- Protobuf linting
      })
    end,
  },

  -- Go filer i treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "go",
        "gomod",
        "gosum",
        "gowork",
        "templ",  -- Templating for Go
      })
    end,
  },

  -- Auto-format med gofumpt og organiser imports
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
      },
    },
  },

  -- Debugging for Go
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      { "<leader>td", function() require("dap-go").debug_test() end, desc = "Debug Go test", ft = "go" },
      { "<leader>tD", function() require("dap-go").debug_last_test() end, desc = "Debug forrige test", ft = "go" },
    },
  },

  -- Verktøy for struct tags (json, db, osv)
  {
    "crispgm/nvim-go",
    ft = "go",
    config = function()
      require("go").setup({
        notify = false,
        auto_format = false,  -- Vi bruker conform istedenfor
        auto_lint = false,
      })
    end,
    keys = {
      { "<leader>ctg", "<cmd>GoAddTags<cr>", desc = "Legg til struct tags" },
      { "<leader>ctG", "<cmd>GoRemoveTags<cr>", desc = "Fjern struct tags" },
      { "<leader>ctf", "<cmd>GoFillStruct<cr>", desc = "Fyll struct" },
      { "<leader>cti", "<cmd>GoImpl<cr>", desc = "Generer interface" },
    },
  },

  -- Test runner med UI
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          experimental = {
            test_table = true,  -- Støtte for table-driven tests
          },
          args = { "-count=1", "-timeout=60s" },
        },
      },
    },
  },

  -- Kjør Go kode snippets
  {
    "michaelb/sniprun",
    build = "bash ./install.sh",
    keys = {
      { "<leader>rg", "<cmd>SnipRun<cr>", desc = "Kjør Go kodesnipp" },
    },
    opts = {
      selected_interpreters = { "Go_original" },
    },
  },
}
