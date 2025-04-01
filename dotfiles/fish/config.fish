#!/usr/bin/env fish

source {{@@ _dotfile_abs_dst @@}}/functions/__ginshio_source-posix.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
    set --universal fish_greeting
    source {{@@ _dotfile_abs_dst @@}}/create_abbrs.fish
    source {{@@ _dotfile_abs_dst @@}}/functions/__ginshio_copy-graphisc-testcases.fish
    source {{@@ _dotfile_abs_dst @@}}/functions/__ginshio_set-git-urls.fish
    source {{@@ _dotfile_abs_dst @@}}/functions/__ginshio_zswap-statistics.fish
end
