unit module Crai::Web::Archive;

use Crai::Web::Layout;
use Template::Classic;

my &template-archive := template :(:%archive!, :$nix, :$zef), q:to/HTML/;
    <% use URI::Escape; %>

    <h2 id="install">Install</h2>
    <table class="crai--properties">
        <tr><th>Nix     <td><%= $nix %>
        <tr><th>Zef     <td><%= $zef %>
        <tr><th>URL     <td><%= %archive<url> %>
        <tr><th>MD5     <td><%= %archive<hash-md5>    or ｢N/A｣ %>
        <tr><th>SHA-1   <td><%= %archive<hash-sha1>   or ｢N/A｣ %>
        <tr><th>SHA-256 <td><%= %archive<hash-sha256> or ｢N/A｣ %>
    </table>

    <h2 id="metadata">Metadata</h2>
    <table class="crai--properties">
        <tr><th>Perl         <td><%= %archive<meta-perl>                or ｢N/A｣ %>
        <tr><th>License      <td><%= %archive<meta-license>             or ｢N/A｣ %>
        <tr><th>Authors      <td><%= %archive<meta-authors>.join(', ')  or ｢N/A｣ %>
        <tr><th>Tags         <td><%= %archive<meta-tags>.join(', ')     or ｢N/A｣ %>
        <tr><th>Email        <td><%= %archive<meta-support-email>       or ｢N/A｣ %>
        <tr><th>Mailing list <td><%= %archive<meta-support-mailinglist> or ｢N/A｣ %>
        <tr><th>Bug tracker  <td><%= %archive<meta-support-bugtracker>  or ｢N/A｣ %>
        <tr><th>Source       <td><%= %archive<meta-support-source>      or ｢N/A｣ %>
        <tr><th>IRC          <td><%= %archive<meta-support-irc>         or ｢N/A｣ %>
        <%
            # Concerning meta-support-phone, that one is a privacy legislation
            # nightmare that I do not want to get into. We’ll skip it.
        %>
    </table>

    <h2 id="versions">Versions</h2>
    <% for %archive<meta-versions>[] -> (:key($url), :value($version)) { %>
        <% if $url eq %archive<url> { %>
            <strong><%= $version %></strong>
        <% } else { %>
            <a href="/archive/<%= uri-escape($url) %>"><%= $version %></a>
        <% } %>
    <% } %>

    <h2 id="readme">Readme</h2>
    <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Qui,
    molestias tempore veritatis accusamus odio aperiam officiis numquam
    expedita ipsa rem laudantium? Nostrum neque, quia optio illo
    reiciendis ipsum? Quae, esse!

    <h2 id="compunits">Compunits</h2>
    <ul>
        <% for %archive<meta-provides>.keys.collate -> $unit { %>
            <li><%= $unit %>
        <% } %>
    </ul>

    <h2 id="dependencies">Dependencies</h2>
    <ul>
        <% for %archive<meta-depends>.kv -> $phase, @use { %>
            <% for @use -> $use { %>
                <li><%= $use %> (<%= $phase %>)
            <% } %>
        <% } %>
    </ul>
    HTML

my sub render-archive(|c)
    is export
{
    template-archive(|c);
}

my sub respond-archive(%archive)
    is export
{
    my $title    := "%archive<meta-name> %archive<meta-version>";
    my $subtitle := %archive<meta-description>;
    my $query    := %archive<meta-name> // '';
    my $nix      := "raku.\"{%archive<meta-name>}\"";
    my $zef      := "zef install \"%archive<meta-name>\"";
    sub content { render-archive(:%archive, :$nix, :$zef) }

    return (
        200,
        { Content-Type => 'text/html' },
        render-layout(:$title, :$subtitle, :$query, :&content),
    );
}
