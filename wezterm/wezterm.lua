-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = wezterm.config_builder()

local is_linux = function()
	return wezterm.target_triple:find("linux") ~= nil
end

local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

local is_windows = function()
  return wezterm.target_triple:find("windows") ~= nil
end

-- This is where you actually apply your config choices

-- config.color_scheme = 'AdventureTime'
config.color_scheme = 'Solarized Dark Higher Contrast'
-- config.color_scheme = 'Sonokai (Gogh)'

config.font = wezterm.font 'Consolas NF'
config.font_size = 12.0

if is_windows() then
  -- config.default_prog = { os.getenv("USERPROFILE") .. '\\bin\\nu' }
  -- winget location
  config.default_prog = { 'C:\\Program Files\\nu\\bin\\nu.exe' }
  -- needed to get the OpenSSH Agent working on Windows
  -- https://github.com/wez/wezterm/discussions/3772#discussioncomment-7201688
  config.ssh_backend = "Ssh2"
else
  config.default_prog = { os.getenv("HOME") .. '/bin/nu' }
end

config.window_close_confirmation = 'NeverPrompt'
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
  'cmd.exe',
  'pwsh.exe',
  'powershell.exe',
  'wsl.exe',
  'wslhost.exe',
}
-- config.enable_scroll_bar = true
-- config.hide_tab_bar_if_only_one_tab = true

config.show_tab_index_in_tab_bar = false

config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.win32_system_backdrop = 'Acrylic'

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

function formatDomain(domain)
  local prefix, name = string.match(domain, "(%w+)(.*)")

  if prefix == "WSL" then
    return prefix
  else
    return domain
  end
end

wezterm.on('format-tab-title', function(tab)
local pane = tab.active_pane
local title = pane.title
if pane.domain_name then
  title = formatDomain(pane.domain_name)
  -- title = pane.domain_name
end
return title
end)

-- and finally, return the configuration to wezterm
return config

