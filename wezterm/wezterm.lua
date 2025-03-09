local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = wezterm.config_builder()
local hostname = wezterm.hostname()

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

wezterm.on('update-status', function(window, pane)
  local meta = pane:get_metadata() or {}
  if meta.is_tardy then
    local secs = meta.since_last_response_ms / 1000.0
    window:set_right_status(string.format('tardy: %5.1fs⏳', secs))
  end
end)

cfg.color_scheme = 'Solarized Dark Higher Contrast'
cfg.font = wezterm.font 'Consolas NF'

if hostname == 'framework-fry' and is_linux() then
  cfg.font_size = 10.0
  cfg.window_frame = {
    font_size = 10.0,
  }
elseif is_darwin() or is_linux() then
  cfg.font_size = 14.0
else
  cfg.font_size = 11.0
end

if is_windows() then
  cfg.default_prog = { os.getenv("USERPROFILE") .. '\\bin\\nu' }
  -- winget location
  -- cfg.default_prog = { 'C:\\Program Files\\nu\\bin\\nu.exe' }
  -- needed to get the OpenSSH Agent working on Windows
  -- https://github.com/wez/wezterm/discussions/3772#discussioncomment-7201688
  cfg.ssh_backend = "Ssh2"

  if wezterm.version > "20240513" then
    -- needed to get the OpenSSH Agent working on Windows
    -- https://github.com/wez/wezterm/discussions/988#discussioncomment-9440847
    cfg.mux_enable_ssh_agent = false
  end

else
  cfg.default_prog = { os.getenv("HOME") .. '/bin/nu' }
end

-- launch straight into nu on WSL
cfg.wsl_domains = {
  {
    name = 'WSL:Ubuntu-22.04',
    distribution = 'Ubuntu-22.04',
    default_prog = { '/home/reilly/bin/nu' },
  }
}

cfg.window_close_confirmation = 'NeverPrompt'
cfg.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
  'nu.exe',
  'cmd.exe',
  'pwsh.exe',
  'powershell.exe',
  -- WSL stuff
  'wsl.exe',
  'wslhost.exe',
  'conhost.exe',
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


function trim(s)
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
table.insert(copy_mode, {
  key = 'c',
  mods = 'CTRL|SHIFT',
  -- Do everything in action_callback to guarantee completion
  -- between actions https://github.com/wez/wezterm/discussions/5384#discussioncomment-9355601
  action = wezterm.action_callback(function(win, pane)
      win:perform_action(act.CopyMode { SetSelectionMode = 'Line' }, pane)
      local selected_text = win:get_selection_text_for_pane(pane)
      local trimmed = trim(selected_text)
      win:copy_to_clipboard(trimmed)
      -- wezterm.log_info('copied: ' .. trimmed)
      win:perform_action(act.ClearSelection, pane)
      -- wezterm.log_info('now selected: ' .. win:get_selection_text_for_pane(pane))
      win:perform_action(act.CopyMode 'Close', pane)
    end),
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

function is_wsl(domain)
  local prefix, name = string.match(domain, "(%w+)(.*)")
  if prefix == "WSL" then
    return true
  else
    return false
  end
end

if is_windows() then

  wezterm.on('format-tab-title', function(tab)
    local pane = tab.active_pane
    local title = pane.title
    if is_wsl(pane.domain_name) then
      title = "🐧 " .. title
    end
    return title
  end)
end

-- and finally, return the configuration to wezterm
return cfg
