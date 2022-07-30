# Purpose

Make fetch like api available to zig

Experiment with various web APIs. Make a wrapper of Telegram Bot API.

# Prerequisites

Install mbedtls

```
git clone https://github.com/Mbed-TLS/mbedtls -b v3.2.1 --single-branch --depth 1
```

# For usage

See src/main.zig file

# TODO

- Find a way to integrate with std.event.Loop and async code. Support both async and blocking mode.

- Polish API

- Write some tests

# Credits

mbedTLS - for TLS (HTTPS protocol)

https://github.com/MasterQ32/zig-uri - for parsing URL

https://github.com/mattnite/zig-mbedtls - for build script

curl ca-certificates - cacert.pem embedding
