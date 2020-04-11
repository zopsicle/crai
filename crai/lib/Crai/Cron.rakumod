unit module Crai::Cron;

use Crai::Cpan;
use Crai::Database;
use Crai::Mirror;
use DBIish;
use LibCurl::Easy;

my sub MAIN(
    IO() :$database!,
    IO() :$mirror!,
    Bool :$skip-list-cpan-archives,
    Bool :$skip-download-archives,
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
}
