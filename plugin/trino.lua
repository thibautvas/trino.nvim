vim.api.nvim_create_user_command("RunSQL", require("trino").run_visual, { range = true })
