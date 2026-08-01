# trino.nvim

## Playground
```bash
nix run github:thibautvas/trino.nvim
```

## Example
Start a docker container running Trino in the background:
```bash
docker run -d --name trino -p 8080:8080 trinodb/trino
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
