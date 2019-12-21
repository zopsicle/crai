unit module CRAI::Main;

use CRAI::ArchiveListing::CPAN;
use CRAI::ArchiveListing::Ecosystem;
use CRAI::Database;

multi MAIN(‘retrieve-archive-list’, Str:D $from, IO() :$database-path! --> Nil)
    is export
{
    my $archive-listing := do given $from {
        when ‘cpan’      { CRAI::ArchiveListing::CPAN.new      }
        when ‘ecosystem’ { CRAI::ArchiveListing::Ecosystem.new }
        default { die “Unknown archive listing: $from” }
    };
    my $database := CRAI::Database.open($database-path);
    $database.ensure-archive($_) for $archive-listing.archives;
}

multi MAIN(‘retrieve-archives’, IO() :$database-path! --> Nil)
    is export
{
    !!!
}

multi MAIN(‘compute-archive-hashes’, IO() :$database-path! --> Nil)
    is export
{
    !!!
}

multi MAIN(‘extract-metadata’, IO() :$database-path! --> Nil)
    is export
{
    !!!
}
