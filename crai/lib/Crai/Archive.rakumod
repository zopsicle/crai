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

=begin pod

=head1 NAME

Crai::Archive - Work with archives

=head1 SYNOPSIS

    use Crai::Archive;
    use JSON::Fast;
    my $meta := read-meta($archive-path) // die('No META6.json in archive');
    my %meta := from-json($meta);
    say %meta<name>;

=head1 DESCRIPTION

An archive is a tarball or zipball with a I<META6.json> file, source files,
and resource files in it.
This module exports routines for working with archives.

=head2 read-meta($archive-path)

Return the contents of the I<META6.json> file in the archive as a string.
The I<META6.json> file is automatically located by searching the archive.
If no I<META6.json> file could be found, returns B<Nil>.

=head1 BUGS

This module only supports tarballs, not zipballs.

This module only works with GNU tar.

=head1 SEE ALSO

The B<Crai::Mirror> module downloads archives and stores them on disk.

=end pod
