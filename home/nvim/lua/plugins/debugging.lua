return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
            "mfussenegger/nvim-dap-python",
        },
        keys = {
            -- dap binds
            { "<Leader>db", ":DapToggleBreakpoint<CR>", desc = "Toggle breakpoint" },
            { "<Leader>dc", ":DapContinue<CR>", desc = "Continue" },
            { "<Leader>di", ":DapStepInto<CR>", desc = "Step into" },
            { "<Leader>do", ":DapStepOver<CR>", desc = "Step over" },
            { "<Leader>du", ":DapStepOut<CR>", desc = "Step out" },
            { "<Leader>dn", ":DapNew<CR>", desc = "New Debug Session" },
            { "<Leader>dx", ":DapTerminate<CR>", desc = "Terminate session" },
        },
        config = function()
            local dap = require("dap")
            require("dapui").setup()
            local dapui = require("dapui")


            -- python (needs the `debugpy` module available to python3)
            require("dap-python").setup("python3")

            -- c/c++: use gdb's native DAP interface (gdb >= 14). No cpptools /
            -- OpenDebugAD7 needed, and gdb is already provided via Nix.
            dap.adapters.gdb = {
                type = "executable",
                command = "gdb",
                args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
            }

            dap.configurations.cpp = {
                {
                    name = "Launch file",
                    type = "gdb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopAtBeginningOfMainSubprogram = true,
                },
                {
                    name = "Attach to gdbserver :1234",
                    type = "gdb",
                    request = "attach",
                    target = "localhost:1234",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                },
            }

            -- c/rust
            dap.configurations.c = dap.configurations.cpp
            dap.configurations.rust = dap.configurations.cpp

            -- dapui listeners
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    }
}
