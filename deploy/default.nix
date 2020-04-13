{ makeWrapper, nix, openssh, production, rakudo, stdenvNoCC, terraform }:
stdenvNoCC.mkDerivation {
    name = "crai-deploy";

    src = ./.;
    buildInputs = [ makeWrapper ];
    inherit nix openssh production rakudo terraform;

    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
        mkdir --parents $out/bin $out/lib

        cp deploy.raku $out/lib/deploy.raku
        cp hcloud_crai.tf $out/lib/hcloud_crai.tf

        extraPATH=$nix/bin:$rsync/bin:$openssh/bin:$terraform/bin

        makeWrapper $rakudo/bin/raku $out/bin/deploy        \
            --prefix PATH : "$extraPATH"                    \
            --add-flags $out/lib/deploy.raku                \
            --add-flags --production=$production            \
            --add-flags --terraform=$out/lib
    '';
}
