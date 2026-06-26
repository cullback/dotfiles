#!/usr/bin/env fish

ip addr show enp0s1 | rg 'inet ([\d\.]+)' -o --replace '$1'
