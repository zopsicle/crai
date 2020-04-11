unit module Crai::Cron;

use Crai::Archive;
use Crai::Cpan;
use Crai::Database;
use Crai::Mirror;
use DBIish;
use JSON::Fast;
use LibCurl::Easy;

my sub MAIN(
    IO() :$database!,
    IO() :$mirror!,
    Bool :$skip-list-cpan-archives,
    Bool :$skip-download-archives,
    Bool :$skip-extract-meta,
    --> Nil
)
    is export
{
    my $curl := LibCurl::Easy.new(timeout => 60);
    my $dbh  := DBIish.connect('SQLite', :$database);
    my $db   := Crai::Database.new(:$dbh);

    unless $skip-list-cpan-archives {
        $db.insert-archive($_) for list-cpan-archives;
    }

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

    unless $skip-extract-meta {
        for $db.fetch-archive-urls -> $archive-url {
            my $archive-path := archive-path($mirror, $archive-url);
            next unless $archive-path.s;
            try {
                my $meta := read-meta($archive-path);
                my %meta := from-json($meta);
                say %meta;
            }
        }
    }
}
