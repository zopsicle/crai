{ crai, hivemind, lighttpd, makeWrapper, rakudo, stdenvNoCC }:
let
    common =
        { database, mirror, server_port }:
        stdenvNoCC.mkDerivation {
            name = "crai-sysadmin";

            src = ./.;
            buildInputs = [ makeWrapper rakudo ];
            inherit crai hivemind lighttpd;

            inherit database mirror server_port;

            phases = [ "unpackPhase" "installPhase" ];
            installPhase = ''
                mkdir --parents $out/bin $out/etc $out/www/cgi-bin

                # www/static
                ln --symbolic $crai/static $out/www/static

                # etc/Procfile
                makeWrapper $hivemind/bin/hivemind $out/bin/crai.development    \
                    --add-flags --root                                          \
                    --add-flags .                                               \
                    --add-flags $out/etc/Procfile

                # bin/crai-cgi
                makeWrapper $crai/bin/crai-cgi $out/www/cgi-bin/crai-cgi        \
                    --add-flags --database=$database

                # etc/lighttpd.conf
                raku template.raku                                              \
                    server-document-root=$out/www                               \
                    server-port=$server_port                                    \
                    < lighttpd.conf                                             \
                    > $out/etc/lighttpd.conf

                # etc/crai-cgi.service
                raku template.raku                                              \
                    lighttpd=$lighttpd/bin/lighttpd                             \
                    lighttpd.conf=$out/etc/lighttpd.conf                        \
                    < crai-cgi.service                                          \
                    > $out/etc/crai-cgi.service

                # etc/crai-cron.timer
                cp crai-cron.timer $out/etc/crai-cron.timer

                # etc/crai-cron.service
                raku template.raku                                              \
                    database=$database                                          \
                    mirror=$mirror                                              \
                    < crai-cron.service                                         \
                    > $out/etc/crai-cron.service

                # etc/Procfile
                raku template.raku                                              \
                    lighttpd=$lighttpd/bin/lighttpd                             \
                    lighttpd.conf=$out/etc/lighttpd.conf                        \
                    < Procfile                                                  \
                    > $out/etc/Procfile
            '';
        };
in
    {
        development = common {
            database    = "/tmp/crai.sqlite3";
            mirror      = "/tmp/crai.mirror";
            server_port = 8080;
        };
        production = common {
            database    = "/var/lib/crai/crai.sqlite3";
            mirror      = "/var/lib/crai/crai.mirror";
            server_port = 80;
        };
    }
