#| Combine the archives from various archive listings.
unit role CRAI::ArchiveListing::Aggregate;

#| Return a sequence of archive listings.
method archive-listings { … }

#| Return the archives from all
#| archive listings returned from C«archive-listings».
method archives(--> Seq:D)
{
    self.archive-listings.map: |*.archives;
}
