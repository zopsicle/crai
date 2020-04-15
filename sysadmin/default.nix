{ caddy, crai, hivemind, makeWrapper, rakudo, stdenvNoCC }:
let
    common =
        { database, mirror, fastcgi_socket, http_url }:
        stdenvNoCC.mkDerivation {
            name = "crai-sysadmin";

            src = ./.;
            buildInputs = [ makeWrapper rakudo ];
            inherit caddy crai hivemind;

            inherit database mirror fastcgi_socket http_url;

            phases = [ "unpackPhase" "installPhase" ];
            installPhase = ''
                mkdir --parents $out/bin $out/etc

                # bin/crai.development
                makeWrapper $hivemind/bin/hivemind $out/bin/crai.development    \
                    --add-flags --root                                          \
                    --add-flags .                                               \
                    --add-flags $out/etc/Procfile

                # etc/Caddyfile
                raku template.raku                                              \
                    fastcgi-socket=$fastcgi_socket                              \
                    static=$crai/static                                         \
                    http-url=$http_url                                          \
                    < Caddyfile                                                 \
                    > $out/etc/Caddyfile

                # etc/caddy.service
                raku template.raku                                              \
                    Caddyfile=$out/etc/Caddyfile                                \
                    caddy=$caddy/bin/caddy                                      \
                    < caddy.service                                             \
                    > $out/etc/caddy.service

                # etc/crai-cron.timer
                cp crai-cron.timer $out/etc/crai-cron.timer

                # etc/crai-cron.service
                raku template.raku                                              \
                    crai-cron=$crai/bin/crai-cron                               \
                    database=$database                                          \
                    mirror=$mirror                                              \
                    < crai-cron.service                                         \
                    > $out/etc/crai-cron.service

                # etc/crai-fastcgi.service
                raku template.raku                                              \
                    crai-fastcgi=$crai/bin/crai-fastcgi                         \
                    database=$database                                          \
                    fastcgi-socket=$fastcgi_socket                              \
                    < crai-fastcgi.service                                      \
                    > $out/etc/crai-fastcgi.service

                # etc/Procfile
                raku template.raku                                              \
                    Caddyfile=$out/etc/Caddyfile                                \
                    caddy=$caddy/bin/caddy                                      \
                    crai-fastcgi=$crai/bin/crai-fastcgi                         \
                    database=$database                                          \
                    fastcgi-socket=$fastcgi_socket                              \
                    < Procfile                                                  \
                    > $out/etc/Procfile
            '';
        };
in
    {
        development = common {
            database       = "/tmp/crai.sqlite3";
            mirror         = "/tmp/crai.mirror";
            fastcgi_socket = "/tmp/crai.fastcgi";
            http_url       = "http://127.0.0.1:8080";
        };
        production = common {
            database       = "/var/lib/crai/crai.sqlite3";
            mirror         = "/var/lib/crai/crai.mirror";
            fastcgi_socket = "/var/run/crai/crai.fastcgi";
            http_url       = "https://crai.foldr.nl";
        };
    }
