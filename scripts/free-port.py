#!/usr/bin/env python3
"""Print a free port for a dev server.

A port is chosen when the server starts and belongs to nobody once it stops,
so no worktree holds one it is not using. PORT in the environment, or the
first argument, is a preference: it is used when nothing is bound to it, so a
main checkout can keep the number people have bookmarked. Otherwise the lowest
free port in the band.

Free means a loopback bind succeeds. tailscaled holds every served port on the
tailnet address as well, and that is the proxy in front of a server, not a
server.

The band is FREE_PORT_BAND as "lo-hi", default 3000-3050. It stops at 3050
because every port in it needs its own `tailscale serve` mapping.
"""

import os
import socket
import sys


def free(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        try:
            sock.bind(("127.0.0.1", port))
        except OSError:
            return False
    return True


def main() -> None:
    band = os.environ.get("FREE_PORT_BAND", "3000-3050")
    try:
        low, high = (int(part) for part in band.split("-"))
    except ValueError:
        sys.exit(f"free-port: FREE_PORT_BAND must look like 3000-3050, not {band!r}")

    preferred = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("PORT")
    if preferred:
        try:
            port = int(preferred)
        except ValueError:
            sys.exit(f"free-port: {preferred!r} is not a port number")
        if free(port):
            print(port)
            return
        print(f"free-port: {port} is taken, picking another", file=sys.stderr)

    for port in range(low, high + 1):
        if free(port):
            print(port)
            return
    sys.exit(f"free-port: nothing free in {low}-{high}")


if __name__ == "__main__":
    main()
