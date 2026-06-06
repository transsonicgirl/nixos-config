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
            { "<Leader>db", ":DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" }},
            { "<Leader>dc", ":DapContinue<CR>", { desc = "Continue" }},
            { "<Leader>di", ":DapStepInto<CR>", { desc = "Step into" }},
            { "<Leader>do", ":DapStepOver<CR>", { desc = "Step over" }},
            { "<Leader>du", ":DapStepOut<CR>", { desc = "Step out" }},
            { "<Leader>dn", ":DapNew<CR>", { desc = "New Debug Session" }},
            { "<Leader>dx", ":DapTerminate<CR>", { desc = "Terminate session" }},
        },
        config = function()
            local dap = require("dap")
            require("dapui").setup()
            local dapui = require("dapui")


            -- python
            require("dap-python").setup("python3")

            -- c++
            dap.adapters.cppdbg = {
                id = "cppdbg",
                type = "executable",
                command = vim.fn.expand("~/.cpptools/extension/debugAdapters/bin/OpenDebugAD7"),
            }

            dap.configurations.cpp = {
                {
                    name = "Launch file",
                    type = "cppdbg",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopAtEntry = true,
                },
                {
                    name = "Attach to gdbserver :1234",
                    type = "cppdbg",
                    request = "launch",
                    MIMode = "gdb",
                    miDebuggerServerAddress = "localhost:1234",
                    miDebuggerPath = "/usr/bin/gdb",
                    cwd = "${workspaceFolder}",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
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
