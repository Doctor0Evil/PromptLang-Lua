-- safety_age_gate.lua
local M = {}

-- meta may include { user_age = 15, wants_image = true }
function M.is_blocked(meta)
  if not meta then return false end
  if meta.wants_image and meta.user_age and meta.user_age < 18 then
    return true
  end
  return false
end

return M
