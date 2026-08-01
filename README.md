# trino.nvim

## Playground
```bash
nix run github:thibautvas/trino.nvim
```

## Example
Start a docker container running trino in the background:
```bash
docker run -d --name trino -p 8080:8080 trinodb/trino
```
Or equivalently:
```bash
nix run github:thibautvas/trino.nvim#dockerTrino
```

Configure trino.nvim in `~/.config/nvim/init.lua`:
```lua
require("trino").setup({
  host = "localhost",
  port = 8080,
  catalog = "tpch",
  http_headers = { ["X-Trino-Original-User"] = "user" },
  http_scheme = "http",
  auth = {
    type = "none",
    username = nil,
    password = nil,
  },
  verify = false,
})
```
And optionally:
```lua
vim.keymap.set("v", "<leader>ef", require("trino").run_visual)
```

Try it out by selecting the following and running `:'<,'>RunSQL`,
or an equivalent keymap:
```sql
select *
from tpch.tiny.nation
limit 10
```
