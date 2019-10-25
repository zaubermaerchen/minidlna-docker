FROM zaubermaerchen/ffmpeg AS build

ARG ffmpegthumbnailer_version="2.2.2"

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/local/lib64

RUN apk add --update \
  autoconf \
  automake \
  bsd-compat-headers \
  build-base \
  cmake \
  flac-dev \
  gcc \
  gettext-dev \
  git \
  jpeg-dev \
  sqlite-dev \
  tar \
  libexif-dev \
  libid3tag-dev \
  libpng-dev \
  libvorbis-dev && \
  rm -rf /var/cache/apk/*

RUN mkdir /usr/local/src

RUN cd /usr/local/src && \
  wget https://github.com/dirkvdb/ffmpegthumbnailer/releases/download/${ffmpegthumbnailer_version}/ffmpegthumbnailer-${ffmpegthumbnailer_version}.tar.bz2 && \
  tar xf ffmpegthumbnailer-${ffmpegthumbnailer_version}.tar.bz2 && \
  cd /usr/local/src/ffmpegthumbnailer-${ffmpegthumbnailer_version} && \
  cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GIO=ON -DENABLE_THUMBNAILER=ON . && \
  make && make install

RUN cd /usr/local/src && \
  git clone https://github.com/mattn/minidlna-git.git && \
  cd /usr/local/src/minidlna-git && \
  ./autogen.sh && ./configure --enable-thumbnail && \
  make && make install && make distclean

FROM zaubermaerchen/ffmpeg

RUN apk add --update \
  flac \
  gettext \
  jpeg \
  sqlite-dev \
  libexif \
  libid3tag \
  libpng \
  libvorbis && \
  rm -rf /var/cache/apk/*

COPY --from=build /usr/local/bin/ffmpegthumbnailer /usr/local/bin/
COPY --from=build /usr/local/lib64/libffmpegthumbnailer.* /usr/local/lib64/
COPY --from=build /usr/local/include/libffmpegthumbnailer /usr/local/include/libffmpegthumbnailer
COPY --from=build /usr/local/share/man/man1/ffmpegthumbnailer.1 /usr/local/share/man/man1/ffmpegthumbnailer.1
COPY --from=build /usr/local/share/thumbnailers/ffmpegthumbnailer.thumbnailer /usr/local/share/thumbnailers/ffmpegthumbnailer.thumbnailer

COPY --from=build /usr/local/sbin/minidlnad /usr/local/sbin/
COPY --from=build /usr/local/src/minidlna-git/minidlna.conf /etc/minidlna.conf 
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

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 1900/udp
EXPOSE 8200
CMD ["minidlnad", "-d", "-R"]