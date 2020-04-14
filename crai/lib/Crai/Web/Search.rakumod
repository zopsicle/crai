unit module Crai::Web::Search;

use Crai::Web::Layout;
use Template::Classic;

my &template-search := template :(:@archives), q:to/HTML/;
    <% use URI::Escape; %>
    <% for @archives -> %archive { %>
        <article class="crai--search-result">
            <h2 class="-title">
                <a href="/archive/<%= uri-escape(%archive<url>) %>">
                    <%= %archive<meta-name> or ｢N/A｣ %></a>
                <a href="/archive/<%= uri-escape(%archive<url>) %>">
                    <%= %archive<meta-version> or ｢N/A｣ %></a>
            </h2>
            <p class="-description">
                <%= %archive<meta-description> or ｢N/A｣ %>
            </p>
            <p class="-labels">
                <span><%= %archive<meta-license> or ｢N/A｣ %></span>
                <% for %archive<meta-tags>[] { %>
                    <span><%= $_ %></span>
                <% } %>
            </p>
        </article>
    <% } %>
    HTML

my sub render-search(|c)
    is export
{
    template-search(|c);
}

my sub respond-search($query, @archives)
    is export
{
    my $title := "“$query”";
    sub content { render-search(:@archives) }

    return (
        200,
        { Content-Type => 'text/html' },
        render-layout(:$title, :$query, :&content),
    );
}
