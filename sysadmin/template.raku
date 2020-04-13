my %c = @*ARGS.map: { [=>] .split(‘=’, 2) };
put S:g/‘@’(@(%c.keys))‘@’/%c{$0}/ for $*IN.lines;
