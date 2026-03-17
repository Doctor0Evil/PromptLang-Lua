# PromptLang-Lua

PromptLang-Lua is a Lua-based AI-chat writing assistant focused on descriptive art prompts, pixel knowledge-graphs, and handpainting-style control for brushwork-oriented outputs.

It is designed to plug into any chat platform that can call Lua code, providing a consistent way to build rich, bracketed prompt expressions for downstream AI models.

## Features

- Descriptive art prompt builder with style catalogs (anime, cinematic, watercolor, pixel-art, and more).
- Pixel knowledge-graph encoding that turns subject, mood, and style into a structured `[kg::...]` bracket block.
- Handpaint / brush-stroke configuration with `[brush::style=...;stroke_density=...;...]` expressions.
- Lightweight ML-style personalization that annotates prompts with `[ml_score::x.xxx]` and simple boost hints.
- Channel-based routing so chat systems can direct messages to `art`, `handpaint`, or `raw` handlers.
- Example REPL and HTTP-style script to demonstrate how to integrate into terminals or basic web stacks.

## Repository layout

```text
promptlang-lua/
  init.lua
  prompt_core.lua
  art_styles.lua
  pixel_kg.lua
  handpaint.lua
  ml_personalizer.lua
  router.lua
  examples/
    demo_repl.lua
    demo_http.lua
  tests/
    test_prompt_core.lua
    test_routes.lua
  README.md
  LICENSE
```

## Installation

Copy the `promptlang-lua` folder into your project and make sure it is on `package.path`, for example:

```lua
package.path = "./promptlang-lua/?.lua;./promptlang-lua/?/init.lua;" .. package.path
local PromptLang = require("init")
```

You can also rename the folder and adjust the `require` paths to match your environment.

## Basic usage

Build a descriptive art prompt:

```lua
local PromptLang = require("init")

local payload = PromptLang.build_chat_payload({
  channel = "art",
  mode = "art",
  subject = "a fox in a cyberpunk alley",
  mood = "moody",
  style = "cinematic",
  medium = "digital painting",
  user_profile = {
    id = "user123",
    mood = "dark",
    style = "cinematic",
    medium = "digital painting"
  }
})

print(payload.prompt)
```

Use the handpaint mode for brush-focused prompts:

```lua
local payload = PromptLang.build_chat_payload({
  channel = "handpaint",
  mode = "handpaint",
  subject = "character portrait with dramatic lighting",
  mood = "bright",
  style = "painterly",
  medium = "oil on canvas",
  user_profile = {
    id = "user777",
    mood = "bright",
    style = "painterly",
    medium = "oil on canvas"
  }
})
```

Integrate with an existing chat loop:

```lua
local PromptLang = require("init")

local function on_user_message(channel, text, user_profile)
  local payload = PromptLang.handle_chat_request({
    channel = channel,
    text = text,
    user_profile = user_profile
  })
  -- send `payload.prompt` to your model, use `payload.meta` for logging/routing
  return payload
end
```

## HTTP example

The `examples/demo_http.lua` script acts like a CGI-style handler:

- `GET /?text=castle+at+sunset&channel=art&mood=bright&style=impressionist`
- It returns a JSON payload containing the bracketed prompt, route info, and meta.

You can wire this into any web server that can execute Lua scripts in a CGI-like fashion.

## Testing

The `tests` folder contains simple Lua scripts that assert core behavior:

```bash
lua tests/test_prompt_core.lua
lua tests/test_routes.lua
```

You can adapt these tests to your preferred test framework (Busted, luaunit, etc.).

## License

See `LICENSE` for the license terms for this project.
