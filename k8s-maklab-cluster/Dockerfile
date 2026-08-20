# Custom k3s image for longhorn support

FROM alpine:3.21 AS builder
RUN apk add --no-cache open-iscsi

FROM rancher/k3s:v1.35.1-k3s1
# iscsi binaries
COPY --from=builder /usr/sbin/iscsiadm /usr/sbin/iscsiadm
COPY --from=builder /usr/sbin/iscsid /usr/sbin/iscsid
COPY --from=builder /usr/sbin/iscsistart /usr/sbin/iscsistart

# Dynamic linker (musl)
COPY --from=builder /lib/ld-musl-aarch64.so.1 /lib/ld-musl-aarch64.so.1

# Shared libraries needed by iscsiadm (from ldd)
COPY --from=builder /usr/lib/libopeniscsiusr.so.0 /usr/lib/libopeniscsiusr.so.0
COPY --from=builder /usr/lib/libkmod.so.2 /usr/lib/libkmod.so.2
COPY --from=builder /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=builder /usr/lib/libmount.so.1 /usr/lib/libmount.so.1
COPY --from=builder /usr/lib/libisns.so.0 /usr/lib/libisns.so.0
COPY --from=builder /usr/lib/libzstd.so.1 /usr/lib/libzstd.so.1
COPY --from=builder /usr/lib/liblzma.so.5 /usr/lib/liblzma.so.5
COPY --from=builder /usr/lib/libz.so.1 /usr/lib/libz.so.1
COPY --from=builder /usr/lib/libblkid.so.1 /usr/lib/libblkid.so.1
COPY --from=builder /usr/lib/libeconf.so.0 /usr/lib/libeconf.so.0
