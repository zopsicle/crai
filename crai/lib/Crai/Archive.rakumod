unit module Crai::Archive;

my sub find-meta(IO() $archive-path)
    is export
{
    use fatal;
    my $tar := run('tar', '--list', "--file=$archive-path", :out);
    $tar.out.lines.grep(/«'META6.json'»/).head;
}

my sub read-meta(IO() $archive-path)
    is export
{
    use fatal;
    my $tar := run(
        'tar',
        '--extract',
        "--file=$archive-path",
        '--to-stdout',
        find-meta($archive-path) // return,
        :out,
    );
    $tar.out.slurp;
}

my sub normalize-meta(%meta)
    is export
{
    multi sub prefix:<$~←>(Str:D $x) { $x }
    multi sub prefix:<$~←>($x)       { Nil }

    multi sub prefix:<$?←>(Bool:D $x) { $x }
    multi sub prefix:<$?←>($x)        { Nil }

    multi sub prefix:<@~←>(@xs) { @xs.map($~←*).grep(*.defined).list }
    multi sub prefix:<@~←>($xs) { () }

    multi sub prefix:<%~←>(%xs) { %xs.pairs.map({ .key => $~←.value }).grep(*.value.defined).Hash }
    multi sub prefix:<%~←>($xs) { {} }

    my %depends = do given %meta<depends> {
        when !*.defined {
            Empty;
        }
        when List {
            runtime => @~← %meta<depends>,
            build   => @~← %meta<build-depends>,
            test    => @~← %meta<test-depends>,
        }
        when Hash {
            runtime => @~← %meta<depends><runtime><requires>,
            build   => @~← %meta<depends><build><requires>,
            test    => @~← %meta<depends><test><requires>,
        }
    };

    {
        meta-perl                => $~← %meta<perl>,
        meta-name                => $~← %meta<name>,
        meta-version             => $~← %meta<version>,
        meta-description         => $~← %meta<description>,
        meta-support-email       => $~← %meta<support><email>,
        meta-support-mailinglist => $~← %meta<support><mailinglist>,
        meta-support-bugtracker  => $~← %meta<support><bugtracker>,
        meta-support-source      => $~← (%meta<support><source> // %meta<source-url>),
        meta-support-irc         => $~← %meta<support><irc>,
        meta-support-phone       => $~← %meta<support><phone>,
        meta-production          => $?← %meta<production>,
        meta-license             => $~← %meta<license>,
        meta-authors             => @~← %meta<authors>,
        meta-provides            => %~← %meta<provides>,
        meta-depends             => %depends,
        meta-emulates            => %~← %meta<emulates>,
        meta-resources           => @~← %meta<resources>,
        meta-tags                => @~← %meta<tags>,
    };
}

=begin pod

=head1 NAME

Crai::Archive - Work with archives

=head1 SYNOPSIS

    use Crai::Archive;
    use JSON::Fast;
    my $meta := read-meta($archive-path) // die('No META6.json in archive');
    my %meta := from-json($meta);
    my %norm := normalize-meta(%meta);
    say %norm<meta-name>;

=head1 DESCRIPTION

An archive is a tarball or zipball with a I<META6.json> file, source files,
and resource files in it.
This module exports routines for working with archives.

=head2 read-meta($archive-path)

Return the contents of the I<META6.json> file in the archive as a string.
The I<META6.json> file is automatically located by searching the archive.
If no I<META6.json> file could be found, returns B<Nil>.

=head2 normalize-meta(%meta)

Normalize metadata parsed from I<META6.json>,
so that it can be slipped to B<Crai::Database::update-archive-meta>.

Does not alter the input, but returns a new hash.

=head1 BUGS

This module only supports tarballs, not zipballs.

This module only works with GNU tar.

=head1 SEE ALSO

The B<Crai::Mirror> module downloads archives and stores them on disk.

=end pod
