unit module Crai::Web::Psgi;

use Crai::Database;
use Crai::Web::Archive;
use Crai::Web::Error;
use Crai::Web::Home;
use Crai::Web::Layout;
use Crai::Web::Search;
use DBIish;
use URI::Escape;

my sub serve-psgi(%env, IO() :$database!)
    is export
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

=begin pod

=head1 NAME

Crai::Web::Psgi - PSGI application

=head1 SYNOPSIS

    use Crai::Web::Psgi;
    my $database := '/tmp/crai.sqlite3';
    my &app := { serve-psgi(%^env, $database) };

=head1 DESCRIPTION

Subroutine taking a PSGI environment and returning a PSGI response triplet.

=end pod
