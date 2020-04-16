unit module Crai::Web::Runs;

use Crai::Web::Layout;
use Template::Classic;

my &template-runs := template :(:@runs), q:to/HTML/;
    <table>
        <thead>
            <tr><th>Run
                <th>Archives
        <tbody>
            <% for @runs -> %run { %>
                <tr>
                    <td><%= %run<when> %>
                    <td><%= %run<encounters> %>
            <% } %>
    </table>
    HTML

my sub render-runs(|c)
    is export
{
    template-runs(|c);
}

my sub respond-runs(@runs)
    is export
{
    my $title := ｢Runs｣;
    sub content { render-runs(:@runs) }

    return (
        200,
        { Content-Type => 'text/html' },
        render-layout(:$title, :&content),
    );
}

