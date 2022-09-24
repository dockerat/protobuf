ARG DART_PROTOBUF_VERSION=2.0.1
ARG GOOGLE_API_VERSION=d9b32e92fa57c37e5af0dc03badfe741170c5849
ARG GO_VERSION=1.19.1
ARG GRPC_GATEWAY_VERSION=2.3.0
ARG GRPC_JAVA_VERSION=1.36.0
ARG GRPC_RUST_VERSION=0.8.2
ARG GRPC_SWIFT_VERSION=1.10.0
ARG GRPC_VERSION=1.36.4
ARG GRPC_WEB_VERSION=1.2.1
ARG NODE_VERSION=14.17.5
ARG PROTOBUF_C_VERSION=1.3.3
ARG PROTOC_GEN_DOC_VERSION=1.4.1
ARG PROTOC_GEN_FIELDMASK_VERSION=0.4.5
ARG PROTOC_GEN_GO_GRPC_VERSION=1.36.0
ARG PROTOC_GEN_GO_VERSION=1.5.2
ARG PROTOC_GEN_GOGO_VERSION=1.3.2
ARG PROTOC_GEN_GOGOTTN_VERSION=3.0.14
ARG PROTOC_GEN_GOVALIDATORS_VERSION=0.3.2
ARG PROTOC_GEN_GQL_VERSION=0.8.0
ARG PROTOC_GEN_LINT_VERSION=0.2.1
ARG PROTOC_GEN_VALIDATE_VERSION=0.6.1
ARG RUST_PROTOBUF_VERSION=2.22.1
ARG TS_PROTOC_GEN_VERSION=0.14.0
ARG UPX_VERSION=3.96



FROM alpine:3.16.2 as protoc

RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev linux-headers cmake ninja
RUN mkdir -p /out

ARG GRPC_VERSION
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc \
    && ln -s /grpc/third_party/protobuf /protobuf \
    && mkdir -p /grpc/cmake/build \
    && cd /grpc/cmake/build \
    && cmake -GNinja -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF ../..  \
    && cmake --build . --target plugins \
    && cmake --build . --target install \
    && DEST_DIR=/out cmake --build . --target install

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c \
    && curl -sSL https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xz --strip 1 -C /protobuf-c \
    && cd /protobuf-c \
    && export LD_LIBRARY_PATH=/usr/lib:/usr/lib64 \
    && export PKG_CONFIG_PATH=/usr/lib64/pkgconfig \
    && ./autogen.sh \
    && ./configure --prefix=/usr \
    && make \
    && make install DEST_DIR=/out

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java \
    && curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz --strip 1 -C /grpc-java \
    && cd /grpc-java \
    && g++ -I. -I/usr/include compiler/src/java_plugin/cpp/*.cpp -L/usr/lib64 -lprotoc -lprotobuf -lpthread --std=c++0x -s -o protoc-gen-grpc-java \
    && install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java

ARG GRPC_WEB_VERSION
RUN mkdir -p /grpc-web \
    && curl -sSL https://api.github.com/repos/grpc/grpc-web/tarball/${GRPC_WEB_VERSION} | tar xz --strip 1 -C /grpc-web \
    && cd /grpc-web \
    && make install-plugin \
    && install -Ds /usr/local/bin/protoc-gen-grpc-web /out/usr/bin/protoc-gen-grpc-web



FROM golang:1.19.1-alpine3.16 as golang

RUN apk add --no-cache build-base curl git

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc \
    && curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc \
    && cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc \
    && go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc \
    && install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

ARG PROTOC_GEN_FIELDMASK_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask \
    && curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-fieldmask/tarball/v${PROTOC_GEN_FIELDMASK_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask \
    && cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask \
    && go build -ldflags '-w -s' -o /protoc-gen-fieldmask-out/protoc-gen-fieldmask . \
    && install -Ds /protoc-gen-fieldmask-out/protoc-gen-fieldmask /out/usr/bin/protoc-gen-fieldmask

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go \
    && curl -sSL https://api.github.com/repos/grpc/grpc-go/tarball/v${PROTOC_GEN_GO_GRPC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go \
    && cd ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc \
    && go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go-grpc . \
    && install -Ds /golang-protobuf-out/protoc-gen-go-grpc /out/usr/bin/protoc-gen-go-grpc

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/golang/protobuf \
    && curl -sSL https://api.github.com/repos/golang/protobuf/tarball/v${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/golang/protobuf \
    && cd ${GOPATH}/src/github.com/golang/protobuf \
    && go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./protoc-gen-go \
    && install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GOGO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/gogo/protobuf \
    && curl -sSL https://api.github.com/repos/gogo/protobuf/tarball/v${PROTOC_GEN_GOGO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/gogo/protobuf \
    && cd ${GOPATH}/src/github.com/gogo/protobuf \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gofast ./protoc-gen-gofast \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogo ./protoc-gen-gogo \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofast ./protoc-gen-gogofast \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogofaster ./protoc-gen-gogofaster \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogoslick ./protoc-gen-gogoslick \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogotypes ./protoc-gen-gogotypes \
    && go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gostring ./protoc-gen-gostring \
    && install -D $(find /gogo-protobuf-out -name 'protoc-gen-*') -t /out/usr/bin \
    && mkdir -p /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf \
    && install -D $(find ./protobuf/google/protobuf -name '*.proto') -t /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf \
    && install -D ./gogoproto/gogo.proto /out/usr/include/github.com/gogo/protobuf/gogoproto/gogo.proto

ARG PROTOC_GEN_GOGOTTN_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn \
    && curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-gogottn/tarball/v${PROTOC_GEN_GOGOTTN_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn \
    && cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-gogottn \
    && go build -ldflags '-w -s' -o /protoc-gen-gogottn-out/protoc-gen-gogottn . \
    && install -Ds /protoc-gen-gogottn-out/protoc-gen-gogottn /out/usr/bin/protoc-gen-gogottn

ARG PROTOC_GEN_GOVALIDATORS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/mwitkow/go-proto-validators \
    && curl -sSL https://api.github.com/repos/mwitkow/go-proto-validators/tarball/v${PROTOC_GEN_GOVALIDATORS_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/mwitkow/go-proto-validators \
    && cd ${GOPATH}/src/github.com/mwitkow/go-proto-validators \
    && mkdir /go-proto-validators-out \
    && go build -ldflags '-w -s' -o /go-proto-validators-out ./... \
    && install -Ds /go-proto-validators-out/protoc-gen-govalidators /out/usr/bin/protoc-gen-govalidators \
    && install -D ./validator.proto /out/usr/include/github.com/mwitkow/go-proto-validators/validator.proto

ARG PROTOC_GEN_GQL_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/danielvladco/go-proto-gql \
    && curl -sSL https://api.github.com/repos/danielvladco/go-proto-gql/tarball/v${PROTOC_GEN_GQL_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/danielvladco/go-proto-gql \
    && cd ${GOPATH}/src/github.com/danielvladco/go-proto-gql \
    && go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gql ./protoc-gen-gql \
    && go build -ldflags '-w -s' -o /go-proto-gql-out/protoc-gen-gogql ./protoc-gen-gogql \
    && install -Ds /go-proto-gql-out/protoc-gen-gql /out/usr/bin/protoc-gen-gql \
    && install -Ds /go-proto-gql-out/protoc-gen-gogql /out/usr/bin/protoc-gen-gogql

ARG PROTOC_GEN_LINT_VERSION
RUN cd / \
    && curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_amd64.zip \
    && mkdir -p /protoc-gen-lint-out \
    && cd /protoc-gen-lint-out \
    && unzip -q /protoc-gen-lint_linux_amd64.zip \
    && install -Ds /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate \
    && curl -sSL https://api.github.com/repos/envoyproxy/protoc-gen-validate/tarball/v${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate \
    && cd ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate \
    && go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . \
    && install -Ds /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate \
    && install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway \
    && curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway \
    && cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway \
    && go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway \
    && go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-openapiv2 ./protoc-gen-openapiv2 \
    && install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway \
    && install -Ds /grpc-gateway-out/protoc-gen-openapiv2 /out/usr/bin/protoc-gen-openapiv2 \
    && mkdir -p /out/usr/include/protoc-gen-openapiv2/options \
    && install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options

ARG GOOGLE_API_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/googleapis/googleapis \
    && curl -sSL https://api.github.com/repos/googleapis/googleapis/tarball/${GOOGLE_API_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/googleapis/googleapis \
    && cd ${GOPATH}/src/github.com/googleapis/googleapis \
    && install -D ./google/api/annotations.proto /out/usr/include/google/api/annotations.proto \
    && install -D ./google/api/field_behavior.proto /out/usr/include/google/api/field_behavior.proto \
    && install -D ./google/api/http.proto /out/usr/include/google/api/http.proto \
    && install -D ./google/api/httpbody.proto /out/usr/include/google/api/httpbody.proto



FROM rust:1.64.0-alpine3.16 as rust

RUN apk add --no-cache curl
RUN rustup target add x86_64-unknown-linux-musl

ARG RUST_PROTOBUF_VERSION
RUN mkdir -p /rust-protobuf \
    && curl -sSL https://api.github.com/repos/stepancheg/rust-protobuf/tarball/v${RUST_PROTOBUF_VERSION} | tar xz --strip 1 -C /rust-protobuf \
    && cd /rust-protobuf/protobuf-codegen \
    && cargo build --target=x86_64-unknown-linux-musl --release \
    && install -Ds /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust /out/usr/bin/protoc-gen-rust

ARG GRPC_RUST_VERSION
RUN mkdir -p /grpc-rust \
    && curl -sSL https://api.github.com/repos/stepancheg/grpc-rust/tarball/v${GRPC_RUST_VERSION} | tar xz --strip 1 -C /grpc-rust \
    && cd /grpc-rust/grpc-compiler && cargo build --target=x86_64-unknown-linux-musl --release \
    && install -Ds /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc /out/usr/bin/protoc-gen-rust-grpc



FROM swift:5.7.0 as swift

RUN apt-get update
RUN apt-get install -y unzip patchelf libnghttp2-dev curl libssl-dev zlib1g-dev

ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift \
    && curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift \
    && cd /grpc-swift && make && make plugins \
    && install -Ds /grpc-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swift \
    && install -Ds /grpc-swift/protoc-gen-grpc-swift /protoc-gen-swift/protoc-gen-grpc-swift \
    && cp /lib64/ld-linux-x86-64.so.2 $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-grpc-swift | awk '{print $3}' | grep /lib | sort | uniq) /protoc-gen-swift/ \
    && find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; \
    && for p in protoc-gen-swift protoc-gen-grpc-swift; do patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; done



FROM dart:2.18.1 as dart

RUN apt-get update
RUN apt-get install -y musl-tools curl

ARG DART_PROTOBUF_VERSION
RUN mkdir -p /dart-protobuf \
    && curl -sSL https://api.github.com/repos/google/protobuf.dart/tarball/protobuf-v${DART_PROTOBUF_VERSION} | tar xz --strip 1 -C /dart-protobuf \
    && cd /dart-protobuf/protoc_plugin \
    && pub install \
    && dart2native --verbose bin/protoc_plugin.dart -o protoc_plugin \
    && install -D /dart-protobuf/protoc_plugin/protoc_plugin /out/usr/bin/protoc-gen-dart



FROM alpine:3.16.2 as packer

COPY --from=protoc /out/ /out/
COPY --from=golang /out/ /out/
COPY --from=rust /out/ /out/
COPY --from=swift /protoc-gen-swift /out/protoc-gen-swift
COPY --from=dart /out/ /out/

ARG UPX_VERSION
RUN apk add --no-cache curl \
    && mkdir -p /upx \
    && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx \
    && install -D /upx/upx /usr/local/bin/upx \
    \
    \
    \
    && upx --lzma $(find /out/usr/bin/ -type f -name 'grpc_*' \
        -not -name 'grpc_csharp_plugin' \
        -not -name 'grpc_node_plugin' \
        -not -name 'grpc_php_plugin' \
        -not -name 'grpc_ruby_plugin' \
        -not -name 'grpc_python_plugin' \
        -or -name 'protoc-gen-*' \
        -not -name 'protoc-gen-dart' \
    ) \
    && find /out -name "*.a" -delete -or -name "*.la" -delete





# 打包真正的镜像
FROM storezhang/alpine:3.16.2


LABEL author="storezhang<华寅>" \
    email="storezhang@gmail.com" \
    qq="160290688" \
    wechat="storezhang" \
    description="Protobuf镜像，集成常见语言及插件"



# 复制文件
COPY --from=packer /out/ /
COPY protobuf /usr/bin/protobuf



RUN set -ex \
    \
    \
    \
    && apk add --no-cache npm libstdc++ \
    \
    \
    \
    # 增加Typescript支持 \
    && npm install -g ts-protoc-gen@${TS_PROTOC_GEN_VERSION} \
    && npm cache clean --force \
    # 修复Dart编译时的密钥问题
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk \
    && apk add glibc-2.31-r0.apk  \
    && for p in protoc-gen-swift protoc-gen-swiftgrpc; do ln -s /protoc-gen-swift/${p} /usr/bin/${p}; done \
    \
    \
    \
    # 给各种语言增加快捷方式
    && ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp \
    && ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp \
    && ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/protoc-gen-grpc-objc \
    && ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js \
    && ln -s /usr/bin/grpc_php_plugin /usr/bin/protoc-gen-grpc-php \
    && ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python \
    && ln -s /usr/bin/grpc_ruby_plugin /usr/bin/protoc-gen-grpc-ruby \
    && ln -s /usr/bin/protoc-gen-swiftgrpc /usr/bin/protoc-gen-grpc-swift \
    && ln -s /usr/local/lib/node_modules/ts-protoc-gen/bin/protoc-gen-ts /usr/bin/protoc-gen-ts \
    \
    \
    \
    # 增加执行权限
    && chmod +x /usr/bin/protobuf \
    \
    \
    \
    && rm -rf /var/cache/apk/*



ENTRYPOINT ["protobuf", "-I/usr/include"]
