-- Debug Adapter Protocol configuration
-- Extends LazyVim's dap setup

return {
  -- Configure nvim-dap and extensions
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
    },
    config = function()
      local dap = require("dap")
      
      -- Setup Go debugging
      require("dap-go").setup()
      
      -- Add Java debugging configuration if needed
      -- LazyVim's Java extra should handle this
    end,
  },
}
