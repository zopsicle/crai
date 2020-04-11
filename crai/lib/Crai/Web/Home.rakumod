unit module Crai::Web::Home;

use Crai::Web::Layout;
use Template::Classic;

my &template-home := template :(), q:to/HTML/;
    <p>
    The <strong>Comprehensive Raku Archive Index</strong> hosts
    metadata about Raku module distribution archives.
    Metadata is retained as new versions of module distributions are
    released, providing a historical database as a possible basis for
    reproducible builds.
    You may also search the database using the web interface, which you are
    currently looking at.
    <p>
    CRAI is a work in progress. You may encounter bugs or desire missing
    features. Please <a href="https://github.com/chloekek/crai/issues">let me know</a>
    if you need anything!
    HTML

my sub render-home(|c)
    is export
{
    template-home(|c);
}

my sub respond-home(Int() $statistic --> Nil)
    is export
{
    my $title    := ｢Comprehensive Raku Archive Index｣;
    my $subtitle := qq｢Hosting metadata about $statistic archives!｣;
    sub content { render-home }

    print("Content-Type: text/html\r\n");
    print("\r\n");
    print($_) for render-layout(:$title, :$subtitle, :&content);
}
