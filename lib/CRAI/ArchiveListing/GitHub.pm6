=begin pod

=head1 NAME

CRAI::ArchiveListing::GitHub - List all archives in a GitHub repository

=head1 SYNOPSIS

=begin code
# Construction
my $url     := ‘https://github.com/chloekek/crai.git’;
my $listing := CRAI::ArchiveListing::GitHub.new(:$url);

# Or
my ($owner, $repository) := <chloekek crai>;
my $listing := CRAI::ArchiveListing::GitHub.new(:$owner, :$repository);

# Query the object
say $listing.owner;       # OUTPUT: «chloekek␤»
say $listing.repository;  # OUTPUT: «crai␤»
say $listing.git-url;     # OUTPUT: «git://github.com/chloekek/crai.git␤»

# List all archives
my @archives = $listing.archives;
.say for @archives;
=end code

=head1 DESCRIPTION

List all archives in the GitHub repository.
This collection of archives is determined by the following algorithm:

=begin item
If the GitHub repository has any tags,
the archives are checkouts of those tags.
=end item

=begin item
If the GitHub repository has no tags,
the archive is the checkout of HEAD.
=end item

Archive URLs are always derived from I«commit hashes», never from refs.
This ensures they are stable across ref rewrites.

=head2 .new(:$url)

Create a new instance from a GitHub URL.
This may be in various formats, as long as it contains the substring
C<github.com/«owner»/«repository»>.

=head2 .new(:$owner, :$repository)

Create a new instance from
a GitHub username or organization name (I<the owner>) and
a GitHub repository name.

=head2 .git-url

Return the Git remote URL for the GitHub repository.
This can be passed to Git commands that expect a Git remote URL,
such as C«git clone» and C«git ls-remote».

This is not necessarily the URL passed to C«new».
It is in a normalized format and does not contain credentials.

Example:

=begin code
my $url     := ‘https://github.com/chloekek/crai.git’;
my $listing := CRAI::ArchiveListing::GitHub.new(:$url);
say $listing.git-url; # OUTPUT: «git://github.com/chloekek/crai.git␤»
=end code

=head2 .archives

Return the URL for each archive,
according to the algorithm above.

=head1 BUGS

This class does no authentication by itself.
It relies on the user’s Git configuration when accessing private repositories.

=end pod

unit class CRAI::ArchiveListing::GitHub;

use CRAI::ArchiveListing;

also is CRAI::ArchiveListing;

has Str $.owner;
has Str $.repository;

multi method new(Str:D :$url --> ::?CLASS:D)
{
    unless $url ~~ /‘github.com/’ (<:L+:N+[_-]>+) ‘/’ (<:L+:N+[_-]>+) / {
        die CRAI::ArchiveListing::GitHub::X::URL.new(:$url);
    }
    self.new(owner => ~$0, repository => ~$1);
}

multi method new(Str:D :$owner, Str:D :$repository --> ::?CLASS:D)
{
    self.bless(:$owner, :$repository);
}

method git-url(::?CLASS:D: --> Str:D)
{
    “git://github.com/$!owner/$!repository.git”;
}

method archives(::?CLASS:D: --> Seq:D)
{
    my $commit-hashes := self!ls-remote;
    $commit-hashes.map({ self!archive-url($_) });
}

method !ls-remote(::?CLASS:D: --> Seq:D)
{
    # TODO: Throw Git errors.

    my @git := «git ls-remote --sort -refname “{$.git-url}” HEAD refs/tags/*»;
    my $git := run(@git, :out);

    $git.out.lines
    ==> map     *.split(“\t”)
    ==> grep    ({ !$++ || .[1] ne ‘HEAD’ })
    ==> map     *[0]
}

method !archive-url(::?CLASS:D: Str:D $commit --> Str:D)
{
    “https://github.com/$!owner/$!repository/archives/$commit.tar.gz”;
}
