unit module Crai::P6c;

use JSON::Fast;
use LibCurl::Easy;

my sub list-p6c-archives(|c)
    is export
{
    list-p6c-sources(|c).map: {
        when /‘github.com/’ (<:L+:N+[_-]>+) ‘/’ (<:L+:N+[_-]>+) / {
            |list-github-archives($0, $1);
        }
        default {
            ();
        }
    };
}

my sub list-p6c-sources(
    LibCurl::Easy:D $curl,
    Str() :$projects-url = 'https://ecosystem-api.p6c.org/projects.json',
)
    is export
{
    $curl.reset;
    $curl.setopt(URL => $projects-url, :followlocation);
    $curl.perform;

    my @metas := from-json($curl.content);
    @metas ==> map(-> %meta { %meta<source-url> // %meta<support><source> })
           ==> grep(*.defined);
}

my sub list-github-archives(Str() $owner, Str() $repo)
    is export
{
    # If a repository is private, Git will ask for a password.
    # By setting these environment variables, it fails instead.
    my %env := %(|%*ENV, GIT_ASKPASS => 'false', GIT_TERMINAL_PROMPT => '0');

    my $url := "https://github.com/$owner/$repo";
    my $git := run(
        'git', 'ls-remote',

        # Put HEAD last, so we can skip
        # it if it’s not the only one.
        '--sort', '-refname',

        # Get refs matching these patterns.
        "$url.git", 'HEAD', 'refs/tags/*',

        :%env,
        :out,
    );
    $git.out.lines
       ==> map  ({ .split(/\s+/) })
       ==> grep ({ !$++ || .[1] ne 'HEAD' })
       ==> grep ({ .[1] !~~ /'^{}'/ })  # Skip hashes of annotated tags.
       ==> map  ({ "$url/archive/{.[0]}.tar.gz#{.[1]}" })
}

=begin pod

=head1 NAME

Crai::P6c - Crawl p6c for archives

=head1 SYNOPSIS

    use Crai::P6c;
    use LibCurl::Easy;
    my $curl := LibCurl::Easy.new(timeout => 60);
    .say for list-p6c-archives($curl);

=head1 DESCRIPTION

B<p6c> lists the latest I<META6.json> of each distribution hosted on GitHub
and possibly other version control hosting sites.

=head2 list-p6c-archives($curl, :$projects-url)

List all archives from version control repositories pointed to from p6c.
The URL of each archive is returned.

If the repository has tags, the archive for each tag is listed.
Otherwise, the archive for HEAD is listed.

C<$curl> must be an instance of B<LibCurl::Curl>.
You may set your own options on this handle before calling this routine.
You are advised to use the same instance for multiple calls to this routine,
so libcurl can maintain a connection pool.

C<$projects-url>, if given, must be the URL of the p6c I<projects.json> file.

=head1 BUGS

Does not support Git repositories that require authentication.

The archive URL for a version is always constructed from the commit hash of
that version. This means that tags are first resolved to specific commits.
This is done so that the archive remains identical even if tags are rewritten.
Archive URLs do contain the tag name in the fragment, for convenience.

=end pod
