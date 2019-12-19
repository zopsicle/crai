unit module CRAI::Main;

use CRAI::ArchiveListing::CPAN;

sub MAIN
    is export
{
    my $cpan := CRAI::ArchiveListing::CPAN.new;
    .say for $cpan.archives;
}
