# Display available recipes
default:
    just --list --unsorted

alias fmt := format

nix-rebuild:
    sudo nixos-rebuild switch --flake ./hosts#$(hostname)

# Bump flake inputs (all, or named ones e.g. `just update nixpkgs-unstable`) and rebuild
update *inputs:
    nix flake update {{ inputs }} --flake ./hosts
    just nix-rebuild

sync-dotfiles:
    bash scripts/install.bash

check:
    #!/usr/bin/env fish
    set status_flag 0
    dprint check --config dprint/dprint.json; or set status_flag 1
    if command -q nixfmt
        fd -e nix | xargs -r nixfmt --check; or set status_flag 1
    else
        echo "⚠️  nixfmt not found, skipping nix format check"
    end
    fd -e fish | xargs -r fish_indent --check; or set status_flag 1
    exit $status_flag

format:
    dprint fmt --config dprint/dprint.json
    command -v nixfmt >/dev/null && fd -e nix | xargs -r nixfmt || echo "⚠️  nixfmt not found, skipping nix format"
    fd -e fish | xargs -r fish_indent -w
    just --unstable --fmt

# Normalise perms on the non-Immich side of /vault/photo (inbox/, archive/) so the
# files stay group-readable/writable for the `users` group. macOS-sourced copies land
# as 0600, which makes them unreadable to anything but the copying user — and would
# be invisible to Immich if an external library were ever pointed at them.
#
# Skips immich/ — that store is immich:immich 0750/0640 by design (see immich.nix,
# GROUP-READABLE STORE). Applying 2775/664 there would make every personal photo
# world-readable and group-writable, and the chmods would fail anyway since the files
# aren't ours.
photo-perms:
    find /vault/photo -path /vault/photo/immich -prune -o -type d -exec chmod 2775 {} +
    find /vault/photo -path /vault/photo/immich -prune -o -type f -exec chmod 664 {} +

# One-time backfill after switching immich.nix to a group-readable store. The UMask
# change only affects files written from then on; everything already imported stays
# 0600/0700 until this runs. Safe to re-run — g+rX never removes access.
# NOTE: no backticks anywhere below. just treats backticks in a recipe line as command
# substitution and runs them, so a message mentioning "newgrp immich" in backticks
# actually EXECUTES newgrp, which spawns an interactive shell and hangs the recipe
# forever. Cost an unexplained 11-minute stall the first time. Use plain quotes.
immich-perms-backfill:
    sudo chmod -R g+rX /vault/photo/immich
    @stat -c '%A %U:%G %n' /vault/photo/immich
    @echo 'Done. Your shell keeps its old groups until you log out and back in;'
    @echo 'until then, read the store with:  sg immich -c "ls /vault/photo/immich"'

# Snapshot before an Immich upgrade. Migrations are sequential and don't always
# tolerate skipped versions — tracking unstable means a flake bump can cross several
# releases at once.
#
# To recover, restore FILES from the snapshot; do NOT `zfs rollback`. The snapshot
# covers all of /vault/photo, so a rollback would also revert every photo added since
# it was taken. The DB is what breaks on a bad upgrade, so restore just that:
#   ls /vault/photo/.zfs/snapshot/immich-pre-upgrade-<stamp>/immich/backups/
# then stop immich-server, restore the dump with pg_restore, and pin the flake back.
immich-preupgrade:
    sudo zfs snapshot frost/vault/photo@immich-pre-upgrade-$(date +%Y%m%d-%H%M%S)
    zfs list -t snapshot -o name,creation frost/vault/photo
