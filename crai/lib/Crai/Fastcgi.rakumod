unit module Crai::Fastcgi;

use Crai::Database;
use Crai::Web::Archive;
use Crai::Web::Error;
use Crai::Web::Home;
use Crai::Web::Layout;
use Crai::Web::Search;
use DBIish;
use FastCGI::NativeCall;
use URI::Escape;

my sub MAIN(:$fastcgi-socket!, :$database! --> Nil)
    is export
{
    my $fcgi := FastCGI::NativeCall.new(path => $fastcgi-socket);
    while $fcgi.accept() {
        my ($status, $headers, $body) := serve($fcgi.env, $database);
        $fcgi.Print("Status: $status\r\n");
        $fcgi.Print("{.key}: {.value}\r\n") for $headers.pairs;
        $fcgi.Print("\r\n");
        $fcgi.Print($_) for $body[];
    }
}

my sub serve(%env, IO() $database)
{
    my $dbh := DBIish.connect('SQLite', :$database);
    my $db  := Crai::Database.new(:$dbh);

    given %env<REQUEST_URI> {
        when /^ '/' $/ { serve-home($db) }
        when /^ '/archive/' (.+) $/ { serve-archive($db, uri-unescape($0)) }
        when /^ '/search?q=' (.*) $/ { serve-search($db, uri-unescape($0)) }
        default { respond-error(404) }
    }
}

my sub serve-home(Crai::Database:D $db)
{
    my $statistic := $db.fetch-archive-count;
    respond-home($statistic);
}

my sub serve-archive(Crai::Database:D $db, Str() $archive-url)
{
    my %archive := $db.fetch-archive($archive-url);
    unless %archive { respond-error(404); return }
    respond-archive(%archive);
}

my sub serve-search(Crai::Database:D $db, Str() $query)
{
    my @archives = $db.search-archives($query);
    respond-search($query, @archives);
}
