unit module Crai::Web::Runs;

use Crai::Web::Layout;
use Template::Classic;

my &template-runs := template :(:@runs, :$chart), q:to/HTML/;
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

    <% take($chart) %>
    HTML

my sub render-runs(|c)
    is export
{
    template-runs(|c);
}

my sub respond-runs(@runs)
    is export
{
    my $gnuplot := run('gnuplot', :in, :out);
    $gnuplot.in.print: q:to/GNUPLOT/;
        set datafile separator ','
        set terminal svg

        set format x "%m-%d\n%H:%M"
        set timefmt '%Y-%m-%d %H:%M:%S'
        set xdata time

        plot '-' using 1:2 with lines
        GNUPLOT
    for @runs -> %run {
        $gnuplot.in.put: "%run<when>,%run<encounters>";
    }
    $gnuplot.in.close;
    my $chart := $gnuplot.out.slurp;
    $gnuplot.sink;

    my $title := ｢Runs｣;
    sub content { render-runs(:@runs, :$chart) }

    return (
        200,
        { Content-Type => 'text/html' },
        render-layout(:$title, :&content),
    );
}

