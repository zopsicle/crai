{ perl, raku, rakudo, sqlite }:
raku.rakuPackage {
    name = "crai";
    src = ./.;
    depends = [ raku.DBIish ];
    postInstallPhase = ''
        makeWrapper ${perl}/bin/prove $out/bin/crai.prove       \
            --set PERL6LIB "$(< $out/PERL6LIB)"                 \
            --set LD_LIBRARY_PATH ${sqlite.out}/lib             \
            --add-flags --exec                                  \
            --add-flags ${rakudo}/bin/raku
    '';
}
