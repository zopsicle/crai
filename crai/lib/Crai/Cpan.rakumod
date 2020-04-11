unit module Crai::Cpan;

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
