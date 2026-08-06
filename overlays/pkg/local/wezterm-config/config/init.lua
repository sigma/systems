local wezterm = require('wezterm')

---@class Config
---@field options table
local Config = {}
Config.__index = Config

---Initialize Config
---@return Config
function Config:init()
   local config = setmetatable({ options = wezterm.config_builder() }, self)
   return config
end

---Append to `Config.options`
---@param new_options table new options to append
---@return Config
function Config:append(new_options)
   for k, v in pairs(new_options) do
      if self.options[k] ~= nil then
         wezterm.log_warn(
            'Duplicate config option detected: ',
            { old = self.options[k], new = new_options[k] }
         )
         goto continue
      end
      self.options[k] = v
      ::continue::
   end
   return self
end

---Apply a plugin to the config
---@param plugin function|table the plugin to apply
---@param opts table the options to pass to the plugin
---@return Config
function Config:apply(plugin, opts)
   if not opts then
      opts = {}
   end
   if type(plugin) == 'function' then
      plugin(self.options, opts)
   else
      plugin.apply_to_config(self.options, opts)
   end
   return self
end

return Config
