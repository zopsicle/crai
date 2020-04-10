let
    tarball = fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/d6fa6426088f377dca81af1526c0154789850bc7.tar.gz";
        sha256 = "1bjn2wzzzv9v0z50z4mczy7c3ww3vixmsxrn4q44nza32fwcy87m";
    };
    config = {
        php = import ./php.nix;
        packageOverrides = pkgs: {
            raku = pkgs.callPackage ./raku.nix {};
        };
    };
in
    {}: import tarball { inherit config; }
