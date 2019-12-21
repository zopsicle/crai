unit class CRAI::Database;

use DBDish::Connection;
use DBDish::StatementHandle;
use DBIish;
use Terminal::ANSIColor;

has DBDish::Connection $!sqlite;
has IO::Path           $!archives;

method new(|c)
{
    die ‘Use CRAI::Database.open instead’;
}

method open(IO::Path:D $path --> ::?CLASS:D)
{
    self.bless(:$path);
}

submethod BUILD(IO::Path:D :$path)
{
    $!sqlite   = DBIish.connect(‘SQLite’, database => $path.child(‘sqlite’));
    $!sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS archives (
            url                     text    NOT NULL,

            filename                text,

            md5_hash                text,
            sha1_hash               text,
            sha256_hash             text,

            meta_name               text,
            meta_version            text,
            meta_description        text,
            meta_source_url         text,
            meta_license            text,

            PRIMARY KEY (url)
        );
        SQL
    # TODO: Create table for depends.
    # TODO: Create table for provides.

    $!archives = $path.child(‘archives’);
    $!archives.mkdir;
}

has DBDish::StatementHandle $!ensure-archive-sth;
method ensure-archive(::?CLASS:D: Str:D $url --> Nil)
{
    $!ensure-archive-sth //= $!sqlite.prepare(q:to/SQL/);
        INSERT INTO archives (url)
        VALUES ($1)
        ON CONFLICT (url) DO NOTHING
        SQL

    $!ensure-archive-sth.execute($url);

    if $!ensure-archive-sth.rows == 0 {
        note color(‘blue’), ‘[OLD]’, color(‘reset’), ‘ ’, $url;
    } else {
        note color(‘green’), ‘[NEW]’, color(‘reset’), ‘ ’, $url;
    }
}
