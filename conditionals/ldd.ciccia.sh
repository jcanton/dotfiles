#!/bin/sh
# DSM ships no ldd, and Mason needs it to tell glibc from musl; the dynamic
# loader does the same job.
loader=/lib64/ld-linux-x86-64.so.2
case $1 in
--version) exec "$loader" --version ;;
*) exec "$loader" --list "$@" ;;
esac
