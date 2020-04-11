unit module Crai::Cgi;

use Crai::Database;
use Crai::Web::Archive;
use Crai::Web::Error;
use Crai::Web::Home;
use Crai::Web::Layout;
use DBIish;

my sub MAIN(IO() :$database! --> Nil)
    is export
{
    my $dbh := DBIish.connect('SQLite', :$database);
    my $db  := Crai::Database.new(:$dbh);

    given %*ENV<REQUEST_URI> {
        when /^ '/' $/ { serve-home($db) }
        when /^ '/archive/' (.+) $/ { serve-archive($db, $0) }
        default { respond-error(404) }
    }
}

my sub serve-home(Crai::Database:D $db --> Nil)
{
    my $statistic := $db.fetch-archive-count;
    respond-home($statistic);
}

my sub serve-archive(Crai::Database:D $db, Str() $archive-url --> Nil)
{
    my %archive := $db.fetch-archive($archive-url);
    unless %archive { respond-error(404); return }
    respond-archive(%archive);
}
