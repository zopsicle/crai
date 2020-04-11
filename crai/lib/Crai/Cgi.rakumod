unit module Crai::Cgi;

use Crai::Database;
use DBIish;

my sub MAIN(IO() :$database! --> Nil)
    is export
{
    my $dbh := DBIish.connect('SQLite', :$database);
    my $db  := Crai::Database.new(:$dbh);

    given %*ENV<REQUEST_URI> {
        when /^ '/archive/' (.+) $/ { serve-archive($db, $0) }
        default { serve-not-found }
    }
}

my sub serve-archive(Crai::Database:D $db, Str() $archive-url --> Nil)
{
    my %archive := $db.fetch-archive($archive-url);
    unless %archive { serve-not-found; return }

    print "Content-Type: text/html\r\n";
    print "\r\n";
    print %archive.gist;
}

my sub serve-not-found(--> Nil)
{
    print "Status: 404\r\n";
    print "Content-Type: text/html\r\n";
    print "\r\n";
    print "Not found.";
}
