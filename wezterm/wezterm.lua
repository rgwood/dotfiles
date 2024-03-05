-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- config.color_scheme = 'AdventureTime'
config.color_scheme = 'Solarized Dark Higher Contrast'
-- config.color_scheme = 'Sonokai (Gogh)'

config.font = wezterm.font 'Consolas NF'
config.font_size = 12.0

if wezterm.target_triple:find("windows") then
  config.default_prog = { os.getenv("USERPROFILE") .. '\\bin\\nu' }
  -- needed to get the OpenSSH Agent working on Windows
  -- https://github.com/wez/wezterm/discussions/3772#discussioncomment-7201688
  config.ssh_backend = "Ssh2"
else
  config.default_prog = { os.getenv("HOME") .. '/bin/nu' }
end

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

