#!/usr/bin/env bash
# Public build recipe for separately executed FFmpeg/FFprobe; no ClipKeep application source.
set -euo pipefail
ROOT="$PWD"
PREFIX="$ROOT/build/prefix"
OUT="$ROOT/engine-output"
mkdir -p "$PREFIX" "$OUT/bin" "$OUT/corresponding-source" "$OUT/licenses"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export CFLAGS='-O2'
export CXXFLAGS='-O2'
export LDFLAGS='-static -static-libgcc -static-libstdc++'
JOBS=4
checkout_source() {
  local name="$1" url="$2" rev="$3"
  git init "build/$name"
  git -C "build/$name" remote add origin "$url"
  git -C "build/$name" fetch --depth 1 origin "$rev"
  git -C "build/$name" checkout --detach FETCH_HEAD
  test "$(git -C "build/$name" rev-parse HEAD)" = "$rev"
  printf '%s %s %s\n' "$name" "$rev" "$url" >> "$OUT/corresponding-source/REVISIONS.txt"
}
checkout_source ffmpeg https://github.com/FFmpeg/FFmpeg.git 946fcce07b6dcd0331c8cc609192aeff5e1924f8
checkout_source x264 https://code.videolan.org/videolan/x264.git b35605ace3ddf7c1a5d67a2eb553f034aef41d55
checkout_source zimg https://github.com/sekrit-twc/zimg.git f819b14e8f39d1282400b0d9543e8ef73c1b2bbd
git -C build/zimg submodule update --init --depth 1 graphengine
git -C build/zimg submodule status >> "$OUT/corresponding-source/REVISIONS.txt"
checkout_source zlib https://github.com/madler/zlib.git 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf
# The pinned dav1d revision below is resolved from the upstream 1.5.2 release.
checkout_source dav1d https://code.videolan.org/videolan/dav1d.git c720f4d3556a01916324aea155555d3efba842e8
# Archive pristine sources, including graphengine, before generating configure/build output.
for name in ffmpeg x264 zimg zlib dav1d; do
  tar --exclude=.git -cJf "$OUT/corresponding-source/$name.tar.xz" -C build "$name"
done
cp engine/build.sh "$OUT/corresponding-source/"
cp .github/workflows/engine.yml "$OUT/corresponding-source/"
pacman -Q > "$OUT/corresponding-source/BUILD-ENVIRONMENT.txt"
cp build/ffmpeg/COPYING.GPLv3 "$OUT/bin/FFmpeg-LICENSE.txt"
cp build/x264/COPYING "$OUT/licenses/x264-COPYING.txt"
cp build/zimg/COPYING "$OUT/licenses/zimg-COPYING.txt"
cp build/zlib/LICENSE "$OUT/licenses/zlib-LICENSE.txt"
cp build/dav1d/COPYING "$OUT/licenses/dav1d-COPYING.txt"
for lib in gcc-libs winpthreads; do
  if test -d "/mingw64/share/licenses/$lib"; then cp -r "/mingw64/share/licenses/$lib" "$OUT/licenses/"; fi
done
(cd build/zlib && make -f win32/Makefile.gcc -j"$JOBS" libz.a)
mkdir -p "$PREFIX/include" "$PREFIX/lib/pkgconfig"
cp build/zlib/zlib.h build/zlib/zconf.h "$PREFIX/include/"
cp build/zlib/libz.a "$PREFIX/lib/"
cat > "$PREFIX/lib/pkgconfig/zlib.pc" <<PC
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: zlib
Description: zlib
Version: 1.3.1
Libs: -L\${libdir} -lz
Cflags: -I\${includedir}
PC
(cd build/x264 && ./configure --prefix="$PREFIX" --host=x86_64-w64-mingw32 --enable-static --disable-cli --disable-opencl && make -j"$JOBS" && make install)
(cd build/zimg && ./autogen.sh && ./configure --prefix="$PREFIX" --disable-shared --enable-static && make -j"$JOBS" && make install)
(cd build/dav1d && meson setup out --prefix="$PREFIX" --default-library=static --buildtype=release -Denable_tools=false -Denable_tests=false && ninja -C out && ninja -C out install)
(cd build/ffmpeg && ./configure --prefix="$PREFIX" --arch=x86_64 --target-os=mingw32 --disable-autodetect --enable-gpl --enable-version3 --enable-libx264 --enable-libzimg --enable-libdav1d --enable-zlib --enable-static --disable-shared --disable-doc --disable-debug --disable-ffplay --disable-network --enable-w32threads --pkg-config-flags=--static --extra-cflags="-I$PREFIX/include" --extra-ldflags="-L$PREFIX/lib -static -static-libgcc -static-libstdc++" --extra-libs='-lstdc++ -lpthread' && make -j"$JOBS" && make install)
cp "$PREFIX/bin/ffmpeg.exe" "$PREFIX/bin/ffprobe.exe" "$OUT/bin/"
ffmpeg -version > "$OUT/bin/FFmpeg-BUILD-README.txt"
ffmpeg -buildconf >> "$OUT/bin/FFmpeg-BUILD-README.txt" 2>&1
for exe in "$OUT/bin/"*.exe; do objdump -p "$exe" | sed -n '/DLL Name/p'; done > "$OUT/DLL-DEPENDENCIES.txt"
if grep -Ei 'libgcc|libstdc|libwinpthread|msys-2|zlib|libzimg|libdav1d|libx264' "$OUT/DLL-DEPENDENCIES.txt"; then echo 'Unexpected non-system DLL dependency'; exit 1; fi
mkdir -p build/smoke
ffmpeg -v error -f lavfi -i testsrc2=s=320x180:r=24 -f lavfi -i anullsrc=cl=5.1:r=48000 -t 4 -c:v libx264 -g 24 -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 -color_range tv -c:a flac build/smoke/input.mkv
ffmpeg -v error -ss 1 -i build/smoke/input.mkv -t 2 -c:v copy -c:a aac -b:a 512k -movflags +faststart build/smoke/copy.mp4
ffmpeg -v error -i build/smoke/input.mkv -frames:v 1 -vf format=rgba build/smoke/sticker.png
ffmpeg -v error -i build/smoke/input.mkv -i build/smoke/sticker.png -filter_complex '[0:v][1:v]overlay=0:0' -t 1 -c:v libx264 -c:a aac build/smoke/overlay.mp4
ffmpeg -v error -i build/smoke/input.mkv -map 0:v -t 1 -vf 'zscale=pin=bt709:tin=bt709:min=bt709:rin=limited:p=bt2020:t=smpte2084:m=bt2020nc:r=limited,format=yuv420p10le' -c:v ffv1 build/smoke/hdr.mkv
ffmpeg -v error -i build/smoke/hdr.mkv -vf 'zscale=pin=bt2020:tin=smpte2084:min=bt2020nc:rin=limited:p=bt2020:t=linear:m=gbr:r=full:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=mobius:param=0.3:desat=2,zscale=t=bt709:m=bt709:r=limited,format=yuv420p' -c:v libx264 build/smoke/sdr.mp4
ffmpeg -v error -ss 1 -i build/smoke/input.mkv -map 0:a -t 1 -af aresample=8000:async=1:first_pts=0 -c:a pcm_f32le -f f32le build/smoke/wave.f32
for name in copy overlay sdr; do
  ffmpeg -v error -xerror -i "build/smoke/$name.mp4" -f null -
  ffprobe -v error -show_streams -show_format -of json "build/smoke/$name.mp4" > "$OUT/$name-probe.json"
done
printf 'Windows native engine smoke passed: stream copy, 5.1 AAC, PNG overlay, PQ tone mapping, PCM waveform, full decode.\n' > "$OUT/WINDOWS-ENGINE-TESTS.txt"
(cd "$OUT" && find bin corresponding-source licenses -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
