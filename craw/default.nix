{ makeWrapper, php, stdenvNoCC }:
stdenvNoCC.mkDerivation {
    name = "craw";
    src = ./.;
    buildInputs = [makeWrapper];
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
        mkdir --parents $out/bin
        mv www lib $out
        makeWrapper ${php}/bin/php $out/bin/craw.dev    \
            --add-flags -t                              \
            --add-flags $out/www                        \
            --add-flags -S
    '';
}
