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
  version = "2.1.118";

  platformMap = {
    x86_64-linux = { suffix = "linux-x64"; hash = "sha256-ujY7JBCkcSDS1Ljs4uEf4LvF1ZrbEyno+4fqDzcPTkY="; };
    aarch64-linux = { suffix = "linux-arm64"; hash = "sha256-t3si/pPBVAnzxkvmeVD+EeX8F9HNMniRWWy4fdm+BJI="; };
    x86_64-darwin = { suffix = "darwin-x64"; hash = "sha256-LNVUBw8FiN4F6e/YjB8HN3DLYg7T5fRbp9+DP8NBTBs="; };
    aarch64-darwin = { suffix = "darwin-arm64"; hash = "sha256-VOXT9lEJuJxgRvR0QJRNUpBsZi0eUXSPYgpDDSatNmU="; };
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
