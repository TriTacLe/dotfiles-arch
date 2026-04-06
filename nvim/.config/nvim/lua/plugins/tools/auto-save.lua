-- Auto-lagring - lagrer filer automatisk
-- Slipper å tenke på :w hele tiden

return {
  -- Auto-save plugin
  {
    "pocco81/auto-save.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      enabled = true, -- start auto-save når Neovim åpner
      execution_message = {
        message = function()
          return ("AutoSaved: " .. vim.fn.strftime("%H:%M:%S"))
        end,
        dim = 0.18,
        cleaning_interval = 1250,
      },
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost" }, -- Lagre når jeg forlater buffer eller vindu
        defer_save = { "InsertLeave", "TextChanged" }, -- Lagre etter jeg slutter å skrive
        cancel_deferred_save = { "InsertEnter" }, -- Avbryt hvis jeg begynner å skrive igjen
      },
      condition = function(buf)
        -- Ikke auto-lagre disse filtypene
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        local fn = vim.fn.expand("%:t")
        
        -- Ikke lagre i disse tilfellene:
        if 
          fn:match("^%d+:%d+:.+") or  -- git diff filer
          ft:match("^git") or          -- git relaterte buffere
          ft == "neo-tree" or
          ft == "Trouble" or
          ft == "qf" or               -- quickfix
          ft == "lazy" or
          ft == "mason" or
          fn:match("^__")             -- spesielle buffere
        then
          return false
        end
        
        return true
      end,
      write_all_buffers = false, -- bare lagre aktiv buffer
      on_off_commands = true,    -- mulighet til å skru av/på med :ASToggle
    },
    keys = {
      { "<leader>ua", "<cmd>ASToggle<cr>", desc = "Toggle auto-save" },
    },
  },
}
