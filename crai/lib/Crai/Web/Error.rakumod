unit module Crai::Web::Error;

use Crai::Web::Layout;
use Template::Classic;

my &template-error := template :(:$description!), q:to/HTML/;
    <p><%= $description %></p>
    HTML

my sub render-error(|c)
    is export
{
    template-error(|c);
}

my sub respond-error(Int() $status --> Nil)
    is export
{
    constant %errors := {
        0   => (｢Unknown error｣, ｢Something went wrong.｣),
        404 => (｢Not found｣, ｢The page you were looking for does not exist.｣),
    };

    my ($title, $description) := %errors{$status} // %errors{0};
    sub content { render-error(:$description) }

    print("Status: $status\r\n");
    print("Content-Type: text/html\r\n");
    print("\r\n");
    print($_) for render-layout(:$title, :&content);
}
