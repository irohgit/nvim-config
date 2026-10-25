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
-- Menu: pick one of my commands from a list
vim.keymap.set("n", "<leader>m", function()
 local actions = {
   { "Toggle outline", outline_toggle },
   { "Edit config",    function() vim.cmd("e $MYVIMRC") end },
   { "Reload config",  function() vim.cmd("source $MYVIMRC") end },
 }
 vim.ui.select(actions, {
   prompt = "Run:",
   format_item = function(a) return a[1] end,
 }, function(choice)
   if choice then choice[2]() end
 end)
end, { desc = "My command menu" })
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
            local line = string.format("%s%-12s %-20s %s", indent, kind, s.name, s.detail or "")
            table.insert(lines, line)
            table.insert(marks, { kind = kind, col = #indent, len = #line - #indent })
            if s.children then walk(s.children, indent .. "  ") end
        end
    end
    for _, res in pairs(results) do
        if res.result then walk(res.result, "") end
    end

    -- 5. Show it in a small window on top
    vim.cmd("topleft new")
    local out = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(out, 0, -1, false, lines)

    -- 6. Colour each whole row by kind (constructors have no group, so they stay white)
    local groups = { Method = "OutlineMethod", Field = "OutlineField", Class = "OutlineClass" }
    for row, m in ipairs(marks) do
        local group = groups[m.kind]
        if group then
            vim.api.nvim_buf_set_extmark(out, outline_ns, row - 1, m.col,
                { end_col = m.col + m.len, hl_group = group })
        end
    end

    -- 7. Throwaway, read-only window; q closes it; jump back to the code
    vim.bo[out].buftype, vim.bo[out].bufhidden, vim.bo[out].modifiable = "nofile", "wipe", false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = out, desc = "Close outline" })
    vim.cmd("resize " .. #lines)
    vim.cmd("wincmd p")
end, { desc = "Outline of the matching header" })
-- Grid Dividers

local ten_ns = vim.api.nvim_create_namespace("ten_lines")
vim.api.nvim_set_hl(0, "TenLine", { bg = "#1c1f26" })
vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
    callback = function(a)
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

