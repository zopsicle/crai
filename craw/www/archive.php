<?php

require_once __DIR__ . '/../lib/Craw/Database.php';
require_once __DIR__ . '/../lib/Craw/Layout.php';

$dbh = new SQLite3('/tmp/crai.sqlite3', SQLITE3_OPEN_READONLY);
$archive = Craw\Database\fetch_archive($dbh, 'https://www.cpan.org/authors/id/C/CH/CHLOEKEK/Perl6/Template-Classic-0.0.2.tar.gz');

Craw\Layout\layout(
    $archive['meta_name'] . ' ' . $archive['meta_version'],
    $archive['meta_description'],
    function() use($archive) {
        $nix = 'raku."' . str_replace('::', '-', $archive['meta_name']) . '"';
        $zef = 'zef install ' . $archive['meta_name'];

        ?>
            <h2 id="install">Install</h2>
            <table class="craw--properties">
                <tr><th>Nix     <td><?= htmlentities($nix) ?>
                <tr><th>Zef     <td><?= htmlentities($zef) ?>
                <tr><th>URL     <td><?= htmlentities($archive['url']) ?>
                <tr><th>MD5     <td><?= htmlentities($archive['hash_md5'] ?? 'N/A') ?>
                <tr><th>SHA-1   <td><?= htmlentities($archive['hash_sha1'] ?? 'N/A') ?>
                <tr><th>SHA-256 <td><?= htmlentities($archive['hash_sha256'] ?? 'N/A') ?>
            </table>

            <h2 id="metadata">Metadata</h2>
            <table class="craw--properties">
                <tr><th>Perl</th>       <td><?= htmlentities($archive['meta_perl'] ?? 'N/A') ?>
                <tr><th>License</th>    <td><?= htmlentities($archive['meta_license'] ?? 'N/A') ?>
                <tr><th>Authors</th>    <td><?= htmlentities(implode(', ', $archive['meta_authors'])) ?>
                <tr><th>Tags</th>       <td><?= htmlentities(implode(', ', $archive['meta_tags'])) ?>
            </table>

            <h2 id="readme">Readme</h2>
            <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Qui,
            molestias tempore veritatis accusamus odio aperiam officiis numquam
            expedita ipsa rem laudantium? Nostrum neque, quia optio illo
            reiciendis ipsum? Quae, esse!

            <h2 id="compunits">Compunits</h2>
            <ul>
                <?php foreach ($archive['meta_provides'] as $meta_provide): ?>
                    <li><?= htmlentities($meta_provide['unit']) ?>
                <?php endforeach; ?>
            </ul>

            <h2 id="dependencies">Dependencies</h2>
            <ul>
                <?php foreach ($archive['meta_depends'] as $meta_depend): ?>
                    <li><?= htmlentities($meta_depend['use']) ?>
                        (<?= htmlentities($meta_depend['phase']) ?>)
                <?php endforeach; ?>
            </ul>
        <?php
    },
);
