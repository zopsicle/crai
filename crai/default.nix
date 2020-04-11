{ curl, lib, libressl, perl, raku, rakudo, sqlite }:
let
    meta6 = builtins.fromJSON (builtins.readFile ./META6.json);
    get-depend = p: raku."${builtins.replaceStrings ["::"] ["-"] p}";
in
    raku.rakuPackage {
        name = "crai";
        src = ./.;
        depends = map get-depend meta6.depends;
        preInstallPhase = ''
            export LD_LIBRARY_PATH=${lib.makeLibraryPath [ curl libressl sqlite ]}
        '';
        postInstallPhase = ''
            makeWrapper ${perl}/bin/prove $out/bin/crai.prove       \
                --set PERL6LIB "$(< $out/PERL6LIB)"                 \
                --set LD_LIBRARY_PATH $LD_LIBRARY_PATH              \
                --add-flags --exec                                  \
                --add-flags ${rakudo}/bin/raku

            wrapProgram $out/bin/crai.cron                          \
                --set LD_LIBRARY_PATH $LD_LIBRARY_PATH

            wrapProgram $out/bin/crai.cron.profile                  \
                --set LD_LIBRARY_PATH $LD_LIBRARY_PATH
        '';
    }
