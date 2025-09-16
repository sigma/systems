{
  buildGoModule,
  cacert,
  fetchFromGitHub,
  lib,
  nodejs,
  stdenv,
  ...
}:
let
  # Fetch the main Jaeger repository
  jaegerSrc = fetchFromGitHub {
    owner = "jaegertracing";
    repo = "jaeger";
    rev = "v2.10.0";
    hash = "sha256-1MoyaJtOydqBcPWcrRZol/yUotfKtTBzj3ZDG6U/LFE=";
  };

  # Fetch the jaeger-ui submodule separately
  jaegerUiSrc = fetchFromGitHub {
    owner = "jaegertracing";
    repo = "jaeger-ui";
    rev = "b375fa5d52ea248c11c48cfca202652103fff430";
    hash = "sha256-EFrEJGwaMdCDYoEXX3u+n0m5jwjfePiilARfw0c+jv4=";
  };

  # Build the UI separately using the official process
  jaegerUi = stdenv.mkDerivation {
    name = "jaeger-ui-built";
    src = jaegerUiSrc;

    nativeBuildInputs = [
      nodejs
      cacert
    ];

    buildPhase = ''
      # Install UI dependencies
      export NPM_CONFIG_AUDIT=false
      export NPM_CONFIG_FUND=false
      export NPM_CONFIG_UPDATE_NOTIFIER=false
      export NPM_CONFIG_CACHE=$TMPDIR/npm-cache

      npm install --no-audit --no-fund --no-update-notifier

      # Build the UI
      npm run build
    '';

    installPhase = ''
      mkdir -p $out
      # The build output is in packages/jaeger-ui/build
      cp -r packages/jaeger-ui/build $out/
    '';
  };

  # Create composite source tree with built UI
  compositeSrc = stdenv.mkDerivation {
    name = "jaeger-composite-src";
    src = jaegerSrc;

    buildInputs = [ jaegerUi ];

    buildPhase = ''
      # Copy the main source to a temporary location
      cp -r $src/* .

      # Create the UI archive file in the expected location
      mkdir -p cmd/query/app/ui/actual

      # Copy the built UI files (copy the contents of the build directory)
      cp -r ${jaegerUi}/build/* cmd/query/app/ui/actual/

      # Debug: show what we copied
      echo "Contents after copy:"
      ls -la cmd/query/app/ui/actual/

      # Gzip the UI assets as expected by Jaeger (only gzip files that aren't already gzipped)
      find cmd/query/app/ui/actual -type f -name "*.html" -o -name "*.js" -o -name "*.css" | xargs gzip --no-name || true

      # Verify that index.html.gz exists (fail early if not)
      if [ ! -f "cmd/query/app/ui/actual/index.html.gz" ]; then
        echo "Error: index.html.gz not found in UI build output"
        echo "Contents of cmd/query/app/ui/actual:"
        ls -la cmd/query/app/ui/actual/
        exit 1
      fi

      echo "UI build verification: index.html.gz found"

      # Copy everything to $out
      cp -r . $out/
    '';

    installPhase = ''
      # The buildPhase already creates the output in $out
      true
    '';
  };
in
buildGoModule rec {
  pname = "jaeger";
  version = "2.10.0";

  src = compositeSrc;

  vendorHash = null;

  subPackages = [ "cmd/jaeger" ];

  # Use modSha256 and proxyVendor to avoid vendoring issues
  modSha256 = "sha256-3BK2jfspWNtNKlpaCa5LmDguXNIs1PmqFu2ulHhd3pY=";
  proxyVendor = true;

  # Override GOPROXY to allow module downloads
  preBuild = ''
    export GOPROXY=https://proxy.golang.org,direct
  '';

  nativeBuildInputs = [ ];

  # Set version information for debugging
  ldflags = [
    "-X github.com/jaegertracing/jaeger/internal/version.commitSHA=${jaegerSrc.rev}"
    "-X github.com/jaegertracing/jaeger/internal/version.latestVersion=${version}"
    "-X github.com/jaegertracing/jaeger/internal/version.date=1970-01-01T00:00:00Z"
  ];

  meta = with lib; {
    description = "Jaeger - a Distributed Tracing System";
    homepage = "https://www.jaegertracing.io/";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
