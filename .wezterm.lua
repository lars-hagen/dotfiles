local wezterm = require 'wezterm'

return {
  -- Enable live config reload
  automatically_reload_config = true,

  -- Colors
  colors = {
    foreground = "#fffaf3",
    background = "#0d0f18",
    cursor_bg = "#ffffff",
    cursor_fg = "#ff0000",
    selection_fg = "#0d0f18",
    selection_bg = "#002a3a",
    ansi = {
      "#222222",
      "#ff000f",
      "#8ce00a",
      "#ffb900",
      "#008df8",
      "#E45FE4",
      "#00d7eb",
      "#ffffff",
    },
    brights = {
      "#222222",
      "#ff000f",
      "#8ce00a",
      "#ffb900",
      "#008df8",
      "#E45FE4",
      "#00d7eb",
      "#ffffff",
    },
  },

  -- Cursor
  cursor_blink_rate = 750,
  default_cursor_style = "SteadyBar",

  -- Font
  font = wezterm.font_with_fallback({
    {family = "FiraCode Nerd Font Mono", weight = "Regular"},
    {family = "FiraCode Nerd Font Mono", weight = "DemiBold", italic = false},
    {family = "FiraCode Nerd Font Mono", weight = "Regular", italic = true},
  }),
  font_size = 12.0,

  -- Window
  window_decorations = "RESIZE",
  window_background_opacity = 0.8,
  macos_window_background_blur = 30,
  window_padding = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5,
  },
}
