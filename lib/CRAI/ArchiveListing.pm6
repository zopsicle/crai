#| An archive listing implements the archives method,
#| which returns a sequence of archive URLs.
#| An archive is a tarball or zipball
#| containing a Raku distribution.
#|
#| An archive listing is expected not to download the archives.
#| Instead, it should merely return the URLs to the archives.
unit class CRAI::ArchiveListing;

#| List of file extensions for archives.
our constant @archive-file-extensions is export =
    <.tar .tar.bz .tar.bz2 .tar.gz .tar.xz
     .tbz .tbz2 .tgz .txz .zip>;

#| Return a sequence of strings that contain the archive URLs.
#| This routine is expected to perform side-effects,
#| in particular network calls.
method archives { … }
