{
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule rec {
  pname = "prs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "dhth";
    repo = "prs";
    rev = "v${version}";
    hash = "sha256-oVG2BMO3vYJQwrDHblM7Wq2PV46hDwtLDq1J9AwFKAk=";
  };

  vendorHash = "sha256-YcbXdgNJ3D2wofye59Vj7mBIgvKBGtKL5o/3QnEooWE=";
}
