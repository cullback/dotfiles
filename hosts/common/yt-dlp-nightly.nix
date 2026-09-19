{
  unstable,
  fetchFromGitHub,
}:

# yt-dlp ships nightlies because YouTube breaks extraction faster than the
# release cadence repairs it, and nixpkgs packages releases only. The
# source is the commit the nightly tag was generated from, taken from
# yt-dlp's own repo so the build matches what nixpkgs expects -- the PyPI
# pre-release sdist lays share/doc out differently and collides with the
# derivation's split doc output.
#
# Bumping means a new rev, hash, version, and stamped version string:
#   gh api repos/yt-dlp/yt-dlp-nightly-builds/releases/latest --jq .body | head -1
#   nix store prefetch-file --unpack https://github.com/yt-dlp/yt-dlp/archive/<rev>.tar.gz
unstable.yt-dlp.overridePythonAttrs (old: rec {
  version = "2026.09.16.232951";

  src = fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    rev = "c7fb478d21e9e59524befbe23f7801bb267fb880";
    hash = "sha256-f98zqG5ov/v6EGZxMqeXSRfKegb+XpEMQD/U5oX7F78=";
  };

  # yt-dlp's CI stamps version.py when it cuts a nightly; a plain checkout
  # still claims the last release, so `yt-dlp --version` would misreport
  # the code it is running, and `-U` would think it is on stable. Stamp it
  # the same way, after the substitutions nixpkgs makes (the deno path
  # among them, which YouTube extraction needs).
  postPatch = old.postPatch + ''
    substituteInPlace yt_dlp/version.py \
      --replace-fail "__version__ = '2026.08.19'" "__version__ = '${version}'" \
      --replace-fail "CHANNEL = 'stable'" "CHANNEL = 'nightly'"
  '';
})
