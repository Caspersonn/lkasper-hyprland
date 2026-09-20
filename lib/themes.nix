{ lib, inputs }:
let
wallpaperRoot = ../wallpapers;
paletteDir = wallpaperRoot + "/palettes";
pairs = import (wallpaperRoot + "/pairs.nix");

dataRoot = ".local/share/lkasper-hyprland";
themeRoot = "${dataRoot}/themes";
stateDir = "$HOME/.config/lkasper-hyprland";

modes = [
  "light"
  "dark"
];
pairNames = builtins.attrNames pairs;

imageNames = builtins.filter (
  n: lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n || lib.hasSuffix ".jpeg" n
) (builtins.attrNames (builtins.readDir wallpaperRoot));

claimed = lib.concatMap (pair: builtins.attrValues pairs.${pair}) pairNames;
unpaired = builtins.filter (image: !(builtins.elem image claimed)) imageNames;
duplicated = builtins.filter (image: lib.count (c: c == image) claimed > 1) (lib.unique claimed);
missingImages = builtins.filter (image: !(builtins.elem image imageNames)) claimed;
malformed = builtins.filter (
  pair:
  builtins.attrNames pairs.${pair} != [
    "dark"
    "light"
  ]
) pairNames;

slugOf = image: lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" image));

paletteOf = image: builtins.fromJSON (builtins.readFile (paletteDir + "/${slugOf image}.json"));

missingPalettes = builtins.filter (
  image: !(builtins.pathExists (paletteDir + "/${slugOf image}.json"))
) claimed;

defaultPair = if builtins.elem "beach" pairNames then "beach" else builtins.head pairNames;
defaultMode = "dark";

hexToRgb = inputs.nix-colors.lib.conversions.hexToRGBString ", ";

retrobox = {
  dark = {
    bg = "1c1c1c";
    fg = "ebdbb2";
    surface = "303030";
    selection = "2a405a";
    comment = "928374";
    accent = "d79921";
    info = "83a598";
    ansi = [
      "1c1c1c"
      "cc241d"
      "98971a"
      "d79921"
      "458588"
      "b16286"
      "689d6a"
      "a89984"
      "928374"
      "fb5944"
      "b8bb26"
      "fabd2f"
      "83a598"
      "d3869b"
      "8ec07c"
      "ebdbb2"
    ];
  };
  light = {
    bg = "fbf1c7";
    fg = "3c3836";
    surface = "e5d4b1";
    selection = "b0d0d0";
    comment = "928374";
    accent = "b57614";
    info = "076678";
    ansi = [
      "3c3836"
      "cc241d"
      "98971a"
      "d79921"
      "458588"
      "b16286"
      "689d6a"
      "7c6f64"
      "928374"
      "9d0006"
      "79740e"
      "b57614"
      "076678"
      "8f3f71"
      "427b58"
      "fbf1c7"
    ];
  };
};

base16Slots = map (c: "base0${c}") (lib.stringToCharacters "0123456789ABCDEF");

accentPalette =
  palette:
  palette
  // {
    base0A = palette.accent2;
    base0B = palette.accent3;
    base0C = palette.accent2;
    base0D = palette.accent;
    base0E = palette.accent3;
    base0F = palette.accent;
  };

uiThemeSchema = 1;

hex = value: "#" + lib.toLower value;

uiTheme = mode: palette: {
  schema = uiThemeSchema;
  inherit mode;

  background = hex palette.base00;
  surface = hex palette.base01;
  foreground = hex palette.base05;
  muted = hex palette.base04;

  accent = hex palette.accent;

  red = hex palette.base08;
  yellow = hex palette.base0A;
  green = hex palette.base0B;
  blue = hex palette.base0D;
};

uiThemes = lib.listToAttrs (
  lib.concatMap (
    pair:
    map (mode: {
      name = "${pair}/${mode}";
      value = uiTheme mode (paletteOf pairs.${pair}.${mode});
    }) modes
  ) pairNames
);

themeFiles =
  pair: mode:
  let
    image = pairs.${pair}.${mode};
    palette = paletteOf image;
    shell = accentPalette palette;
    accent = palette.accent;
    rb = retrobox.${mode};
    rbAnsi = i: builtins.elemAt rb.ansi i;
    wallpaper = wallpaperRoot + "/${image}";
  in
  {
    "ui-theme.json" = builtins.toJSON (uiTheme mode palette);

    "colors.json" = builtins.toJSON (
      shell
      // {
        inherit mode;
        background = "#${shell.base00}";
        foreground = "#${shell.base05}";
        accent = accent;
        hairline = if mode == "light" then shell.base05 else shell.base07;
        shade = if mode == "light" then shell.base03 else "000000";
      }
    );

    "colors-ansi.json" = builtins.toJSON (palette // { inherit mode; });

    "nvim.lua" = ''
      return {
        mode = "${mode}",
        colorscheme = "retrobox",
        background = "${mode}",
        wallpaper_background = "#${palette.base00}",
        palette = {
      ${lib.concatMapStringsSep "\n" (slot: "    ${slot} = \"#${palette.${slot}}\",") base16Slots}
        },
      }
    '';

    "wallpaper.path" = "${wallpaper}\n";

    "foot.ini" = ''
      [colors]
      background=${rb.bg}
      foreground=${rb.fg}
      selection-background=${rb.selection}
      selection-foreground=${rb.fg}
      ${lib.concatStringsSep "\n" (lib.genList (i: "regular${toString i}=${rbAnsi i}") 8)}
      ${lib.concatStringsSep "\n" (lib.genList (i: "bright${toString i}=${rbAnsi (i + 8)}") 8)}
    '';

    "ghostty" = ''
      background = #${rb.bg}
      foreground = #${rb.fg}
      selection-background = #${rb.selection}
      selection-foreground = #${rb.fg}
      ${lib.concatStringsSep "\n" (lib.genList (i: "palette = ${toString i}=#${rbAnsi i}") 16)}
    '';

    "clipse-theme.json" = builtins.toJSON {
      useCustomTheme = true;
      TitleFore = "#${rb.bg}";
      TitleBack = "#${rb.fg}";
      TitleInfo = "#${rbAnsi 12}";
      NormalTitle = "#${rb.fg}";
      DimmedTitle = "#${rb.comment}";
      SelectedTitle = "#${rbAnsi 11}";
      NormalDesc = "#${rb.comment}";
      DimmedDesc = "#${rb.comment}";
      SelectedDesc = "#${rbAnsi 11}";
      StatusMsg = "#${rbAnsi 10}";
      PinIndicatorColor = "#${rbAnsi 11}";
      SelectedBorder = "#${rb.accent}";
      SelectedDescBorder = "#${rb.accent}";
      FilteredMatch = "#${rbAnsi 10}";
      FilterPrompt = "#${rbAnsi 10}";
      FilterInfo = "#${rbAnsi 12}";
      FilterText = "#${rb.fg}";
      FilterCursor = "#${rb.accent}";
      HelpKey = "#${rbAnsi 12}";
      HelpDesc = "#${rb.comment}";
      PageActiveDot = "#${rb.accent}";
      PageInactiveDot = "#${rb.comment}";
      DividerDot = "#${rb.comment}";
      PreviewedText = "#${rb.fg}";
      PreviewBorder = "#${rb.comment}";
    };

    "fish.fish" = ''
      set -U fish_color_normal ${rb.fg}
      set -U fish_color_command ${rbAnsi 10}
      set -U fish_color_keyword ${rbAnsi 9}
      set -U fish_color_quote ${rbAnsi 10}
      set -U fish_color_redirection ${rbAnsi 14}
      set -U fish_color_end ${rbAnsi 11}
      set -U fish_color_error ${rbAnsi 9}
      set -U fish_color_param ${rb.fg}
      set -U fish_color_option ${rbAnsi 14}
      set -U fish_color_comment ${rb.comment}
      set -U fish_color_operator ${rbAnsi 14}
      set -U fish_color_escape ${rbAnsi 11}
      set -U fish_color_autosuggestion ${rb.comment}
      set -U fish_color_cwd ${rbAnsi 11}
      set -U fish_color_user ${rbAnsi 14}
      set -U fish_color_host ${rbAnsi 12}
      set -U fish_color_valid_path --underline
      set -U fish_color_selection ${rb.fg} --background=${rb.selection}
      set -U fish_color_search_match --background=${rb.selection}
      set -U fish_pager_color_prefix ${rb.accent} --bold
      set -U fish_pager_color_completion ${rb.fg}
      set -U fish_pager_color_description ${rb.comment}
      set -U fish_pager_color_progress ${rb.comment}
      set -U fish_pager_color_selected_background --background=${rb.selection}
      set -U lkh_fg ${rb.fg}
      set -U lkh_dim ${rb.comment}
      set -U lkh_red ${rbAnsi 9}
      set -U lkh_green ${rbAnsi 10}
      set -U lkh_yellow ${rbAnsi 11}
      set -U lkh_blue ${rbAnsi 12}
      set -U lkh_magenta ${rbAnsi 13}
      set -U lkh_cyan ${rbAnsi 14}
    '';

    "tmux.conf" = ''
      set -g status-style "fg=#${rb.fg},bg=#${rb.surface}"
      set -g status-left-style "fg=#${rb.accent},bold"
      set -g status-right-style "fg=#${rb.comment}"
      set -g window-status-style "fg=#${rb.comment}"
      set -g window-status-current-style "fg=#${rb.bg},bg=#${rb.accent},bold"
      set -g window-status-activity-style "fg=#${rbAnsi 3}"
      set -g pane-border-style "fg=#${rb.comment}"
      set -g pane-active-border-style "fg=#${rb.info}"
      set -g message-style "fg=#${rb.bg},bg=#${rb.accent}"
      set -g message-command-style "fg=#${rb.fg},bg=#${rb.surface}"
      set -g mode-style "fg=#${rb.fg},bg=#${rb.selection}"
      set -g clock-mode-colour "#${rb.info}"
      set -g copy-mode-match-style "fg=#${rb.bg},bg=#${rb.info}"
      set -g copy-mode-current-match-style "fg=#${rb.bg},bg=#${rb.accent}"
    '';

    "btop.theme" = ''
      theme[main_bg]="#${rb.bg}"
      theme[main_fg]="#${rb.fg}"
      theme[title]="#${rb.fg}"
      theme[hi_fg]="#${rbAnsi 11}"
      theme[selected_bg]="#${rb.selection}"
      theme[selected_fg]="#${rb.fg}"
      theme[inactive_fg]="#${rb.comment}"
      theme[graph_text]="#${rb.comment}"
      theme[meter_bg]="#${rb.surface}"
      theme[proc_misc]="#${rbAnsi 12}"
      theme[cpu_box]="#${rbAnsi 10}"
      theme[mem_box]="#${rbAnsi 11}"
      theme[net_box]="#${rbAnsi 13}"
      theme[proc_box]="#${rbAnsi 12}"
      theme[div_line]="#${rb.comment}"
      theme[temp_start]="#${rbAnsi 10}"
      theme[temp_mid]="#${rbAnsi 11}"
      theme[temp_end]="#${rbAnsi 9}"
      theme[cpu_start]="#${rbAnsi 10}"
      theme[cpu_mid]="#${rbAnsi 11}"
      theme[cpu_end]="#${rbAnsi 9}"
      theme[free_start]="#${rbAnsi 10}"
      theme[cached_start]="#${rbAnsi 14}"
      theme[available_start]="#${rbAnsi 11}"
      theme[used_start]="#${rbAnsi 9}"
      theme[download_start]="#${rbAnsi 14}"
      theme[download_mid]="#${rbAnsi 12}"
      theme[download_end]="#${rbAnsi 13}"
      theme[upload_start]="#${rbAnsi 14}"
      theme[upload_mid]="#${rbAnsi 12}"
      theme[upload_end]="#${rbAnsi 13}"
    '';

    "starship.toml" = ''
      add_newline = false
      format = "$directory$git_branch$git_status$character"

      [directory]
      style = "bold #${accent}"
      truncation_length = 4

      [git_branch]
      style = "bold #${palette.base05}"

      [git_status]
      style = "#${palette.base05}"

      [character]
      success_symbol = "[>](bold #${accent})"
      error_symbol = "[>](bold #${palette.base08})"
    '';

    "hypr.conf" = ''
      general {
        col.active_border = rgba(${accent}ee)
        col.inactive_border = rgba(${palette.base03}aa)
      }

      group {
        col.border_active = rgba(${accent}ee)
        col.border_inactive = rgba(${palette.base03}aa)
      }
    '';

    "hyprlock.conf" = ''
      $lkh_surface = rgb(${hexToRgb palette.base02})
      $lkh_foreground = rgb(${hexToRgb palette.base05})
      $lkh_muted = rgb(${hexToRgb palette.base04})
      $lkh_accent = rgb(${hexToRgb accent})
      $lkh_ok = rgb(${hexToRgb palette.base0B})
    '';

    "gtk.css" = ''
      @define-color accent_color #${accent};
      @define-color accent_bg_color #${accent};
      @define-color accent_fg_color #${palette.base00};
      @define-color theme_bg_color #${palette.base00};
      @define-color theme_fg_color #${palette.base05};
      @define-color theme_base_color #${palette.base00};
      @define-color theme_text_color #${palette.base05};
    '';

    "opencode.json" = builtins.toJSON {
      "$schema" = "https://opencode.ai/theme.json";
      theme = {
        primary = "#${palette.base0D}";
        secondary = "#${palette.base0E}";
        accent = "#${accent}";
        error = "#${palette.base08}";
        warning = "#${palette.base09}";
        success = "#${palette.base0B}";
        info = "#${palette.base0D}";
        text = "#${palette.base05}";
        textMuted = "#${palette.base04}";
        background = "#${palette.base00}";
        backgroundPanel = "#${palette.base01}";
        backgroundElement = "#${palette.base02}";
        border = "#${palette.base03}";
        borderActive = "#${accent}";
        borderSubtle = "#${palette.base02}";
        diffAdded = "#${palette.base0B}";
        diffRemoved = "#${palette.base08}";
        diffContext = "#${palette.base04}";
        diffHunkHeader = "#${palette.base0D}";
        diffHighlightAdded = "#${palette.base0B}";
        diffHighlightRemoved = "#${palette.base08}";
        diffAddedBg = "#${palette.base01}";
        diffRemovedBg = "#${palette.base01}";
        diffContextBg = "#${palette.base00}";
        diffLineNumber = "#${palette.base03}";
        diffAddedLineNumberBg = "#${palette.base01}";
        diffRemovedLineNumberBg = "#${palette.base01}";
        markdownText = "#${palette.base05}";
        markdownHeading = "#${palette.base0D}";
        markdownLink = "#${palette.base0E}";
        markdownLinkText = "#${palette.base0C}";
        markdownCode = "#${palette.base0B}";
        markdownBlockQuote = "#${palette.base04}";
        markdownEmph = "#${palette.base09}";
        markdownStrong = "#${palette.base0A}";
        markdownHorizontalRule = "#${palette.base03}";
        markdownListItem = "#${palette.base0D}";
        markdownListEnumeration = "#${palette.base0C}";
        markdownImage = "#${palette.base0E}";
        markdownImageText = "#${palette.base0C}";
        markdownCodeBlock = "#${palette.base0B}";
        syntaxComment = "#${palette.base03}";
        syntaxKeyword = "#${palette.base0E}";
        syntaxFunction = "#${palette.base0D}";
        syntaxVariable = "#${palette.base08}";
        syntaxString = "#${palette.base0B}";
        syntaxNumber = "#${palette.base09}";
        syntaxType = "#${palette.base0A}";
        syntaxOperator = "#${palette.base05}";
        syntaxPunctuation = "#${palette.base04}";
      };
    };
  };
in
{
  inherit
    wallpaperRoot
    paletteDir
    pairs
    pairNames
    modes
    dataRoot
    themeRoot
    stateDir
    claimed
    slugOf
    paletteOf
    defaultPair
    defaultMode
    base16Slots
    accentPalette
    themeFiles
    uiTheme
    uiThemes
    uiThemeSchema
    ;

  validation = {
    inherit
      unpaired
      duplicated
      missingImages
      missingPalettes
      malformed
      ;
  };
}
