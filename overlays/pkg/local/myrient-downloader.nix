{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  electron,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "myrient-downloader";
  version = "3.1.3";

  src = fetchFromGitHub {
    owner = "bradrevans";
    repo = "myrient-downloader";
    rev = "v${version}";
    hash = "sha256-ovbdxv49Z8LLhYIR+P4Stsva4NzOaLY7m7k9nE2AXlE=";
  };

  npmDepsHash = "sha256-yqw2mYAd2DN/DFriMEGgmKtqeKEac8KyZYOPIKnwnyo=";

  nativeBuildInputs = [ makeWrapper ];

  # Don't run npm audit and other unnecessary checks
  npmFlags = [ "--legacy-peer-deps" ];

  # Skip Electron binary download - we'll use the one from nixpkgs
  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # Build phase - we need to build the CSS
  buildPhase = ''
    runHook preBuild
    npm run build:css
    runHook postBuild
  '';

  # Install the application files
  installPhase = ''
    runHook preInstall

    # Create the application directory
    mkdir -p $out/lib/myrient-downloader

    # Copy application files
    cp -r src $out/lib/myrient-downloader/
    cp -r node_modules $out/lib/myrient-downloader/
    cp package.json $out/lib/myrient-downloader/

    # Create wrapper script
    mkdir -p $out/bin
    makeWrapper ${electron}/bin/electron $out/bin/myrient-downloader \
      --add-flags $out/lib/myrient-downloader

    runHook postInstall
  '';

  meta = with lib; {
    description = "A powerful desktop application for accessing and downloading public domain game archives from the Myrient library";
    homepage = "https://github.com/bradrevans/myrient-downloader";
    license = licenses.isc;
    maintainers = [
      sigma
    ];
    platforms = platforms.unix;
    mainProgram = "myrient-downloader";
  };
}
