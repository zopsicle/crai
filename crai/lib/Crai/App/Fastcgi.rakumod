unit module Crai::App::Fastcgi;

use Crai::Web::Psgi;
use FastCGI::NativeCall;

my sub MAIN(:$fastcgi-socket!, :$database! --> Nil)
    is export
{
    my &app := { serve-psgi(%^env, :$database) };

    my $fcgi := FastCGI::NativeCall.new(path => $fastcgi-socket);
    while $fcgi.accept() {
        my ($status, $headers, $body) := app($fcgi.env);
        $fcgi.header(Status => $status, |$headers);
        $fcgi.Print($_) for $body[];
    }
}
