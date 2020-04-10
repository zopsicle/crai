<?php
namespace Craw\Layout;

function layout($title, $subtitle, $content) {
?><!DOCTYPE html>
<meta charset="utf-8">
<link rel="stylesheet" href="/static/reset.css">
<link rel="stylesheet" href="/static/style.css">
<title><?= htmlentities($title) ?> at CRAI</title>
<body class="crai--light">
<nav>
    <div>
        <a href="/">CRAI</a>
    </div>
</nav>
<header>
    <div>
        <h1><?= htmlentities($title) ?></h1>
        <p><?= htmlentities($subtitle) ?>
    </div>
</header>
<section>
    <div>
        <?php $content(); ?>
    </div>
</section>
<footer>
    <div>
        <p>
        <a href="https://github.com/chloekek/crai">CRAI</a> © Chloé Kekoa.
        <a href="https://github.com/perl6/mu/blob/master/misc/camelia.txt">Camelia</a>
            ™ Larry Wall.
    </div>
</footer>
<?php
}
