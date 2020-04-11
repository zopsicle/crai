{ pkgs ? import ./nix/pkgs.nix {} }:
rec {
    crai = pkgs.callPackage ./crai {};
    craw = pkgs.callPackage ./craw {};
    development = pkgs.callPackage ./development { inherit crai; };
}
