let
    pkgs = import ./nix/pkgs.nix {};
in
    pkgs.raku-nix.rakuPackage {
        name = "crai";
        src = pkgs.lib.cleanSource ./.;
        depends = [pkgs.raku-nix.Pod-To-HTML];
        postInstallPhase = ''
            wrapProgram $out/bin/crai \
                --prefix PATH : ${pkgs.curl}/bin \
                --prefix PATH : ${pkgs.git}/bin \
                --prefix PATH : ${pkgs.jq}/bin \
                --prefix PATH : ${pkgs.rsync}/bin

            (
                export PERL6LIB=$(< $out/PERL6LIB)
                for module in $(find lib -name '*.pm6'); do
                    html=$out/share/doc/''${module#lib/}
                    html=''${html%.pm6}.html
                    mkdir --parents $(dirname $html)
                    raku --doc=HTML "$module" > "$html"
                done
            )
        '';
    }
