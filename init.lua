-- init.lua: Neovim config

-- Editor behaviour
local opt = vim.opt
vim.g.mapleader = " "
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.laststatus = 2
opt.ruler = true
opt.showmode = true
opt.cursorline = true
opt.hlsearch = true
opt.incsearch = true
opt.clipboard = "unnamed"
opt.background = "dark"
opt.termguicolors = true
opt.guicursor ="n-v-c:hor20,i-ci-ve:ver25,r-cr-o:hor20"
-- Keys
vim.keymap.set("i", "jk", "<Esc>")
-- Move selected lines up and down, re-indenting as they go
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
-- Syntax and filetype detection
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- Theme: try sorbet, fallback to habamax
local ok = pcall(vim.cmd.colorscheme, "sorbet")
if not ok then
  vim.cmd.colorscheme("habamax")
end

-- Custom highlights
vim.api.nvim_set_hl(0, "LineNr",       { fg = "#2e2e2e" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#a8e6a1" })
vim.api.nvim_set_hl(0, "AbsNr", {fg = "#3a3f4b"})
vim.api.nvim_set_hl(0, "AbsNrCur", {fg="#ffffff"})
vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#2b2b2b"})
vim.api.nvim_set_hl(0, "QfText", {fg = "#9ca1ac"})
vim.api.nvim_set_hl(0, "qfLineNr", {fg = "#8a90a0"})
opt.statuscolumn = "%s%=%{%v:relnum==0?'%#AbsNrCur#':'%#AbsNr#'%}%{v:lnum}%* %-3{v:relnum}"
-- Plain quickfix panes
vim.api.nvim_create_autocmd("FileType", {
 pattern = "qf",
 callback = function()
   vim.opt_local.statuscolumn = ""
   vim.opt_local.number = false
   vim.opt_local.relativenumber = false
   vim.opt_local.wrap = false
   vim.opt_local.winhighlight = "Normal:QfText"
 end,
})
-- Quickfix lines: just "line | text"
function _G.QfText(info)
 local list
 if info.quickfix == 1 then
   list = vim.fn.getqflist({ id = info.id, items = 1 })
 else
   list = vim.fn.getloclist(info.winid, { id = info.id, items = 1 })
 end
 local lines = {}
 for i = info.start_idx, info.end_idx do
   local e = list.items[i]
   table.insert(lines, string.format("%4d | %s", e.lnum, vim.trim(e.text)))
 end
 return lines
end
vim.o.quickfixtextfunc = "v:lua.QfText"  
-- Highlight the enclosing def in the quickfix pane as the cursor moves
vim.api.nvim_create_autocmd("CursorMoved", {
 pattern = "*.py",
 callback = function()
   local def_line = vim.fn.search([[^\s*def ]], "bnW")
   if def_line == 0 then return end
   local buf = vim.api.nvim_get_current_buf()
   for i, e in ipairs(vim.fn.getqflist()) do
     if e.bufnr == buf and e.lnum == def_line then
       vim.fn.setqflist({}, "a", { idx = i })
       return
     end
   end
 end,
})

-- Read a symbol's declaration straight from the header text, so parameter names show.
-- clangd's `detail` is the symbol's TYPE, and a function's type has no parameter names.
local function decl_text(buf, s)
    local first, last = s.range.start.line, s.range["end"].line   -- "end" is a Lua keyword, so use brackets
    local src = vim.api.nvim_buf_get_lines(buf, first, last + 1, false)
    for i, l in ipairs(src) do
        src[i] = l:gsub("//.*$", "")                    -- drop line comments
    end
    local text = table.concat(src, " ")                 -- multi-line declarations become one line
    text = text:gsub("/%*.-%*/", "")                    -- drop block comments
    text = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")   -- squash whitespace
    text = text:gsub("%( ", "("):gsub(" %)", ")"):gsub(" ,", ",") -- tidy spaces inside brackets
    return text
end
-- Outline: toggle a right-hand pane listing every def
local function outline_toggle()
 for _, win in ipairs(vim.fn.getwininfo()) do
   if win.quickfix == 1 then
     vim.cmd("cclose")
     return
   end
 end
 vim.cmd([[silent! vimgrep /^\s*def / %]])
 if vim.g.outline_pos == "bottom" then
  vim.cmd("botright copen 8")
 elseif vim.g.outline_pos == "top" then
  vim.cmd("topleft copen 8")
 else
  vim.cmd("botright vert copen 45")
 end
 vim.cmd("wincmd p")
end
vim.keymap.set("n", "<leader>o", outline_toggle, { desc = "Toggle outline" })
vim.keymap.set("n", "<leader>O", function()
local order = { right = "bottom", bottom = "top", top = "right" }
vim.g.outline_pos = order[vim.g.outline_pos or "right"]    
print("Outline: " .. vim.g.outline_pos)
end, { desc = "Switch outline side" })
-- Swap two words: asks for A and B, then A becomes B and B becomes A
function _G.SwapWords(range)
 local a = vim.fn.input("Swap: ")
 if a == "" then return end
 local b = vim.fn.input("With: ")
 if b == "" then return end
 local ea = vim.fn.escape(a, [[\/.*$^~[]])
 local eb = vim.fn.escape(b, [[\/.*$^~[]])
 vim.cmd(string.format(
[[%ss/\%%(\<\|_\)\zs\(%s\|%s\)\ze\(_\|\>\)/\=submatch(1)==#'%s'?'%s':'%s'/g]],
   range, ea, eb, a, b, a))
end
vim.keymap.set("n", "<leader>s", function() SwapWords("") end,
 { desc = "Swap two words on this line" })
vim.keymap.set("x", "<leader>s", [[:<C-u>lua SwapWords("'<,'>")<CR>]],
 { desc = "Swap two words in selection" })

-- Save and run LÖVE; collect its output and show it after the game closes
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")
  local output = {}
  local function collect(_, data)
    for _, line in ipairs(data) do
      if line ~= "" then table.insert(output, line) end
    end
  end
  vim.fn.jobstart({ "love", "." }, {
    on_stdout = collect,   -- print() output
    on_stderr = collect,   -- errors and tracebacks
    on_exit = function()
      if #output > 0 then vim.notify(table.concat(output, "\n")) end
    end,
  })
end, {desc = "Save and run LÖVE" })

-- C++ language server
vim.lsp.config("clangd", {
   cmd = { "clangd", "--background-index" },
   filetypes = { "c", "cpp" },
   root_markers = { "compile_flags.txt", "compile_commands.json", ".git" },
})

-- Clang Helpers
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert", "popup" }
vim.lsp.enable("clangd")

vim.diagnostic.config({ virtual_text = true })   -- show errors inline at the end of the line

vim.api.nvim_create_autocmd("LspAttach", {
   callback = function(args)
       local client = vim.lsp.get_client_by_id(args.data.client_id)
       vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
       vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
   end,
})

-- ===== Floating window helper: centred, rounded, dark; q or Esc closes =====
local function open_float(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = #title + 6
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l) + 2) end
  width = math.min(width, vim.o.columns - 4)
  local height = math.max(1, math.min(#lines, vim.o.lines - 4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. title .. " ", title_pos = "center",
  })
  vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:Normal"   -- same dark background as the code
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local function close() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })
  return buf, win, close
end
-- Workspace_Symbol Shortcut
-- ===== <leader>m: compact, sorted, coloured outline of the matching header =====
-- Blue = methods (what the class DOES), green = fields (what it HAS / KNOWS),
-- gold = the class itself, white = constructors (how it's born)
vim.api.nvim_set_hl(0, "OutlineMethod", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "OutlineField",  { fg = "#98c379" })
vim.api.nvim_set_hl(0, "OutlineClass",  { fg = "#e5c07b", bold = true })
local outline_ns = vim.api.nvim_create_namespace("outline")

vim.keymap.set("n", "<leader>m", function()
    -- 1. Load the matching header invisibly (Game.cpp -> Game.h), without a swap file
    local header = vim.fn.expand("%:p:r") .. ".h"
    local buf = vim.fn.bufadd(header)
    vim.bo[buf].swapfile = false
    vim.fn.bufload(buf)
    vim.api.nvim_buf_call(buf, function() vim.cmd("checktime") end)   -- reload the header if it changed on disk

    -- 2. Ask clangd for the header's symbols
    local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
    local results = vim.lsp.buf_request_sync(buf, "textDocument/documentSymbol", params, 2000)
    if not results then
        print("clangd isn't ready for " .. header .. " yet; try again in a moment")
        return
    end

    -- 3. Sort: constructors, then methods, then fields; A to Z within each group
    local kinds = vim.lsp.protocol.SymbolKind
    local order = { Constructor = 1, Method = 2, Field = 3 }
    local function sorted(symbols)
        local copy = vim.list_extend({}, symbols)
        table.sort(copy, function(a, b)
            local ka, kb = order[kinds[a.kind]] or 4, order[kinds[b.kind]] or 4
            if ka ~= kb then return ka < kb end
            return a.name:lower() < b.name:lower()
        end)
        return copy
    end

    -- 4. One line per symbol; remember each line's kind and where its text starts
    local lines, marks = {}, {}
    local function walk(symbols, indent)
        for _, s in ipairs(sorted(symbols)) do
            local kind = kinds[s.kind] or ""
            local line
            if kind == "Method" or kind == "Constructor" then
                line = string.format("%s%-12s %s", indent, kind, decl_text(buf, s)) -- real declaration, names included
            else
                line = string.format("%s%-12s %-20s %s", indent, kind, s.name, s.detail or "") -- fields and the class
            end
            table.insert(lines, line)
            table.insert(marks, { kind = kind, col = #indent, len = #line - #indent })
            if s.children then walk(s.children, indent .. "  ") end
        end
    end
    for _, res in pairs(results) do
        if res.result then walk(res.result, "") end
    end
    -- 5. Show it in the standard floating window, titled with the header's name
    local out = open_float(lines, vim.fn.fnamemodify(header, ":t"))

    -- 6. Colour each whole row by kind (constructors have no group, so they stay white)
   local groups = { Method = "CheatKey", Field = "CheatFn", Class = "CheatHead" }
    for row, m in ipairs(marks) do
        local group = groups[m.kind]
        if group then
            vim.api.nvim_buf_set_extmark(out, outline_ns, row - 1, m.col,
                { end_col = m.col + m.len, hl_group = group })
        end
    end
end, { desc = "Outline of the matching header" })
-- Grid Dividers

local ten_ns = vim.api.nvim_create_namespace("ten_lines")
vim.api.nvim_set_hl(0, "TenLine", { bg = "#1c1f26" })
vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
    callback = function(a)
        if vim.bo[a.buf].buftype ~= "" then return end --only "real" files will get the stripe.. so command will not
        vim.api.nvim_buf_clear_namespace(a.buf, ten_ns, 0, -1)
        for l = 9, vim.api.nvim_buf_line_count(a.buf) - 1, 10 do     -- lines 10, 20, 30... (0-based 9, 19, 29)
            vim.api.nvim_buf_set_extmark(a.buf, ten_ns, l, 0, { line_hl_group = "TenLine" })
        end
    end,
})

vim.opt.list = true
vim.opt.listchars = { leadmultispace = "│   ", tab = "│ " }   -- one guide every 4 leading spaces

vim.opt.cursorline = true        -- highlight the cursor's row (you already have this)
vim.opt.cursorcolumn = true      -- and its column

-- ===== C++ build and run (MSBuild, from a terminal where `padel` loaded vsdev) =====
vim.opt.makeprg = "msbuild Padel.sln -p:Configuration=Debug -p:Platform=x64 -v:minimal -nologo"
vim.opt.errorformat = "%\\s%#%f(%l\\,%c): %trror %m,%\\s%#%f(%l\\,%c): %tarning %m"

vim.keymap.set("n", "<leader>b", "<cmd>wall<CR><cmd>make<CR><cmd>cwindow<CR>",
    { desc = "Save all, build, show errors" })

vim.keymap.set("n", "<leader>e", function()
  local exe = vim.fn.getcwd() .. "\\x64\\Debug\\Padel.exe"
  if vim.fn.filereadable(exe) == 0 then
    vim.notify("Not found: " .. exe .. "  (check :pwd)", vim.log.levels.ERROR)
    return
  end
  local output = {}
  vim.fn.jobstart({ exe }, {
    cwd = vim.fn.getcwd(),
    stderr_buffered = true,
    on_stderr = function(_, data) vim.list_extend(output, data) end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("Padel exited with code " .. code .. "\n" .. table.concat(output, "\n"), vim.log.levels.WARN)
      end
    end,
  })
end, { desc = "Run Padel" })

-- Install l   -- Install lazy.nvim, the plugin manager, if it's missing
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
 vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
   "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- The leader key must be set before plugins load
vim.g.mapleader = " "

-- Load every plugin file in lua/plugins/
require("lazy").setup("plugins")
-- Quit debugging: stop the game, close panels and leftover debug terminals
vim.keymap.set("n", "<leader>dq", function()
    require("dap").terminate()
    require("dapui").close()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("Padel") then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
end, { desc = "Quit debugging" })

-- Cheat sheet colours: copy the theme's colours, then add bold
local function bold_copy(name, from)
 local hl = vim.api.nvim_get_hl(0, { name = from, link = false })
 vim.api.nvim_set_hl(0, name, { fg = hl.fg, bold = true })
end
bold_copy("CheatKey",  "Statement")    -- blue: $ keys
bold_copy("CheatFn",   "Identifier")   -- green: @ functions
bold_copy("CheatHead", "String")       -- yellow: headings
-- ===== <leader>h: cheat sheet of my leader keys ($) and PowerShell functions (@) =====
local function cheatsheet()
  local lines = { "Leader = Space, shown as $", "" }

  -- 1. Leader mappings, read live from Neovim
  local rows, seen = {}, {}
  for _, mode in ipairs({ "n", "x" }) do
    for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
      local rest = km.lhs:match("^<Space>(.+)") or km.lhs:match("^ (.+)")
      if rest and not seen[rest] then
        seen[rest] = true
        local desc = km.desc or "(no description)"
        if mode == "x" then desc = desc .. " (visual)" end
        table.insert(rows, { "$" .. rest, desc })
      end
    end
  end
  table.sort(rows, function(a, b) return a[1]:lower() < b[1]:lower() end)
  for _, r in ipairs(rows) do
    table.insert(lines, string.format("%-8s %s", r[1], r[2]))
  end

  -- 2. PowerShell functions, read from the shared profile
  table.insert(lines, "")
  table.insert(lines, "PowerShell functions, shown as @")
  table.insert(lines, "")
  local profile = vim.fn.stdpath("config") .. "/powershell/Microsoft.PowerShell_profile.ps1"
  if vim.fn.filereadable(profile) == 0 then
    table.insert(lines, "(profile not found: " .. profile .. ")")
  else
    local file = vim.fn.readfile(profile)
    for i, line in ipairs(file) do
      local name = line:match("^%s*[Ff]unction%s+([%w_%-]+)")
      if name then
        local desc = (i > 1 and file[i - 1]:match("^%s*#%s*(.+)$")) or "(no description)"
        table.insert(lines, string.format("%-14s %s", "@" .. name, desc))
      end
    end
  end

  -- 3. Show it in a centred floating window
  local buf = open_float(lines, "Commands")
  -- 4. Colour: $ keys blue, @ functions green, headings gold
  for row, l in ipairs(lines) do
    local word = l:match("^(%S+)")
    local group = (l:sub(1, 1) == "$" and "CheatKey")
      or (l:sub(1, 1) == "@" and "CheatFn")
      or (l ~= "" and "CheatHead")
    if group then
      local len = (group == "CheatHead") and #l or #word
      vim.api.nvim_buf_set_extmark(buf, outline_ns, row - 1, 0, { end_col = len, hl_group = group })
    end
  end
end
vim.keymap.set("n", "<leader>h", cheatsheet, { desc = "Show my commands" })
-- Menu: pick one of my commands from a pop-up (number or Enter runs it)
vim.keymap.set("n", "<leader>M", function()
  local actions = {
    { "Toggle outline", outline_toggle },
    { "Edit config",    function() vim.cmd("e $MYVIMRC") end },
    { "Show commands",  cheatsheet },
  }
  local lines = {}
  for i, a in ipairs(actions) do lines[i] = string.format("%d  %s", i, a[1]) end
  local buf, win, close = open_float(lines, "Menu")
  for row = 1, #lines do
    vim.api.nvim_buf_set_extmark(buf, outline_ns, row - 1, 0, { end_col = 1, hl_group = "CheatKey" })
  end

  local function run(i)
    if not actions[i] then return end
    close()
    vim.schedule(actions[i][2])   -- run after the menu has closed, in the window you came from
  end
  vim.keymap.set("n", "<CR>", function() run(vim.api.nvim_win_get_cursor(win)[1]) end, { buffer = buf, nowait = true })
  for i = 1, #actions do
    vim.keymap.set("n", tostring(i), function() run(i) end, { buffer = buf, nowait = true })
  end
end, { desc = "My command menu" })
vim.keymap.set("n", "<leader>ws", function()
    vim.lsp.buf.workspace_symbol(vim.fn.input("Symbol: "))
end, { desc = "Search symbols, including library headers" })

-- Third-party code under External/ is read-only: view it, never edit it.
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*/External/*",
    callback = function()
        vim.bo.readonly = true      -- warns on :w
        vim.bo.modifiable = false   -- blocks typing at all
    end,
})
