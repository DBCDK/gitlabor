{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.14.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "ea59d87ef89da429b8e905264fdec3419f84f2215bb3d81e07a18aac919026c3";
      };

      beamDeps = [];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.23.0";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "6cd1c04cd15c81e5a493f167b226a15f0938a84fc8f0736ebe4ddcab65c0b44e";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "1.0.3";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "8eab6e1cfa8d5918c2ce4ba43588e894af35dbd8e91e6e55c817bca5847df34a";
      };

      beamDeps = [];
    };

    httpoison = buildMix rec {
      name = "httpoison";
      version = "2.2.3";

      src = fetchHex {
        pkg = "httpoison";
        version = "${version}";
        sha256 = "fa0f2e3646d3762fdc73edb532104c8619c7636a6997d20af4003da6cfc53e53";
      };

      beamDeps = [ hackney ];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.4";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "c5eb0cab91f094599f94d55bc63409236a8ec69a21a67814529e8d5f6cc90b3b";
      };

      beamDeps = [];
    };

    libvault = buildMix rec {
      name = "libvault";
      version = "0.2.4";

      src = fetchHex {
        pkg = "libvault";
        version = "${version}";
        sha256 = "f495afb2b99464b8c1dccccf59744afb361169ca1fc67ba48e71ed35a00315f0";
      };

      beamDeps = [ hackney mint tesla ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.6";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "c9945363a6b26d747389aac3643f8e0e09d30499a138ad64fe8fd1d13d9b153e";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.3.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "a1e15a50d1887217de95f0b9b0793e32853f7c258a5cd227650889b38839fe9d";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.7.1";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "fceba0a4d0f24301ddee3024ae116df1c3f4bb7a563a731f45fdfeb9d39a231b";
      };

      beamDeps = [ hpax ];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.14.1";

      src = fetchHex {
        pkg = "tesla";
        version = "${version}";
        sha256 = "c1dde8140a49a3bef5bb622356e77ac5a24ad0c8091f12c3b7fc1077ce797155";
      };

      beamDeps = [ hackney jason mime mint ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };

    uuid = buildMix rec {
      name = "uuid";
      version = "1.1.8";

      src = fetchHex {
        pkg = "uuid";
        version = "${version}";
        sha256 = "c790593b4c3b601f5dc2378baae7efaf5b3d73c4c6456ba85759905be792f2ac";
      };

      beamDeps = [];
    };

    wallaby = buildMix rec {
      name = "wallaby";
      version = "0.30.10";

      src = fetchHex {
        pkg = "wallaby";
        version = "${version}";
        sha256 = "a8f89b92d8acce37a94b5dfae6075c2ef00cb3689d6333f5f36c04b381c077b2";
      };

      beamDeps = [ httpoison jason web_driver_client ];
    };

    web_driver_client = buildMix rec {
      name = "web_driver_client";
      version = "0.2.0";

      src = fetchHex {
        pkg = "web_driver_client";
        version = "${version}";
        sha256 = "83cc6092bc3e74926d1c8455f0ce927d5d1d36707b74d9a65e38c084aab0350f";
      };

      beamDeps = [ hackney jason tesla ];
    };
  };
in self

