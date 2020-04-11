unit module Crai::Cron;

use Crai::Cpan;

my sub MAIN()
    is export
{
    .put for list-cpan-archives;
}
