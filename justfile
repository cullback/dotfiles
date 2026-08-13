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

# Normalise /vault/photo perms so the immich service user (group `users`) can
# read/write. macOS-sourced copies land as 0600, which is invisible to immich.
photo-perms:
    find /vault/photo -type d -exec chmod 2775 {} +
    find /vault/photo -type f -exec chmod 664 {} +

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
