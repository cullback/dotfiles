#!/usr/bin/env fish

# tinty hook: runs after every `tinty apply <scheme>`.
#
# tinty renders the Helix theme (from the tinted-helix template) and exports the
# active scheme's palette as TINTY_SCHEME_PALETTE_BASE*_HEX_{R,G,B} env vars.
# We reuse those palette values to generate Ghostty and Zellij themes from the
# same source, then live-reload all three tools so colors change without a
# restart. See tinty/README in the repo for the reload mechanics per tool.

function _hex --argument-names base
    set -l rn TINTY_SCHEME_PALETTE_{$base}_HEX_R
    set -l gn TINTY_SCHEME_PALETTE_{$base}_HEX_G
    set -l bn TINTY_SCHEME_PALETTE_{$base}_HEX_B
    echo (string join "" $$rn $$gn $$bn)
end

for n in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    set -g b$n (_hex BASE$n)
end

function _write_ghostty_theme
    set -l dir ~/.config/ghostty/themes
    mkdir -p $dir
    # Bright ANSI (8-15): base16 reuses the normal colors; base24 has dedicated
    # bright variants in base10-17, so use those when the scheme is base24.
    set -l p8 $b03
    set -l p9 $b08
    set -l p10 $b0B
    set -l p11 $b0A
    set -l p12 $b0D
    set -l p13 $b0E
    set -l p14 $b0C
    set -l p15 $b07
    if test "$TINTY_SCHEME_SYSTEM" = base24
        set p9 (_hex BASE12)
        set p10 (_hex BASE14)
        set p11 (_hex BASE13)
        set p12 (_hex BASE16)
        set p13 (_hex BASE17)
        set p14 (_hex BASE15)
    end
    # palette 0-7 use the standard base16 ANSI mapping.
    printf '%s\n' \
        "palette = 0=#$b00" \
        "palette = 1=#$b08" \
        "palette = 2=#$b0B" \
        "palette = 3=#$b0A" \
        "palette = 4=#$b0D" \
        "palette = 5=#$b0E" \
        "palette = 6=#$b0C" \
        "palette = 7=#$b05" \
        "palette = 8=#$p8" \
        "palette = 9=#$p9" \
        "palette = 10=#$p10" \
        "palette = 11=#$p11" \
        "palette = 12=#$p12" \
        "palette = 13=#$p13" \
        "palette = 14=#$p14" \
        "palette = 15=#$p15" \
        "background = #$b00" \
        "foreground = #$b05" \
        "cursor-color = #$b05" \
        "cursor-text = #$b00" \
        "selection-background = #$b02" \
        "selection-foreground = #$b05" >$dir/tinty
end

function _zc --argument-names name base bg e0 e1 e2 e3
    printf '%s\n' \
        "        $name {" \
        "            base \"#$base\"" \
        "            background \"#$bg\"" \
        "            emphasis_0 \"#$e0\"" \
        "            emphasis_1 \"#$e1\"" \
        "            emphasis_2 \"#$e2\"" \
        "            emphasis_3 \"#$e3\"" \
        "        }"
end

function _write_zellij_theme
    set -l dir ~/.config/zellij/themes
    mkdir -p $dir
    # Component theme with explicit base02 backgrounds for content selections, so
    # highlights stay subtle and scheme-consistent. The old simple fg/bg format
    # let Zellij derive highlight backgrounds from bright accents, which clashed.
    set -l acc $b09 $b0D $b0B $b0E
    begin
        echo "themes {"
        echo "    tinty {"
        _zc text_unselected $b05 $b00 $acc
        _zc text_selected $b05 $b02 $acc
        _zc ribbon_unselected $b05 $b01 $acc
        _zc ribbon_selected $b00 $b0D $b09 $b0B $b0E $b08
        _zc table_title $b0D $b00 $acc
        _zc table_cell_unselected $b05 $b00 $acc
        _zc table_cell_selected $b05 $b02 $acc
        _zc list_unselected $b05 $b00 $acc
        _zc list_selected $b05 $b02 $acc
        _zc frame_selected $b0C $b00 $acc
        _zc frame_highlight $b09 $b00 $acc
        _zc exit_code_success $b0B $b00 $acc
        _zc exit_code_error $b08 $b00 $acc
        echo "    }"
        echo "}"
    end >$dir/tinty.kdl
end

function _write_gitui_theme
    set -l dest ~/.config/gitui/theme.ron
    mkdir -p (dirname $dest)
    # gitui loads theme.ron directly (no theme-name indirection). Replace any
    # existing symlink so we generate a real file instead of writing into the
    # repo's static seed copy.
    rm -f $dest
    printf '%s\n' \
        "(" \
        "    selected_tab: Some(\"Reset\")," \
        "    command_fg: Some(\"#$b05\")," \
        "    selection_bg: Some(\"#$b04\")," \
        "    selection_fg: Some(\"#$b05\")," \
        "    cmdbar_bg: Some(\"#$b01\")," \
        "    cmdbar_extra_lines_bg: Some(\"#$b01\")," \
        "    disabled_fg: Some(\"#$b03\")," \
        "    diff_line_add: Some(\"#$b0B\")," \
        "    diff_line_delete: Some(\"#$b08\")," \
        "    diff_file_added: Some(\"#$b0B\")," \
        "    diff_file_removed: Some(\"#$b08\")," \
        "    diff_file_moved: Some(\"#$b0E\")," \
        "    diff_file_modified: Some(\"#$b09\")," \
        "    commit_hash: Some(\"#$b07\")," \
        "    commit_time: Some(\"#$b04\")," \
        "    commit_author: Some(\"#$b0C\")," \
        "    danger_fg: Some(\"#$b08\")," \
        "    push_gauge_bg: Some(\"#$b0D\")," \
        "    push_gauge_fg: Some(\"#$b00\")," \
        "    tag_fg: Some(\"#$b06\")," \
        "    branch_fg: Some(\"#$b0C\")" \
        ")" >$dest
end

function _place_helix_theme
    set -q TINTY_THEME_FILE_PATH; or return
    set -l dir ~/.config/helix/themes
    mkdir -p $dir
    cp -f $TINTY_THEME_FILE_PATH $dir/tinty.toml
end

function _reload_helix
    pkill -USR1 hx 2>/dev/null
    return 0
end

function _reload_zellij
    # Zellij live-reloads when config.kdl changes; bump its mtime so the running
    # session re-reads themes/tinty.kdl.
    test -e ~/.config/zellij/config.kdl; and touch ~/.config/zellij/config.kdl
    return 0
end

function _reload_ghostty
    # Ghostty reloads its config on SIGUSR2 (re-reads themes/tinty). No
    # Accessibility permission, focus, or AppleScript needed - same idea as
    # Helix's SIGUSR1 above.
    pkill -USR2 ghostty 2>/dev/null
    return 0
end

_place_helix_theme
_write_ghostty_theme
_write_zellij_theme
_write_gitui_theme

_reload_helix
_reload_zellij
_reload_ghostty
# gitui has no live reload; the new theme.ron applies on its next launch.
