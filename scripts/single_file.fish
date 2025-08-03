#!/usr/bin/env fish

# https://github.com/gildas-lormeau/SingleFile/blob/f550b1daf07efa86169c732dc4dc6f710d783e77/src/ui/pages/help.html#L26
# "template variables"

single-file --filename-template "{url-hostname} - {date-iso} - {page-title}.{filename-extension}" $argv[1]
