unit class Crai::Database;

has $.dbh;
has %!sth;

my sub date-str(DateTime() $_)
{
    "{.yyyy-mm-dd} {.hh-mm-ss}";
}

my sub normalize-version(Version() $_)
{
    (|~«.parts, |('' xx ∞))
        .map({ /^\d+$/ ?? +$_ !! 0 })
        .map({ sprintf("%08d", $_) })
        .head(6)
        .join('.');
}

method new(:$dbh)
{
    my $self := self.bless(:$dbh);
    $self!setup;
    $self;
}

method !sth(::?CLASS:D: Str() $sql)
{
    %!sth{$sql} //= $!dbh.prepare($sql);
}

method !setup(::?CLASS:D: --> Nil)
{
    $!dbh.do(q:to/SQL/);
        -- An archive is a tarball retrieved from CPAN or GitHub.
        -- An archive contains exactly one distribution.
        -- This table stores metadata about the archive and distribution.
        -- Some metadata is stored in other tables, due to plurality.
        CREATE TABLE IF NOT EXISTS archives (
            -- Unique URL and hashes of the archive.
            url                         TEXT    NOT NULL,

            -- Hashes of the archive.
            hash_md5                    TEXT,
            hash_sha1                   TEXT,
            hash_sha256                 TEXT,

            -- Raw fields from META6.json.
            meta_perl                   TEXT,
            meta_name                   TEXT,
            meta_version                TEXT,
            meta_description            TEXT,
            meta_support_email          TEXT,
            meta_support_mailinglist    TEXT,
            meta_support_bugtracker     TEXT,
            meta_support_source         TEXT,
            meta_support_irc            TEXT,
            meta_support_phone          TEXT,
            meta_production             INTEGER,
            meta_license                TEXT,

            -- Processed meta_version, so that it can be sorted.
            --
            -- The version number is padded to six dot-separated segments.
            -- Each segment is left-padded with zeroes until it is eight long.
            -- For instance, 1.2.3 becomes 00000001.00000002.00000003.
            --                             00000000.00000000.00000000.
            -- Non-numeric parts, such as '-alpha', are treated as 0.
            --
            -- If multiple archives have the same version, sort them according
            -- to encounters.run_when.
            norm_version                TEXT,

            PRIMARY KEY (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_authors (
            archive_url                 TEXT    NOT NULL,
            author                      TEXT    NOT NULL,
            PRIMARY KEY (archive_url, author)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_provides (
            archive_url                 TEXT    NOT NULL,
            unit                        TEXT    NOT NULL,
            file                        TEXT    NOT NULL,
            PRIMARY KEY (archive_url, unit)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_depends (
            archive_url                 TEXT    NOT NULL,
            phase                       TEXT    NOT NULL,
            use                         TEXT    NOT NULL,
            PRIMARY KEY (archive_url, phase, use)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_emulates (
            archive_url                 TEXT    NOT NULL,
            unit                        TEXT    NOT NULL,
            use                         TEXT    NOT NULL,
            PRIMARY KEY (archive_url, unit)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_resources (
            archive_url                 TEXT    NOT NULL,
            resource                    TEXT    NOT NULL,
            PRIMARY KEY (archive_url, resource)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_tags (
            archive_url                 TEXT    NOT NULL,
            tag                         TEXT    NOT NULL,
            PRIMARY KEY (archive_url, tag)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $!dbh.do(q:to/SQL/);
        -- Warnings about problems with an archive.
        -- For instance, mistakes in META6.json.
        CREATE TABLE IF NOT EXISTS warnings (
            archive_url                 TEXT    NOT NULL,
            message                     TEXT    NOT NULL,
            PRIMARY KEY (archive_url, message)
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        );
        SQL

    $!dbh.do(q:to/SQL/);
        -- A run is one invocation of the cron job that indexes archives.
        -- Each run is identified by the time at which it started.
        -- Runs are useful for tracking the state of the ecosystem over time.
        CREATE TABLE IF NOT EXISTS runs (
            [when]                      TEXT    NOT NULL,
            PRIMARY KEY ([when])
        )
        SQL

    $!dbh.do(q:to/SQL/);
        -- For each run, the set of archives that were found to exist.
        CREATE TABLE IF NOT EXISTS encounters (
            run_when                    TEXT    NOT NULL,
            archive_url                 TEXT    NOT NULL,
            PRIMARY KEY (run_when, archive_url)
            FOREIGN KEY (run_when) REFERENCES runs ([when])
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL
}

method fetch-archive-urls(
    ::?CLASS:D:
)
{
    my $sth := self!sth(q:to/SQL/);
        SELECT   url
        FROM     archives
        ORDER BY url ASC
        SQL
    $sth.execute;
    $sth.allrows.map(*[0]);
}

method fetch-archive-count(
    ::?CLASS:D:
)
{
    my $sth := self!sth(q:to/SQL/);
        SELECT COUNT(*)
        FROM   archives
        SQL
    $sth.execute;
    $sth.row[0];
}

method search-archives(
    ::?CLASS:D:
    Str() $query,
)
{
    my @terms = $query.comb(/\S+/);
    return () unless @terms;

    my $sth := self!sth(qq:to/SQL/);
        WITH latests AS (
            SELECT   max(norm_version) AS norm_version
            FROM     archives
            GROUP BY meta_name
        )

        SELECT
            archives.url,
            archives.meta_name,
            archives.meta_version,
            archives.meta_description,
            archives.meta_license,
            (
                SELECT coalesce(group_concat(meta_tags.tag), '')
                FROM   meta_tags
                WHERE  meta_tags.archive_url = archives.url
            ) AS meta_tags

        FROM
            archives

        WHERE
            archives.norm_version IN ( SELECT norm_version FROM latests ) AND
            {@terms.map({ "meta_name LIKE '%' || ?{++$} || '%'" }).join(' AND ')}

        GROUP BY
            meta_name
        SQL
    $sth.execute(@terms);
    $sth.allrows
        ==> map ({ my % = $sth.column-names.map({S:g/_/-/}) Z=> @^a });
}

method fetch-archive(
    ::?CLASS:D:
    Str() $url,
)
{
    my %archive = do {
        my $sth := self!sth(q:to/SQL/);
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
            SQL
        $sth.execute($url);
        $sth.column-names.map({S:g/_/-/}) Z=> $sth.row;
    };

    return {} unless %archive;

    %archive<meta-authors> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT   author
            FROM     meta_authors
            WHERE    archive_url = ?1
            ORDER BY author
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.map(*[0]).list;
    };

    %archive<meta-provides> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT unit, file
            FROM   meta_provides
            WHERE  archive_url = ?1
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.map({ [=>] @^a }).hash;
    };

    %archive<meta-depends> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT phase, use
            FROM   meta_depends
            WHERE  archive_url = ?1
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.classify(*[0], as => *[1]);
    };

    %archive<meta-emulates> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT unit, use
            FROM   meta_emulates
            WHERE  archive_url = ?1
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.map({ [=>] @^a }).hash;
    };

    %archive<meta-resources> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT   resource
            FROM     meta_resources
            WHERE    archive_url = ?1
            ORDER BY resource
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.map(*[0]).list;
    };

    %archive<meta-tags> = do {
        my $sth := self!sth(q:to/SQL/);
            SELECT   tag
            FROM     meta_tags
            WHERE    archive_url = ?1
            ORDER BY tag
            SQL
        $sth.execute(%archive<url>);
        $sth.allrows.map(*[0]).list;
    };

    %archive;
}

method insert-archive(
    ::?CLASS:D:
    Str() $url,
    --> Nil
)
{
    my $sth := self!sth(q:to/SQL/);
        INSERT INTO archives (url)
        VALUES (?1)
        ON CONFLICT DO NOTHING
        SQL
    $sth.execute($url);
}

method update-archive-hashes(
    ::?CLASS:D:
    Str() $url,
    :$hash-md5,
    :$hash-sha1,
    :$hash-sha256,
    --> Nil
)
{
    my $sth := self!sth(q:to/SQL/);
        UPDATE archives
        SET    hash_md5    = ?2,
               hash_sha1   = ?3,
               hash_sha256 = ?4
        WHERE  url = ?1
        SQL
    $sth.execute($url, $hash-md5, $hash-sha1, $hash-sha256);
}

method update-archive-meta(
    ::?CLASS:D:
    Str() $url,
    :$meta-perl,
    :$meta-name,
    :$meta-version,
    :$meta-description,
    :$meta-support-email,
    :$meta-support-mailinglist,
    :$meta-support-bugtracker,
    :$meta-support-source,
    :$meta-support-irc,
    :$meta-support-phone,
    :$meta-production,
    :$meta-license,
    :@meta-authors,
    :%meta-provides,
    :%meta-depends,
    :%meta-emulates,
    :@meta-resources,
    :@meta-tags,
)
{
    self!sth('BEGIN TRANSACTION');
    KEEP self!sth('COMMIT TRANSACTION');
    UNDO self!sth('ROLLBACK TRANSACTION');

    my $sth := self!sth(q:to/SQL/);
        UPDATE archives
        SET    meta_perl                = ?2,
               meta_name                = ?3,
               meta_version             = ?4,
               meta_description         = ?5,
               meta_support_email       = ?6,
               meta_support_mailinglist = ?7,
               meta_support_bugtracker  = ?8,
               meta_support_source      = ?9,
               meta_support_irc         = ?10,
               meta_support_phone       = ?11,
               meta_production          = ?12,
               meta_license             = ?13,
               norm_version             = ?14
        WHERE  url = ?1
        SQL
    $sth.execute(
        $url,
        $meta-perl,
        $meta-name,
        $meta-version,
        $meta-description,
        $meta-support-email,
        $meta-support-mailinglist,
        $meta-support-bugtracker,
        $meta-support-source,
        $meta-support-irc,
        $meta-support-phone,
        $meta-production.defined ?? +$meta-production !! Nil,
        $meta-license,
        normalize-version($meta-version),
    );

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_authors
        WHERE       archive_url = ?1
        SQL
    for @meta-authors -> $author {
        self!sth(q:to/SQL/).execute($url, $author);
            INSERT INTO meta_authors (archive_url, author)
            VALUES (?1, ?2)
            ON CONFLICT DO NOTHING
            SQL
    }

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_provides
        WHERE       archive_url = ?1
        SQL
    for %meta-provides.kv -> $unit, $file {
        self!sth(q:to/SQL/).execute($url, $unit, $file);
            INSERT INTO meta_provides (archive_url, unit, file)
            VALUES (?1, ?2, ?3)
            SQL
    }

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_depends
        WHERE       archive_url = ?1
        SQL
    for %meta-depends.kv -> $phase, @uses {
        for @uses -> $use {
            self!sth(q:to/SQL/).execute($url, $phase, $use);
                INSERT INTO meta_depends (archive_url, phase, use)
                VALUES (?1, ?2, ?3)
                ON CONFLICT DO NOTHING
                SQL
        }
    }

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_emulates
        WHERE       archive_url = ?1
        SQL
    for %meta-emulates.kv -> $unit, $use {
        self!sth(q:to/SQL/).execute($url, $unit, $use);
            INSERT INTO meta_emulates (archive_url, unit, use)
            VALUES (?1, ?2, ?3)
            SQL
    }

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_resources
        WHERE       archive_url = ?1
        SQL
    for @meta-resources -> $resource {
        self!sth(q:to/SQL/).execute($url, $resource);
            INSERT INTO meta_resources (archive_url, resource)
            VALUES (?1, ?2)
            ON CONFLICT DO NOTHING
            SQL
    }

    self!sth(q:to/SQL/).execute($url);
        DELETE FROM meta_tags
        WHERE       archive_url = ?1
        SQL
    for @meta-tags -> $tag {
        self!sth(q:to/SQL/).execute($url, $tag);
            INSERT INTO meta_tags (archive_url, tag)
            VALUES (?1, ?2)
            ON CONFLICT DO NOTHING
            SQL
    }
}

method insert-run(
    ::?CLASS:D:
    DateTime() $when,
    --> Nil
)
{
    self!sth(q:to/SQL/).execute(date-str($when));
        INSERT INTO runs ([when])
        VALUES (?1)
        SQL
}

method insert-encounter(
    ::?CLASS:D:
    DateTime() $run-when,
    Str()      $archive-url,
    --> Nil
)
{
    self!sth(q:to/SQL/).execute(date-str($run-when), $archive-url);
        INSERT INTO encounters (run_when, archive_url)
        VALUES (?1, ?2)
        SQL
}

method insert-warning(
    ::?CLASS:D:
    Str() $archive-url,
    Str() $message,
    --> Nil
)
{
    my $sth := self!sth(q:to/SQL/);
        INSERT INTO warnings (archive_url, message)
        VALUES (?1, ?2)
        ON CONFLICT DO NOTHING
        SQL
    $sth.execute($archive-url, $message);
}
