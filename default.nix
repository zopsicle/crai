{ pkgs ? import ./nix/pkgs.nix {} }:
rec {
    crai = pkgs.callPackage ./crai {};
}
