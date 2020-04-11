unit module Crai::Cron;

use Crai::Cpan;
use Crai::Database;
use DBIish;

my sub MAIN(IO() :$database! --> Nil)
    is export
{
    my $dbh := DBIish.connect('SQLite', :$database);
    my $db  := Crai::Database.new(:$dbh);
    $db.insert-archive($_) for list-cpan-archives;
}
