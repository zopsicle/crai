{ pkgs ? import ./nix/pkgs.nix {} }:
rec {
    crai = pkgs.callPackage ./crai {};
    sysadmin = pkgs.callPackage ./sysadmin { inherit crai; };
}
