# Neovim config

My Neovim and PowerShell setup, shared across every Windows machine I use.

| File | What it does |
|---|---|
| `init.lua` | Neovim config |
| `lua/plugins/dap.lua` | nvim-dap debugger setup for C++ (Padel) |
| `lua/plugins/markdown.lua` | Renders Markdown inside Neovim |
| `powershell/Microsoft.PowerShell_profile.ps1` | Shared PowerShell profile: shortcuts, prompt, key bindings |
| `nvim-dap-setup.ps1` | One-run setup for a new machine |

This README has three parts:

1. **Part 1: Terminal setup.** Neovim, the shared PowerShell profile and its shortcuts.
2. **Part 2: Debugger setup.** nvim-dap, codelldb and cdb, for debugging Padel.
3. **Part 3: Keys.** Every leader key, and the built-in cheat sheet.

Do Part 1 first.

---

# Part 1: Terminal setup

## How it works

The real PowerShell profile lives in this repo, at `powershell/Microsoft.PowerShell_profile.ps1`.

Each machine's own `$PROFILE` is a two-line pointer to it.

So there is one file to edit, and every machine gets the change after a `git pull`.

## Requirements

| Software | Why | Installed by `nvim-dap-setup.ps1`? |
|---|---|---|
| Git | Clone this repo | Yes |
| Neovim | The editor | Yes |
| PowerShell 7 | Runs the shared profile | Yes |

## Step 1: Clone this repo

```powershell
git clone <this repo's URL> "$env:LOCALAPPDATA\nvim"
```

Skip this step on a machine that already has the repo.

## Step 2: Run the setup script

```powershell
& "$env:LOCALAPPDATA\nvim\nvim-dap-setup.ps1"
```

On a brand-new machine, if scripts are blocked, run this instead:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\nvim\nvim-dap-setup.ps1"
```

The script:

1. Lets your own scripts run.
2. Installs Git, Neovim and PowerShell 7 with winget, if they are missing.
3. Points both PowerShell profiles at the shared profile in this repo.
   1. Any old profile is backed up as `.bak` first.
4. Finds cdb and adds it to your PATH, if cdb is installed (see Part 2).
5. Installs the Neovim plugins.

It checks before every change, so it is safe to run more than once.

## Step 2, by hand (if you skip the script)

1. Allow your own scripts to run:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. Open your profile with `notepad $PROFILE`.
   1. If it says the file does not exist, run `New-Item -Force $PROFILE` first.
3. Replace everything in it with this pointer:

   ```powershell
   $Shared = "$env:LOCALAPPDATA\nvim\powershell\Microsoft.PowerShell_profile.ps1"
   if (Test-Path $Shared) { . $Shared }
   ```

4. Save, then run `. $PROFILE` to reload.
5. If you also use Windows PowerShell 5, repeat steps 2 to 4 there.
   1. PowerShell 5 and 7 each have their own `$PROFILE`.

The leading `. ` is dot-sourcing: it runs the shared file in your current session, so its functions stay loaded.

## Step 3: Check it worked

1. Open a new terminal.
2. Type `padel`.
3. Type `nvimdir`.

**Result:** your shortcuts, prompt and key bindings load on this machine.

## Shortcuts in the shared profile

| Command | What it does |
|---|---|
| `padel` | Go to the Padel project |
| `padelv` | Go to Padel and open it in Neovim |
| `padelrun` | Go to Padel and run the x64 Debug build |
| `padeltrace` | Run Padel under cdb and print the call stack each time a function runs |
| `pingpong` | Go to the old Lua ping-pong project |
| `portfolio` | Go to the portfolio site |
| `nvimdir` | Go to this Neovim config folder |
| `nvimrc` | Open `init.lua` in Neovim |
| `vsdev` | Load the Visual Studio developer shell (64-bit MSVC and MSBuild) |

Folders that differ between machines use a `Test-Path` list, so each machine picks the path that exists:

```powershell
$PadelRoot = @('E:\cplusplus\Padel', 'C:\Users\User\cplusplus\Padel') |
    Where-Object { Test-Path $_ } | Select-Object -First 1
function padel { Set-Location $PadelRoot }
```

To add a new machine's folder, add its path to the list.

## Editing the profile

1. Run `nvimdir`.
2. Open `powershell/Microsoft.PowerShell_profile.ps1`.
3. Put a one-line `#` comment directly above every new function. The cheat sheet (Part 3) shows it as the description.
4. Save, then run `. $PROFILE` to reload.
5. Commit and push, so other machines get it on their next `git pull`.

---

# Part 2: Debugger setup (nvim-dap)

## Requirements

| Software | Why | Installed automatically? |
|---|---|---|
| nvim-dap, nvim-dap-ui, nvim-nio, mason.nvim | Debugger plugins | Yes, by lazy.nvim |
| codelldb | Debug adapter for nvim-dap | Yes, the first time Neovim opens |
| cdb | Console debugger, used by `padeltrace` | **No, install it yourself (steps 1 and 2)** |
| An x64 Debug build of Padel | Gives the debugger `x64\Debug\Padel.exe` and its `.pdb` symbols | No, build it in Visual Studio |

Build Padel as **x64**. codelldb cannot walk the call stack of a 32-bit (x86) program on Windows, so an x86 build only shows one frame.

## Step 1: Check for cdb

```powershell
Test-Path "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64\cdb.exe"
```

1. **True:** cdb is installed. Go to step 3.
2. **False:** cdb is not installed. Go to step 2.

## Step 2: Install cdb

cdb ships inside the Windows SDK as an optional feature, "Debugging Tools for Windows".

1. **If the Windows SDK is already installed** (Visual Studio often installs it):
   1. Open Settings, then Apps, then Installed apps.
   2. Find Windows Software Development Kit.
   3. Choose Modify, then Change.
   4. Tick Debugging Tools for Windows, then finish.
2. **If the Windows SDK is not installed:**
   1. Search for "Windows SDK download" and open the official Microsoft developer page.
   2. Run the installer.
   3. On the features page, untick everything except Debugging Tools for Windows.
3. Run the step 1 check again.
   1. It should now say True.

## Step 3: Run the setup script

```powershell
& "$env:LOCALAPPDATA\nvim\nvim-dap-setup.ps1"
```

Step 4 of the script finds cdb and adds it to your PATH.

## Step 4: The plugin config

This lives at `lua/plugins/dap.lua`:

```lua
return {
  { "williamboman/mason.nvim", config = true },
  {
    "mfussenegger/nvim-dap",
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()

      -- Install codelldb automatically on any new machine
      local ok, registry = pcall(require, "mason-registry")
      if ok then
        registry.refresh(function()
          local pkg = registry.get_package("codelldb")
          if not pkg:is_installed() then pkg:install() end
        end)
      end

      -- The adapter: codelldb, installed by Mason
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb.cmd",
          args = { "--port", "${port}" },
          detached = false, -- needed on Windows
        },
      }

      -- What to launch: Padel's x64 Debug build, falling back to the old x86 path
      dap.configurations.cpp = {
        {
          name = "Padel (Debug)",
          type = "codelldb",
          request = "launch",
          program = function()
            local x64 = vim.fn.getcwd() .. "\\x64\\Debug\\Padel.exe"
            if vim.fn.filereadable(x64) == 1 then return x64 end
            return vim.fn.getcwd() .. "\\Debug\\Padel.exe"
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- Open and close the panels automatically
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

      -- Same keys as Visual Studio
      vim.keymap.set("n", "<F5>", dap.continue)
      vim.keymap.set("n", "<F9>", dap.toggle_breakpoint)
      vim.keymap.set("n", "<F10>", dap.step_over)
      vim.keymap.set("n", "<F11>", dap.step_into)
      vim.keymap.set("n", "<S-F11>", dap.step_out)

      -- Logpoint: prints a message and keeps running
      vim.keymap.set("n", "<leader>dl", function()
        dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
      end, { desc = "Logpoint: print a message and keep running" })

      -- Trace a Padel function with cdb, in a terminal split
      vim.keymap.set("n", "<leader>dt", function()
        local fn = vim.fn.input("Trace function: ", "AudioSystem::~AudioSystem")
        vim.cmd("botright 15split | terminal pwsh -NoLogo -Command padeltrace '" .. fn .. "'")
      end, { desc = "Trace a Padel function" })
    end,
  },
}
```

`<leader>dq` (quit debugging) lives in `init.lua`, because it runs outside the plugin's setup.

## Step 5: The trace function

This lives in the shared PowerShell profile, `powershell/Microsoft.PowerShell_profile.ps1`:

```powershell
# Run Padel under cdb and print the call stack each time a function runs
function padeltrace {
    param([string]$Fn = 'AudioSystem::~AudioSystem')
    Set-Location $PadelRoot
    cdb -G -c "bu Padel!$Fn `"k; g`"; g" .\x64\Debug\Padel.exe
}
```

It runs Padel under cdb, prints the call stack each time `$Fn` runs, and keeps going.

| Part | Why |
|---|---|
| No `-g` | cdb pauses once at startup. That pause is when the `-c` commands run. Skipping it with `-g` means the breakpoint is never set. |
| `-G` | Skips the pause at exit, so cdb closes with the game |
| `bu` | An unresolved breakpoint: it waits until the function's symbol exists, so it is safe to set at startup |
| `"k; g"` | When hit: print the call stack (`k`), then keep going (`g`) |

## Step 6: Check it worked

1. Open a new terminal and run `cdb -version`.
2. Open Neovim once, so codelldb can install itself.
3. Build Padel as **Debug | x64**.
4. In Neovim, open `AudioSystem.cpp` and press `F9` on the first line inside `ShutDown()`.
5. Press `F5`, play, then quit the game.
   1. Neovim pauses on your line, with the full call stack in the panels.
   2. In the REPL, `bt` prints the stack and `p mSystem` prints a member.
6. Press `<leader>dq` to stop and close the panels.
7. Press `<leader>dt` and accept the default to see the cdb trace.

**Result:** you can debug and trace Padel without leaving Neovim.

## Debugger keys

| Key | Action |
|---|---|
| `F5` | Start or continue |
| `F9` | Toggle a breakpoint |
| `F10` | Step over |
| `F11` | Step into |
| `Shift+F11` | Step out |
| `<leader>dl` | Logpoint: print a message and keep running |
| `<leader>dt` | Trace a Padel function with cdb, in a terminal split |
| `<leader>dq` | Quit debugging: stop the game, close the panels and debug terminals |

---

# Part 3: Keys

The leader key is Space.

## The cheat sheet

Press `<leader>h` for a pop-up listing every leader key and every PowerShell function, with descriptions.

1. `$` lines are leader keys, read live from Neovim. Any mapping with a `desc` appears automatically.
2. `@` lines are PowerShell functions, read from the shared profile. The description is the `#` comment directly above each function.

## Leader keys

| Key | Action |
|---|---|
| `<leader>b` | Save all, build Padel (x64), show errors |
| `<leader>e` | Run Padel (x64 Debug) |
| `<leader>h` | Show the cheat sheet |
| `<leader>m` | Outline of the matching C++ header (methods, fields), from clangd |
| `<leader>M` | Command menu: press a number or Enter to run |
| `<leader>o` | Toggle a side panel listing every Python `def` in the file |
| `<leader>O` | Move that panel: right, bottom, top |
| `<leader>r` | Save and run LÖVE |
| `<leader>s` | Swap two words on this line, or in a visual selection |
| `<leader>dl`, `dt`, `dq` | Debugger keys, see Part 2 |

Every pop-up (`h`, `m`, `M`) opens in the same centred window. `q` or `Esc` closes it.

---

# Security

This repo is public.

Never commit passwords, API keys, tokens, or anything that identifies or exposes me.

The profile holds folder paths, which can show Windows usernames, so check them before pushing.

Check every change before pushing.
