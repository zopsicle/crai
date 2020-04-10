<?php
namespace Craw\Database;

function execute($dbh, $sql, $values)
{
    $sth = $dbh->prepare($sql);
    foreach ($values as $i => $v)
        $sth->bindValue($i + 1, $v);
    $res = $sth->execute();
    while (($row = $res->fetchArray(SQLITE3_ASSOC)) !== FALSE)
        yield $row;
}

function fetch_archive($dbh, $url)
{
    $rows = execute($dbh, '
        SELECT
            url,

            hash_md5,
            hash_sha1,
            hash_sha256,

            meta_perl,
            meta_name,
            meta_version,
            meta_description,
            meta_support_email,
            meta_support_mailinglist,
            meta_support_bugtracker,
            meta_support_source,
            meta_support_irc,
            meta_support_phone,
            meta_production,
            meta_license

        FROM
            archives

        WHERE
            url = ?1

        ORDER BY
            norm_version DESC

        LIMIT 1
    ', [$url]);

    foreach ($rows as $archive) {
        $meta_authors  = fetch_meta_authors($dbh, $archive['url']);
        $meta_tags     = fetch_meta_tags($dbh, $archive['url']);
        $meta_provides = fetch_meta_provides($dbh, $archive['url']);
        $meta_depends  = fetch_meta_depends($dbh, $archive['url']);
        $archive['meta_authors']  = iterator_to_array($meta_authors);
        $archive['meta_provides'] = iterator_to_array($meta_provides);
        $archive['meta_depends']  = iterator_to_array($meta_depends);
        $archive['meta_tags']     = iterator_to_array($meta_tags);
        return $archive;
    }
}

function fetch_meta_authors($dbh, $archive_url)
{
    $rows = execute($dbh, '
        SELECT   author
        FROM     meta_authors
        WHERE    archive_url = ?1
        ORDER BY author ASC
    ', [$archive_url]);
    foreach ($rows as $row)
        yield $row['author'];
}

function fetch_meta_provides($dbh, $archive_url)
{
    $rows = execute($dbh, '
        SELECT   unit, file
        FROM     meta_provides
        WHERE    archive_url = ?1
        ORDER BY unit ASC
    ', [$archive_url]);
    return $rows;
}

function fetch_meta_depends($dbh, $archive_url)
{
    $rows = execute($dbh, '
        SELECT   phase, use
        FROM     meta_depends
        WHERE    archive_url = ?1
        ORDER BY use ASC, phase ASC
    ', [$archive_url]);
    return $rows;
}

function fetch_meta_tags($dbh, $archive_url)
{
    $rows = execute($dbh, '
        SELECT   tag
        FROM     meta_tags
        WHERE    archive_url = ?1
        ORDER BY tag ASC
    ', [$archive_url]);
    foreach ($rows as $row)
        yield $row['tag'];
}
