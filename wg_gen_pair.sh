#!/bin/sh
# Generate a WireGuard keypair and print it to stdout.
# Keys stay out of shell history since nothing is passed on the command line.
set -eu

private_key=$(wg genkey)
public_key=$(printf '%s' "$private_key" | wg pubkey)

printf 'private: %s\n' "$private_key"
printf 'public:  %s\n' "$public_key"
