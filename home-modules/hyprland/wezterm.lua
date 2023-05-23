local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'OneHalfLight'

config.font = wezterm.font_with_fallback {
  'Hack',
  'Noto Sans CJK SC',
  'Noto Music',
  'Noto Sans Symbols',
  'Noto Sans Symbols 2',
  'Noto Color Emoji',
  'Symbols Nerd Font Mono',
}

config.window_frame = {
  font = wezterm.font_with_fallback {
    { family = 'Inter', weight = 'Medium' },
    { family = 'Noto Sans CJK SC', weight = 'Medium' },
  },
  active_titlebar_bg = '#e6e6e6',
  inactive_titlebar_bg = '#e6e6e6',
}

config.colors = {
  tab_bar = {
    inactive_tab_edge = '#cdcdcd',
    active_tab = {
      bg_color = '#fafafa',
      fg_color = '#000000',
    },
    inactive_tab = {
      bg_color = '#d7d7d7',
      fg_color = '#4d4d4d',
    },
    inactive_tab_hover = {
      bg_color = '#c0c0c0',
      fg_color = '#404040',
    },
    new_tab = {
      bg_color = '#d7d7d7',
      fg_color = '#333333',
    },
    new_tab_hover = {
      bg_color = '#c0c0c0',
      fg_color = '#404040',
    },
  },
  scrollbar_thumb = '#d7d7d7',
}

config.keys = {
  { key = 'LeftArrow', mods = 'SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'SHIFT', action = wezterm.action.ActivateTabRelative(1) },
}

config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = true
config.scrollback_lines = 10000
config.alternate_buffer_wheel_scroll_speed = 1

return config
