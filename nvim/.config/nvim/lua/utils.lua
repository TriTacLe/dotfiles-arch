-- Hjelpefunksjoner som brukes i flere plugins
-- Legg ting her som du trenger flere steder

local M = {}

-- Sjekk om en plugin er installert
-- Bruk: if utils.has("neo-tree.nvim") then ... end
function M.has(plugin)
  return require("lazy.core.config").plugins[plugin] ~= nil
end

-- Hent opsjoner for en plugin
function M.opts(plugin)
  return require("lazy.core.config").plugins[plugin] or {}
end

-- Trygg require som returnerer nil hvis modul ikke finnes
-- Bra for å unngå kræsj hvis en plugin mangler
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if ok then
    return result
  end
  return nil
end

-- Sjekk om vi er i et git repository
function M.is_git_repo()
  local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("true") ~= nil
  end
  return false
end

-- Få git rot-mappe
-- Returnerer nil hvis ikke i git repo
function M.git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    return result ~= "" and result or nil
  end
  return nil
end

return M
