#| List all archives on CPAN
#| except for those of the PSIXDISTS project.
unit class CRAI::ArchiveListing::CPAN;

use CRAI::ArchiveListing;

also is CRAI::ArchiveListing;

#| The rsync URL is used to find the archives on CPAN.
has $.rsync-url;

#| The HTTP URL is used to construct the archive URLs.
has $.http-url;

#| Use the URLs for the official CPAN instance.
multi method new(--> ::?CLASS:D)
{
    self.new(
        :rsync-url<rsync://cpan-rsync.perl.org/CPAN>,
        :http-url<https://www.cpan.org>,
    );
}

#| Construct with the given CPAN URLs.
#| See the documentation on the homonymous attributes.
multi method new(Str:D :$rsync-url, Str:D :$http-url --> ::?CLASS:D)
{
    self.bless(:$rsync-url, :$http-url);
}

method archives(::?CLASS:D: --> Seq:D)
{
    my @rsync-command := self!rsync-command;
    my $proc := run(@rsync-command, :out);
    self!process-output($proc.out);
}

method !rsync-command(::?CLASS:D: --> List:D)
{
    my @rsync-flags := <--dry-run --verbose --prune-empty-dirs --recursive>;
    my @rsync-includes := ‘*/’, |@archive-file-extensions.map({ “/id/*/*/*/Perl6/*$_” });
    my @rsync-excludes := ‘*’,;
    return (
        ‘rsync’,
        |@rsync-flags,
        |@rsync-includes.map({ “--include=$_” }),
        |@rsync-excludes.map({ “--exclude=$_” }),
        “$!rsync-url/authors/id”,
    );
}

method !process-output(::?CLASS:D: IO::Handle:D $_ --> Seq:D)
{
    .lines
    ==> grep    *.ends-with(any(@archive-file-extensions))
    ==> map     *.split(/\s+/)[4]
    ==> grep    !*.starts-with(‘id/P/PS/PSIXDISTS/’)
    ==> map     “$!http-url/authors/” ~ *
}
