unit module Crai::App::Cron;

use Crai::Archive;
use Crai::Database;
use Crai::Mirror;
use Crai::Source::Cpan;
use Crai::Source::P6c;
use DBIish;
use JSON::Fast;
use LibCurl::Easy;

my sub MAIN(
    IO() :$database!,
    IO() :$mirror!,
    Bool :$skip-list-cpan-archives,
    Bool :$skip-list-p6c-archives,
    Bool :$skip-download-archives,
    Bool :$skip-compute-hashes,
    Bool :$skip-extract-meta,
    --> Nil
)
    is export
{
    $*OUT.out-buffer = 0;

    my $when := DateTime.now;
    my $curl := LibCurl::Easy.new(timeout => 60);
    my $dbh  := DBIish.connect('SQLite', :$database);
    my $db   := Crai::Database.new(:$dbh);

    $db.insert-run($when);

    unless $skip-list-cpan-archives {
        for list-cpan-archives() {
            put($_);
            $db.insert-encounter($when, $_);
            $db.insert-archive($_);
        }
    }

    unless $skip-list-p6c-archives {
        for list-p6c-archives($curl) {
            put($_);
            $db.insert-encounter($when, $_);
            $db.insert-archive($_);
        }
    }

    $db.finish-run($when, DateTime.now);

    unless $skip-download-archives {
        for ^∞ Z $db.fetch-archive-urls -> ($i, $archive-url) {
            sub noflood { sleep(1) if $i %% 10 }
            print("$archive-url ");
            given download-archive($curl, $mirror, $archive-url) {
                when Exception { put("! $_"); noflood }
                when IO::Path  { put("→ $_"); noflood }
                when :present  { put("✔️") }
            }
        }
    }

    unless $skip-compute-hashes {
        for $db.fetch-archive-urls -> $archive-url {
            print("$archive-url ");
            given compute-hashes($mirror, $archive-url) {
                when Exception {
                    put("! $_");
                }
                when List {
                    my %hashes = <hash-md5 hash-sha1 hash-sha256> Z=> $_;
                    $db.update-archive-hashes($archive-url, |%hashes);
                    put("✔");
                }
            }
        }
    }

    unless $skip-extract-meta {
        for $db.fetch-archive-urls -> $archive-url {
            my $archive-path := archive-path($mirror, $archive-url);
            next unless $archive-path.s;
            print("$archive-url ");
            try {
                my $meta := read-meta($archive-path);
                my %meta := from-json($meta);
                my %norm := normalize-meta(%meta);
                $db.update-archive-meta($archive-url, |%norm);
            }
            with    $! { put("! $_") }
            without $! { put("✔") }
        }
    }
}
