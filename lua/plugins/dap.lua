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

      -- What to launch: Padel's Debug build
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
      end, {desc = "Logpoint: print a message and keep running"})

      -- Trace a Padel function with cdb, in a terminal split
      vim.keymap.set("n", "<leader>dt", function()
        local fn = vim.fn.input("Trace function: ", "AudioSystem::~AudioSystem")
        vim.cmd("botright 15split | terminal pwsh -NoLogo -Command padeltrace '" .. fn .. "'")
      end, { desc = "Trace a Padel function" })
    end,
  },
}
