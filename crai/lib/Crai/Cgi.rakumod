unit module Crai::Cgi;

use Crai::Database;
use DBIish;

my sub MAIN(IO() :$database!)
    is export
{
    my $dbh := DBIish.connect('SQLite', :$database);
    my $db  := Crai::Database.new(:$dbh);

    print "Content-Type: text/plain\r\n";
    print "\r\n";
    print %*ENV<REQUEST_URI>;
}
