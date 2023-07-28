-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = 'AdventureTime'

config.font = wezterm.font 'Consolas NF'
config.font_size = 14.0

-- if on linux use linuxbrew, if on mac use homebrew
if wezterm.target_triple == "x86_64-unknown-linux-gnu" then
    config.default_prog = {'/home/linuxbrew/.linuxbrew/bin/nu'}
elseif string.find(wezterm.target_triple, 'apple%-darwin') then
    config.default_prog = {'/opt/homebrew/bin/nu'}
end

-- and finally, return the configuration to wezterm
return config
