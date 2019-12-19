unit module CRAI::Main;

use CRAI::ArchiveListing::CPAN;
use CRAI::ArchiveListing::Ecosystem;

sub MAIN(‘list-archives’, Str:D $from --> Nil)
    is export
{
    my $archive-listing := do given $from {
        when ‘cpan’      { CRAI::ArchiveListing::CPAN.new      }
        when ‘ecosystem’ { CRAI::ArchiveListing::Ecosystem.new }
        default { die “Unknown archive listing: $from” }
    };
    .say for $archive-listing.archives;
}
