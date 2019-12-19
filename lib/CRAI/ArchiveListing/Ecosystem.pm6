#| List all archives on GitHub
#| as pointed to by I«projects.json».
unit class CRAI::ArchiveListing::Ecosystem;

use CRAI::ArchiveListing;
use CRAI::ArchiveListing::Aggregate;
use CRAI::ArchiveListing::GitHub;

also is CRAI::ArchiveListing;
also does CRAI::ArchiveListing::Aggregate;

#| The URL to the I«projects.json» file.
has $.projects-json-url;

multi method new(--> ::?CLASS:D)
{
    self.new(
        :projects-json-url<https://ecosystem-api.p6c.org/projects.json>,
    );
}

multi method new(Str:D :$projects-json-url --> ::?CLASS:D)
{
    self.bless(:$projects-json-url);
}

method archive-listings(::?CLASS:D: --> Seq:D)
{
    self!source-urls.map: { CRAI::ArchiveListing::GitHub.new(:url($_)) };
}

#| Retrieve all source URLs mentioned in I«projects.json».
method !source-urls(::?CLASS:D: --> Seq:D)
{
    my @curl := <curl --silent --show-error>;
    my @jq   := <jq --raw-output>;

    my $curl := run(@curl, $!projects-json-url, :out);
    my $jq   := run(@jq, q:to/JQ/, :in($curl.out), :out);
        map(."source-url" | strings) | join("\n")
        JQ

    $jq.out.lines;
}
