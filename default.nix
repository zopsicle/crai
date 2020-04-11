{ pkgs ? import ./nix/pkgs.nix {} }:
rec {
    crai = pkgs.callPackage ./crai {};
    development = pkgs.callPackage ./development { inherit crai; };
}
