{ crai, hivemind, lighttpd, makeWrapper, rakudo, stdenvNoCC }:
stdenvNoCC.mkDerivation {
    name = "crai-development";

    src = ./.;
    buildInputs = [ makeWrapper rakudo ];
    inherit crai hivemind lighttpd;

    database_path = "/tmp/crai.sqlite3";

    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
        mkdir --parents $out/bin $out/etc $out/www/cgi-bin

        makeWrapper $hivemind/bin/hivemind $out/bin/crai.development    \
            --add-flags --root                                          \
            --add-flags .                                               \
            --add-flags $out/etc/Procfile

        makeWrapper $crai/bin/crai.cgi $out/www/cgi-bin/crai.cgi        \
            --add-flags --database=$database_path

        raku template.raku                                              \
            document-root=$out/www                                      \
            < lighttpd.conf                                             \
            > $out/etc/lighttpd.conf

        raku template.raku                                              \
            lighttpd=$lighttpd/bin/lighttpd                             \
            lighttpd.conf=$out/etc/lighttpd.conf                        \
            < Procfile                                                  \
            > $out/etc/Procfile
    '';
}
