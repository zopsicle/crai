{ pkgs ? import ./nix/pkgs.nix {} }:
rec {
    crai = pkgs.callPackage ./crai {};
    deploy = pkgs.callPackage ./deploy { inherit (sysadmin) production; };
    sysadmin = pkgs.callPackage ./sysadmin { inherit crai; };
}
