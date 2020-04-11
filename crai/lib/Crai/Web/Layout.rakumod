unit module Crai::Web::Layout;

use Template::Classic;

my &template-layout := template :(:$title!, :$subtitle, :&content!), q:to/HTML/;
    <!DOCTYPE html>
    <meta charset="utf-8">
    <link rel="stylesheet" href="/static/style.css">
    <title><%= $title %> at CRAI</title>
    <body class="crai--dark">
    <nav>
        <div>
            <a href="/">CRAI</a>
        </div>
    </nav>
    <header>
        <div>
            <h1><%= $title %></h1>
            <% with $subtitle { %>
                <p><%= $_ %></p>
            <% } %>
        </div>
    </header>
    <section>
        <div>
            <% .take for content %>
        </div>
    </section>
    <footer>
        <div>
            <p>
                <a href="https://github.com/chloekek/crai">CRAI</a> © Chloé Kekoa.
                <a href="https://github.com/perl6/mu/blob/master/misc/camelia.txt">Camelia</a>
                    ™ Larry Wall.
            </p>
        </div>
    </footer>
    HTML

my sub render-layout(|c)
    is export
{
    template-layout(|c);
}
