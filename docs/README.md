# PromptLang-Lua Plugin

PromptLang-Lua is a Lua-based AI art and prompt-processing engine designed as a **platform-agnostic plugin**.

## Quick Start (Host Integrator)

1. Add this repository to your Lua path.
2. Implement three send functions in your host:
   - `send_text(channel_id, text)`
   - `send_image(channel_id, payload)`
   - `send_graph(channel_id, payload)`
3. Initialize the plugin:

```lua
local ChatInterface = require("platform.chat_interface")
local config        = require("config.example_config")

ChatInterface.init(config, {
  send_text  = function(channel_id, text)  ... end,
  send_image = function(channel_id, payload) ... end,
  send_graph = function(channel_id, payload) ... end,
})
