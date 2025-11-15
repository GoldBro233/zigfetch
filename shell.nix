{ pkgs ? import <nixpkgs> {} }:

let
  unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  }) {};
in
pkgs.mkShell {
  buildInputs = [
    unstable.zig
    pkgs.pciutils
  ];
}
