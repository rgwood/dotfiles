local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = wezterm.config_builder()

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

cfg.color_scheme = 'Solarized Dark Higher Contrast'
cfg.font = wezterm.font 'Consolas NF'

if is_darwin() or is_linux() then
  cfg.font_size = 14.0
else
  cfg.font_size = 11.0
end

if is_windows() then
  -- config.default_prog = { os.getenv("USERPROFILE") .. '\\bin\\nu' }
  -- winget location
  cfg.default_prog = { 'C:\\Program Files\\nu\\bin\\nu.exe' }
  -- needed to get the OpenSSH Agent working on Windows
  -- https://github.com/wez/wezterm/discussions/3772#discussioncomment-7201688
  cfg.ssh_backend = "Ssh2"
else
  cfg.default_prog = { os.getenv("HOME") .. '/bin/nu' }
end

cfg.window_close_confirmation = 'NeverPrompt'
cfg.skip_close_confirmation_for_processes_named = {
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

cfg.show_tab_index_in_tab_bar = false
cfg.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
cfg.win32_system_backdrop = 'Acrylic'

cfg.keys = {
  { key = "v", mods = "CTRL", action = wezterm.action { PasteFrom = "Clipboard" } },
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

local copy_mode = wezterm.gui.default_key_tables().copy_mode
-- remove existing ctrl+c keybinding
for i, v in ipairs(copy_mode) do
  if v.key == 'c' and v.mods == 'CTRL' then
    table.remove(copy_mode, i)
    break
  end
end


function Trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

table.insert(copy_mode, {
  key = 'c',
  mods = 'CTRL',
  action = act.Multiple { {
    CopyTo = 'ClipboardAndPrimarySelection'
  }, {
    CopyMode = 'Close'
  } }
})

-- copy the entire line
-- wtf why doesn't this work the first time on a new tab? file an issue
table.insert(copy_mode, {
  key = 'c',
  mods = 'CTRL|SHIFT',
  action = act.Multiple {
    act.CopyMode { SetSelectionMode = 'Line' },
    wezterm.action_callback(function(win, pane)
      local selected_text = win:get_selection_text_for_pane(pane)
      local trimmed = Trim(selected_text)
      win:copy_to_clipboard(trimmed)
      wezterm.log_info('copied: ' .. trimmed)
      win:perform_action(act.ClearSelection, pane)
      wezterm.log_info('now selected: ' .. win:get_selection_text_for_pane(pane))
    end),
    { CopyMode = 'Close'}
}
})

-- TODO get this working right... I want to be able to hold shift and arrow keys for selection
-- table.insert(copy_mode, {
--   key = 'RightArrow',
--   mods = 'SHIFT',
--   action = act.Multiple {
--     act.CopyMode { SetSelectionMode = 'Cell' },
--     act.CopyMode 'MoveRight',
--   }
-- })

cfg.key_tables = {
  copy_mode = copy_mode
}

function formatDomain(domain)
  local prefix, name = string.match(domain, "(%w+)(.*)")

  if prefix == "WSL" then
    return prefix
  else
    return domain
  end
end

if is_windows() then
  wezterm.on('format-tab-title', function(tab)
    local pane = tab.active_pane
    local title = pane.title
    if pane.domain_name then
      title = formatDomain(pane.domain_name)
    end
    return title
  end)
end

-- and finally, return the configuration to wezterm
return cfg
