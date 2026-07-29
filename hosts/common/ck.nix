{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  onnxruntime,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "ck-search";
  version = "0.7.11";

  src = fetchFromGitHub {
    owner = "BeaconBay";
    repo = "ck";
    rev = version;
    hash = "sha256-YZ5zswjTvst6Ee5arJPKzz9BDIIXf/pHuQ6QB+qZ9kc=";
  };

  cargoHash = "sha256-sv7wTFN5eA7HWOE+syDGLtwcV/pvUmqyO8Cb0n5ldgE=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    onnxruntime
    openssl
  ];

  # The `ort` crate (via fastembed) downloads a prebuilt onnxruntime by
  # default, which the sandbox blocks. Point it at the nixpkgs library and
  # link dynamically: ort-sys otherwise looks for a static .a (nixpkgs
  # ships only the .so). The nix ld wrapper bakes the RPATH from the -L
  # search path, so the runtime dlopen resolves without ORT_DYLIB_PATH.
  env = {
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
  };

  # Tests exercise embedding models fetched from HuggingFace at runtime.
  doCheck = false;

  meta = {
    description = "Semantic code search that combines grep with embeddings";
    homepage = "https://github.com/BeaconBay/ck";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "ck";
  };
}
