{ lib, stdenv, fetchFromGitHub, libX11 }:

stdenv.mkDerivation rec {
  pname = "sowm";
  version = "unstable-2024-06-01";

  src = fetchFromGitHub {
    owner = "dylanaraps";
    repo = "sowm";
    rev = "f4cb48d7afeda195a73ff2bfdd3f85a016d53cec"; # latest master tại thời điểm viết, đã pin cụ thể
    # QUAN TRỌNG: hash bên dưới là placeholder (lib.fakeHash).
    # Nix KHÔNG cho phép tự "đoán" hash NAR — cách chính xác duy nhất là để Nix build
    # thất bại lần đầu và nó sẽ tự in ra hash thật (SRI, dạng "sha256-....").
    # Quy trình:
    #   1. nixos-rebuild switch --flake .#fastnix
    #   2. Build sẽ báo lỗi "hash mismatch", copy dòng "got: sha256-..."
    #   3. Dán giá trị đó thay cho lib.fakeHash bên dưới rồi build lại.
    hash = lib.fakeHash;
  };

  buildInputs = [ libX11 ];

  # sowm chỉ có 1 file main.c + Makefile tối giản (không config.h theo kiểu suckless khác,
  # patch trực tiếp source nếu muốn đổi keybind/modkey).
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp sowm $out/bin/sowm
    runHook postInstall
  '';

  meta = with lib; {
    description = "A stacking window manager, written in about 600 lines";
    homepage = "https://github.com/dylanaraps/sowm";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "sowm";
  };
}
