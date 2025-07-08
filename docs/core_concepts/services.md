---
sidebar_position: 2
---

# ⚙️ Services

persistent modules basically

```lua
local MathService = Roket.Service "MathService" {
    data = 13
}

function MathService.RoketStart()
    MathService.data = 50
end

function MathService.GetData()
    local data = MathService.data
    MathService.data += 1
    return data
end

return MathService
```

talk about differences to normal require
