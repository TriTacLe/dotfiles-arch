return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function(plugin)
    vim.fn.system({ "npm", "install", "--prefix", plugin.dir .. "/app" })
  end,
  keys = {
    { "<leader>mb", "<cmd>MarkdownPreview<CR>", desc = "Markdown Preview (Browser)" },
    { "<leader>mt", "<cmd>MarkdownPreviewToggle<CR>", desc = "Toggle Markdown Preview" },
  },
  config = function()
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_command_for_global = 0
    vim.g.mkdp_open_to_the_world = 0
    vim.g.mkdp_open_ip = ""
    vim.g.mkdp_browser = ""
    vim.g.mkdp_echo_preview_url = 0
    vim.g.mkdp_page_title = "「${name}」"
  end,
}
