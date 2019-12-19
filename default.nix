let
    pkgs = import ./nix/pkgs.nix {};
in
    pkgs.raku-nix.rakuPackage {
        name = "crai";
        src = pkgs.lib.cleanSource ./.;
        postInstallPhase = ''
            wrapProgram $out/bin/crai \
                --prefix PATH : ${pkgs.curl}/bin \
                --prefix PATH : ${pkgs.git}/bin \
                --prefix PATH : ${pkgs.jq}/bin \
                --prefix PATH : ${pkgs.rsync}/bin
        '';
    }
