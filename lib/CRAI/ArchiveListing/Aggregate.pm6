=begin pod

=head1 NAME

CRAI::ArchiveListing::Aggregate - Combine multiple archive listings

=head1 DESCRIPTION

This role can be mixed into a subclass of C«CRAI::ArchiveListing»
to provide the C«archives» method.

All you have to do is mix in the role and
implement the C«archive-listings» method.

=head2 .archive-listings

Return a sequence of instances of C«CRAI::ArchiveListing».

=head2 .archives

All archives reported by
all archive listings in C«self.archive-listings».

=end pod

unit role CRAI::ArchiveListing::Aggregate;

method archive-listings { … }

method archives(--> Seq:D)
{
    self.archive-listings.map: |*.archives;
}
