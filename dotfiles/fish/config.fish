#!/usr/bin/env fish
# copy this file to ~/.config/fish/config

if status is-interactive
    # Commands to run in interactive sessions can go here
    set --universal fish_greeting
    source $HOME/.config/fish/create_abbrs.fish
    source $HOME/.config/fish/functions/__ginshio_copy-graphisc-testcases.fish
    source $HOME/.config/fish/functions/__ginshio_set-git-urls.fish
    source $HOME/.config/fish/functions/__ginshio_source-posix.fish
    source $HOME/.config/fish/functions/__ginshio_zswap-statistics.fish
end
