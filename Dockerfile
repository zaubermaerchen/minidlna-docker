FROM alpine:3.18 AS build

ARG minidlna_version="1.3.3"
ARG ffmpeg_version="6.0"
ARG ffmpegthumbnailer_version="2.2.2"

ADD patch/ /tmp/patch

RUN mkdir /usr/local/src

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
RUN apk add --update \
  autoconf \
  automake \
  bsd-compat-headers \
  build-base \
  coreutils \
  cmake \
  fdk-aac-dev \
  flac-dev \
  freetype-dev \
  gcc \
  gettext-dev \
  git \
  jpeg-dev \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libexif-dev \
  libid3tag-dev \
  libpng-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  openssl-dev \
  opus-dev \
  pkgconf \
  pkgconfig \
  rtmpdump-dev \
  sqlite-dev \
  tar \
  wget \
  x264-dev \
  x265-dev \
  yasm && \
  rm -rf /var/cache/apk/*

RUN cd /usr/local/src && \
  wget https://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.gz && \
  tar zxf ffmpeg-${ffmpeg_version}.tar.gz && \
  cd /usr/local/src/ffmpeg-${ffmpeg_version} && \
  ./configure \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  --enable-libfreetype \
  --enable-openssl \
  --enable-shared \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" &&  \
  make && make install && make distclean

RUN cd /usr/local/src && \
  wget https://github.com/dirkvdb/ffmpegthumbnailer/releases/download/${ffmpegthumbnailer_version}/ffmpegthumbnailer-${ffmpegthumbnailer_version}.tar.bz2 && \
  tar xf ffmpegthumbnailer-${ffmpegthumbnailer_version}.tar.bz2 && \
  cd /usr/local/src/ffmpegthumbnailer-${ffmpegthumbnailer_version} && \
  wget -O /tmp/patch/ffmpegthumbnailer-ffmpeg6.patch https://github.com/dirkvdb/ffmpegthumbnailer/files/11408666/ffmpegthumbnailer-ffmpeg6.patch.txt && \
  patch -p1 < /tmp/patch/ffmpegthumbnailer-ffmpeg6.patch && \
  cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GIO=ON -DENABLE_THUMBNAILER=ON . && \
  make && make install

RUN cd /usr/local/src && \
  wget https://jaist.dl.sourceforge.net/project/minidlna/minidlna/${minidlna_version}/minidlna-${minidlna_version}.tar.gz && \
  tar xf minidlna-${minidlna_version}.tar.gz && \
  cd /usr/local/src/minidlna-${minidlna_version} && \
  wget -O /tmp/patch/minidlna-1.2.1-cover-resize.patch  https://gist.githubusercontent.com/grigorye/d30bbed518226e44a18eec75f6f6159e/raw/78a5e3261cc6c88bbf901cd1adac26ec6b2f978b/minidlna-1.2.1-cover-resize.patch && \
  patch < /tmp/patch/minidlna-1.2.1-cover-resize.patch && \
  patch < /tmp/patch/thumbnail_creation.patch && \
  ./autogen.sh && ./configure --enable-thumbnail && \
  make && make install && make distclean && \
  cp /usr/local/src/minidlna-${minidlna_version}/minidlna.conf /etc/minidlna.conf

FROM alpine:3.18

RUN apk add --update \
  ca-certificates \
  fdk-aac \
  flac \
  gettext \
  jpeg \
  lame \
  lame-dev \
  libexif \
  libid3tag \
  libpng \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  openssl \
  opus \
  pcre \
  sqlite-dev \
  rtmpdump \
  x264-dev \
  x265-dev && \
  rm -rf /var/cache/apk/*

COPY --from=build /usr/local/bin/* /usr/local/bin/
COPY --from=build /usr/local/share/ffmpeg /usr/local/share/ffmpeg
COPY --from=build /usr/local/lib/lib* /usr/local/lib/
COPY --from=build /usr/local/lib/pkgconfig/* /usr/local/lib/pkgconfig/
COPY --from=build /usr/local/include/libavcodec /usr/local/include/libavcodec
COPY --from=build /usr/local/include/libavdevice /usr/local/include/libavdevice
COPY --from=build /usr/local/include/libavfilter /usr/local/include/libavfilter
COPY --from=build /usr/local/include/libavformat /usr/local/include/libavformat
COPY --from=build /usr/local/include/libavutil /usr/local/include/libavutil
COPY --from=build /usr/local/include/libpostproc /usr/local/include/libpostproc
COPY --from=build /usr/local/include/libswresample /usr/local/include/libswresample
COPY --from=build /usr/local/include/libswscale /usr/local/include/libswscale
COPY --from=build /usr/local/include/libffmpegthumbnailer /usr/local/include/libffmpegthumbnailer
COPY --from=build /usr/local/share/man/man1/ffmpegthumbnailer.1 /usr/local/share/man/man1/ffmpegthumbnailer.1
COPY --from=build /usr/local/share/thumbnailers/ffmpegthumbnailer.thumbnailer /usr/local/share/thumbnailers/ffmpegthumbnailer.thumbnailer

COPY --from=build /usr/local/sbin/minidlnad /usr/local/sbin/
COPY --from=build /etc/minidlna.conf /etc/minidlna.conf
COPY --from=build /usr/local/share/locale/da/LC_MESSAGES/minidlna.mo /usr/local/share/locale/da/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/de/LC_MESSAGES/minidlna.mo /usr/local/share/locale/de/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/es/LC_MESSAGES/minidlna.mo /usr/local/share/locale/es/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/fr/LC_MESSAGES/minidlna.mo /usr/local/share/locale/fr/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/it/LC_MESSAGES/minidlna.mo /usr/local/share/locale/it/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/ja/LC_MESSAGES/minidlna.mo /usr/local/share/locale/ja/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/ko/LC_MESSAGES/minidlna.mo /usr/local/share/locale/ko/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/nb/LC_MESSAGES/minidlna.mo /usr/local/share/locale/nb/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/nl/LC_MESSAGES/minidlna.mo /usr/local/share/locale/nl/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/pl/LC_MESSAGES/minidlna.mo /usr/local/share/locale/pl/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/ru/LC_MESSAGES/minidlna.mo /usr/local/share/locale/ru/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/sl/LC_MESSAGES/minidlna.mo /usr/local/share/locale/sl/LC_MESSAGES/minidlna.mo
COPY --from=build /usr/local/share/locale/sv/LC_MESSAGES/minidlna.mo /usr/local/share/locale/sv/LC_MESSAGES/minidlna.mo

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 1900/udp
EXPOSE 8200
CMD ["minidlnad", "-d", "-R"]
