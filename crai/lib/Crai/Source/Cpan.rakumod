unit module Crai::Source::Cpan;

my constant @whitelist := <.tar .tar.gz .tgz>;
my constant @blacklist := 'id/P/PS/PSIXDISTS';

my sub list-cpan-archives(
    Str() :$rsync-url = 'rsync://cpan-rsync.perl.org/CPAN',
    Str() :$http-url  = 'https://www.cpan.org',
)
    is export
{
    use fatal;
    my @rsync-flags    := <--dry-run --verbose --prune-empty-dirs --recursive>;
    my @rsync-includes := '*/', |@whitelist.map('/id/*/*/*/Perl6/*' ~ *);
    my @rsync-excludes := '*',;
    my @rsync-command  := (
        'rsync',
        |@rsync-flags,
        |@rsync-includes.map('--include=' ~ *),
        |@rsync-excludes.map('--exclude=' ~ *),
        "$rsync-url/authors/id",
    );
    run(@rsync-command, :out).out.lines
        ==> grep *.ends-with(any(@whitelist))
        ==> map  *.split(/\s+/)[4]
        ==> grep !*.starts-with(any(@blacklist))
        ==> map  "$http-url/authors/" ~ *;
}

=begin pod

=head1 NAME

Crai::Source::Cpan - Crawl CPAN for archives

=head1 SYNOPSIS

    use Crai::Source::Cpan;
    .say for list-cpan-archives;

=head1 DESCRIPTION

The B<Comprehensive Perl Archive Network> is one place to host Raku modules.
CPAN exposes the modules as versioned archives.

=head2 list-cpan-archives(:$rsync-url, :$http-url)

Using rsync, retrieve a list of Raku archives on CPAN.
The URL of each archive is returned.

The optional arguments C<$rsync-url> and C<$http-url> may be given to customize
the CPAN mirror. By default, the main mirror is used.

=head1 BUGS

Archives belonging to the PSIXDISTS project are ignored.
There are many such archives, and they are long obsolete.

=end pod
