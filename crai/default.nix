{ curl, lib, libressl, perl, raku, rakudo, sassc, sqlite }:
let
    meta6 = builtins.fromJSON (builtins.readFile ./META6.json);
    get-depend = p: raku."${builtins.replaceStrings ["::"] ["-"] p}";
in
    raku.rakuPackage {
        name = "crai";
        src = ./.;
        buildInputs = [ sassc ];
        depends = map get-depend meta6.depends;
        preInstallPhase = ''
            export LD_LIBRARY_PATH=${lib.makeLibraryPath [ curl libressl sqlite ]}
        '';
        postInstallPhase = ''
            makeWrapper ${perl}/bin/prove $out/bin/crai-prove       \
                --set PERL6LIB "$(< $out/PERL6LIB)"                 \
                --set LD_LIBRARY_PATH $LD_LIBRARY_PATH              \
                --add-flags --exec                                  \
                --add-flags ${rakudo}/bin/raku

            for p in $out/bin/crai-{cgi,cron}{,.profile}; do
                wrapProgram $p                                      \
                    --set LD_LIBRARY_PATH $LD_LIBRARY_PATH
            done

            mkdir --parents $out
            mv static $out
        '';
    }
