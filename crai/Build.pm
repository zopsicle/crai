class Build
{
    method build(IO() $dir --> Nil)
    {
        run('sassc',
            '--precision', '10',
            "$dir/static/style.scss",
            "$dir/static/style.css");
    }
}
