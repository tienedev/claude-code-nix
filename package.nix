{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
  procps,
  ripgrep,
  bubblewrap,
  socat,
}:

let
  version = "2.1.167";

  platformMap = {
    x86_64-linux = { suffix = "linux-x64"; hash = "sha256-1tKZW/yj+FOdnpqlE/9Dw9qg1VbW0a8Hxt9oHgUOUiw="; };
    aarch64-linux = { suffix = "linux-arm64"; hash = "sha256-uPOD3x3KVX3I+4F+TnYzVjn5SgqMe4A8ovWu8S03Pwk="; };
    x86_64-darwin = { suffix = "darwin-x64"; hash = "sha256-pQh5d77pXKhFmMi5QPxoFlxElyKrQQ20X2ENFI6cLQ4="; };
    aarch64-darwin = { suffix = "darwin-arm64"; hash = "sha256-+zy+kgCz7rp64G7kP9tLSysjHV+oBA0OR5VKfzdNFTA="; };
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  distBase = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${distBase}/${version}/${platform.suffix}/claude";
    hash = platform.hash;
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [ makeBinaryWrapper ]
    ++ lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 $src $out/bin/.claude-unwrapped
    makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${lib.makeBinPath (
        [ procps ripgrep ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap socat ]
      )}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code — AI coding assistant in your terminal";
    homepage = "https://www.anthropic.com/claude-code";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "claude";
  };
}
