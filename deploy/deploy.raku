my sub MAIN(IO() :$production!, IO() :$terraform! --> Nil)
    is export
{
    run(<terraform init>, $terraform);
    run(<terraform apply>, $terraform);
    my $host := run(<terraform output hcloud_crai_ipv4>, :out).out.slurp.chomp;

    my @closure = run(<nix-store --query --requisites>,
                      $production, :out).out.lines;

    run(<rsync --archive --compress --ignore-existing --relative --verbose>,
        @closure, "root@$host:/");

    my $ssh := run(<ssh -T>, "root@$host", 'bash', :in);
    {
        $ssh.in.put: "if ! id crai; then useradd crai; fi";
        $ssh.in.put: "mkdir --parents /home/crai";
        $ssh.in.put: "chown crai:crai /home/crai";

        $ssh.in.put: "mkdir --parents /var/lib/crai/crai.mirror";
        $ssh.in.put: "chown crai:crai /var/lib/crai";
        $ssh.in.put: "chown crai:crai /var/lib/crai/crai.mirror";

        my %units := {
            'crai-cgi.service'  => { :enable, :restart },
            'crai-cron.timer'   => { :enable, :restart },
            'crai-cron.service' => {},
        };
        for %units.keys {
            $ssh.in.put: "ln --force --symbolic " ~
                         "$production/etc/$_ /etc/systemd/system/$_";
        }
        $ssh.in.put: "systemctl daemon-reload";
        for %units.kv -> $unit, %flags {
            $ssh.in.put: "systemctl enable  $unit" if %flags<enable>;
            $ssh.in.put: "systemctl restart $unit" if %flags<restart>;
        }
    }
    $ssh.in.close;
    $ssh.sink;
}
