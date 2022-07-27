# Purpose

Make fetch like api available to zig

# Prerequisites

Install mbedtls

```
git clone https://github.com/Mbed-TLS/mbedtls -b v3.2.1 --single-branch --depth 1
```

# TODO

- Find a way to integrate with std.event.Loop and async code. Support both async and blocking mode.

- Polish API

- Write some tests

# Credits

https://github.com/MasterQ32/zig-uri - for parsing URL

https://github.com/mattnite/zig-mbedtls - for build script

curl ca-certificates - cacert.pem embedding
