-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- config.color_scheme = 'AdventureTime'
config.color_scheme = 'Solarized Dark Higher Contrast'
-- config.color_scheme = 'Sonokai (Gogh)'


config.font = wezterm.font 'Consolas NF'
config.font_size = 16.0

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { os.getenv("USERPROFILE") .. '\\bin\\nu' }
else
  config.default_prog = { os.getenv("HOME") .. '/bin/nu' }
end



-- if wezterm.target_triple == "x86_64-unknown-linux-gnu" then
--     config.default_prog = {'/home/reilly/bin/nu'}
-- elseif string.find(wezterm.target_triple, 'apple%-darwin') then
--     config.default_prog = {'/Users/reilly/bin/nu'}
-- end

config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false

config.keys = {
  {key="v", mods="CTRL", action=wezterm.action{PasteFrom="Clipboard"}},
  {
    key = "UpArrow",
    mods = "SHIFT",
    action = wezterm.action {
      ScrollToPrompt = -1
    }
  }, {
    key = "DownArrow",
    mods = "SHIFT",
    action = wezterm.action {
      ScrollToPrompt = 1
    }
  }
}

-- and finally, return the configuration to wezterm
return config

