# Neovim Plugins

Dette er mine personlige plugin-konfigurasjoner for Neovim med LazyVim.

## Struktur

```
lua/plugins/
├── README.md              # Denne fila
├── lang/                  # Språk-spesifikt
│   ├── java.lua          # Java og Spring Boot
│   ├── go.lua            # Go
│   └── frontend.lua      # Vue, Next.js, React
└── tools/                 # Verktøy
    ├── dap.lua           # Debugging
    ├── hidden-files.lua  # Vise .env og sånt
    ├── markdown-preview.lua
    ├── peek.lua
    ├── glow.lua
    └── wakatime.lua      # Tidtaking

lua/
└── utils.lua             # Hjelpefunksjoner (ikke i plugins/)
```

## Hva jeg har satt opp

### Java (java.lua)

Brukes til Spring Boot-prosjekter. Har:
- Java LSP med kodefullføring
- Debugging for å finne bugs
- JPA snippets (skriv `findBy` + Tab så får du metode-maler)
- Test-kjøring
- HTTP client for å teste API-er

**Snarveier:**
- `<leader>th` - Kjør HTTP request (bra for Controllers)
- `<leader>tt` - Kjør tester
- `findBy` + Tab - Lager repository-metoder automatisk

### Go (go.lua)

For Go-utvikling:
- Go LSP (gopls)
- Delve debugger
- Auto-format når jeg lagrer
- Test-runner
- Struct tags (f.eks. JSON tags)

**Snarveier:**
- `<leader>td` - Debug test
- `<leader>ctg` - Legg til struct tags

### Frontend (frontend.lua)

Vue, Next.js, React, TypeScript:
- TypeScript og Vue språkservere
- ESLint for feilsjekking
- Prettier for formattering
- Tailwind CSS støtte
- Se npm-pakkeversjoner i package.json

**Snarveier:**
- `<leader>ns` - Se npm pakkeversjon

### Verktøy

**dap.lua** - Debugging for Java og Go

**hidden-files.lua** - Viser skjulte filer som `.env`. Før så jeg dem ikke, nå gjør jeg det. Trykk `H` i filutforskeren for å toggle.

**markdown-*.lua** - Tre forskjellige måter å preview Markdown:
- Browser
- Floating vindu  
- Terminal

**wakatime.lua** - Tracker tid jeg bruker på koding (bare for moro)

## Hvordan legge til nye plugins

1. Lag ny `.lua` fil i riktig mappe
2. Returner en tabell med plugin-spesifikasjon
3. Restart Neovim - Lazy ordner resten

Eksempel:
```lua
-- lua/plugins/tools/min-plugin.lua
return {
  {
    "forfatter/navn",
    config = function()
      require("navn").setup()
    end,
  },
}
```

## Utils

lua/utils.lua inneholder hjelpefunksjoner. Den ligger i `lua/` ikke `lua/plugins/` fordi LazyVim prøver å laste alt i plugins/ som plugins.

- `has(plugin)` - Sjekk om plugin er installert
- `git_root()` - Finn git rot-mappe
- `safe_require()` - Trygg require som ikke kræsjer

Bruk dem sånn:
```lua
local utils = require("utils")  -- ikke "plugins.utils"
if utils.has("neo-tree.nvim") then
  -- gjør noe
end
```

## Språk-extras

Disse lastes automatisk fra LazyVim i `lua/config/lazy.lua`:
- Java
- TypeScript  
- Vue
- Tailwind
- Go

De gir grunnleggende LSP, og mine konfigurasjoner utvider dem.
