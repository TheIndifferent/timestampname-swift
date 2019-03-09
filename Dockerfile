## docker build -t timestampname .
## docker run --rm -it -v "$(pwd)":"$(pwd)" -w "$(pwd)" timestampname -dry
FROM ubuntu:18.04 as build

RUN apt-get update \
    && apt-get install -y -qq curl libatomic1 libedit2 libicu60 libxml2 libbsd0 clang \
    && rm -rf /var/lib/apt/lists/*
RUN curl 'https://swift.org/builds/swift-4.2.3-release/ubuntu1804/swift-4.2.3-RELEASE/swift-4.2.3-RELEASE-ubuntu18.04.tar.gz' \
    | tar -xz --strip-components=1
WORKDIR /build
COPY Sources /build/Sources/
COPY Package.swift /build/
RUN swift build -c release -Xswiftc -O -Xswiftc -whole-module-optimization


FROM ubuntu:18.04
RUN cd /usr/share && du -h --summarize *
RUN apt-get update \
    && apt-get install -y libcurl4 libatomic1 libedit2 libicu60 libxml2 libbsd0 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/lib/swift/linux/*.so /usr/lib/swift/linux/
COPY --from=build /build/.build/x86_64-unknown-linux/release/TimestampName /TimestampName
ENTRYPOINT ["/TimestampName"]
