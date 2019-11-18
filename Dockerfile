FROM ubuntu:16.04

RUN mkdir /app
WORKDIR /app
COPY . /app

# Prepare the custom package location
RUN apt-get update && apt-get install --no-install-recommends --yes git gnupg devscripts equivs
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83
ENV DISTRO=xenial
RUN echo "# Kurento Media Server - Nightly packages" >> /etc/apt/sources.list.d/kurento.list
RUN echo "deb [arch=amd64] http://ubuntu.openvidu.io/dev xenial kms6" >> /etc/apt/sources.list.d/kurento.list
RUN apt-get update

# Clone KMS
RUN git config --global http.sslVerify false
RUN git clone https://github.com/Kurento/kms-omni-build.git
WORKDIR /app/kms-omni-build
RUN git submodule update --init --recursive
RUN git submodule update --remote
RUN git checkout 6.11.0
RUN git submodule foreach "git checkout 6.11.0 || true"

# Install all build dependencies
RUN cp ../build-dependencies.sh ./
RUN /bin/bash build-dependencies.sh

# We build a custom gstreamer gst-plugin-bad
WORKDIR /app/
RUN git clone https://github.com/samhumeau/gst-plugins-bad.git
WORKDIR /app/gst-plugins-bad
RUN mk-build-deps --install --remove  --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' "./debian/control"

# now we build libgstbad ...
RUN ./autogen.sh  --enable-gtk-doc --enable-orc --with-cuda-prefix=/usr/local/cuda
RUN make -j8
RUN make install

# Erase libgstbad with the new ones
RUN cp /usr/local/lib/* /usr/lib/x86_64-linux-gnu/ -r
RUN cp /usr/local/lib/gstreamer-1.5/* /usr/lib/x86_64-linux-gnu/gstreamer-1.5/ -r

# build kms
WORKDIR /app/kms-omni-build/
RUN mkdir build-Release
WORKDIR /app/kms-omni-build/build-Release
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
ENV MAKEFLAGS="-j8"
RUN make
WORKDIR /app/kms-omni-build/build-Release
COPY ./entrypoint.sh ./entrypoint.sh
EXPOSE 8888
ENV GST_DEBUG="3,Kurento*:4,kms*:4,sdp*:4,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4"
CMD ["/bin/bash", "./entrypoint.sh"]
