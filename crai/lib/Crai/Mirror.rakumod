unit module Crai::Mirror;

use LibCurl::Easy;
use OpenSSL::Digest;

my sub archive-path(IO() $mirror, Str() $archive-url)
    is export
{
    my $hash     := sha256($archive-url.encode);
    my $basename := $hash.list.map(*.fmt('%02x')).join;
    $mirror.add($basename);
}

my sub download-archive(LibCurl::Easy:D $curl, $mirror, $archive-url)
    is export
{
    my $archive-path := archive-path($mirror, $archive-url);
    return { :present } if $archive-path.s;
    try {
        $curl.setopt(
            URL      => $archive-url,
            download => ~$archive-path,
            :followlocation,
        );
        $curl.perform;
    }
    $! // $archive-path;
}

=begin pod

=head1 NAME

Crai::Mirror - Download archives and store them on disk

=head1 SYNOPSIS

    use Crai::Mirror;
    use LibCurl::Easy;

    my $curl        := LibCurl::Easy.new(timeout => 60);
    my $mirror      := '/tmp/crai.mirror';
    my $archive-url := '';
    download-archive($curl, $mirror, $archive-url);

=head1 DESCRIPTION

This module provides functions for working with a mirror.
A mirror is a directory that stores archives for further analysis and hosting.
Archives are downloaded from whatever URL you give it, typically CPAN or GitHub.

Archives are expected not to change after they have been downloaded.
Downloading the archive at a given URL twice should result in the same bytes.

=head2 On-disk format

The mirror directory is an argument given to the routines in this module.
It stores archives in their original form, typically tarballs or zipballs.
The filename of each archive is the SHA-256 hash of the URL of the archive.

=head2 download-archive($curl, $mirror, $archive-url)

Download an archive if it is not already present in the mirror.

C<$curl> must be an instance of B<LibCurl::Curl>.
You may set your own options on this handle before calling this routine.
You are advised to use the same instance for multiple calls to this routine,
so libcurl can maintain a connection pool.

C<$mirror> must be the path to the mirror directory.
The mirror directory must already exist, and must be writable.

C<$archive-url> must be the URL of the archive.
This may be any URL that libcurl accepts.

This routines returns one of three types of values,
which you can smartmatch against:

    given download-archive($curl, $mirror, $archive-url) {
        when Exception { #`｢Something went wrong, see $_｣ }
        when IO::Path  { #`｢The archive was downloaded to $_｣ }
        when :present  { #`｢The archive was already in the mirror｣ }
    }

=end pod
