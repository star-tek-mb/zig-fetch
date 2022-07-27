// https://github.com/mattnite/zig-mbedtls

const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

pub const Library = struct {
    step: *LibExeObjStep,

    pub fn link(self: Library, other: *LibExeObjStep) void {
        other.addIncludeDir(include_dir);
        other.linkLibrary(self.step);
    }
};

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";
pub const include_dir = root_path ++ "mbedtls/include";
const library_include = root_path ++ "mbedtls/library";

pub fn create(b: *Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) Library {
    const ret = b.addStaticLibrary("mbedtls", null);

    ret.setTarget(target);
    ret.setBuildMode(mode);
    ret.addIncludeDir(include_dir);
    ret.addIncludeDir(library_include);
    ret.addCSourceFiles(srcs, &.{"-Os"});
    ret.linkLibC();

    if (target.isWindows()) {
        ret.linkSystemLibrary("ws2_32");
    }

    return Library{ .step = ret };
}

const srcs = &.{
    library_include ++ "/aes.c",
    library_include ++ "/aesni.c",
    library_include ++ "/aria.c",
    library_include ++ "/asn1parse.c",
    library_include ++ "/asn1write.c",
    library_include ++ "/base64.c",
    library_include ++ "/bignum.c",
    library_include ++ "/camellia.c",
    library_include ++ "/ccm.c",
    library_include ++ "/chacha20.c",
    library_include ++ "/chachapoly.c",
    library_include ++ "/cipher.c",
    library_include ++ "/cipher_wrap.c",
    library_include ++ "/constant_time.c",
    library_include ++ "/cmac.c",
    library_include ++ "/ctr_drbg.c",
    library_include ++ "/des.c",
    library_include ++ "/dhm.c",
    library_include ++ "/ecdh.c",
    library_include ++ "/ecdsa.c",
    library_include ++ "/ecjpake.c",
    library_include ++ "/ecp.c",
    library_include ++ "/ecp_curves.c",
    library_include ++ "/entropy.c",
    library_include ++ "/entropy_poll.c",
    library_include ++ "/error.c",
    library_include ++ "/gcm.c",
    library_include ++ "/hkdf.c",
    library_include ++ "/hmac_drbg.c",
    library_include ++ "/md.c",
    library_include ++ "/md5.c",
    library_include ++ "/memory_buffer_alloc.c",
    library_include ++ "/mps_reader.c",
    library_include ++ "/mps_trace.c",
    library_include ++ "/nist_kw.c",
    library_include ++ "/oid.c",
    library_include ++ "/padlock.c",
    library_include ++ "/pem.c",
    library_include ++ "/pk.c",
    library_include ++ "/pk_wrap.c",
    library_include ++ "/pkcs12.c",
    library_include ++ "/pkcs5.c",
    library_include ++ "/pkparse.c",
    library_include ++ "/pkwrite.c",
    library_include ++ "/platform.c",
    library_include ++ "/platform_util.c",
    library_include ++ "/poly1305.c",
    library_include ++ "/psa_crypto.c",
    library_include ++ "/psa_crypto_aead.c",
    library_include ++ "/psa_crypto_cipher.c",
    library_include ++ "/psa_crypto_client.c",
    library_include ++ "/psa_crypto_driver_wrappers.c",
    library_include ++ "/psa_crypto_ecp.c",
    library_include ++ "/psa_crypto_hash.c",
    library_include ++ "/psa_crypto_mac.c",
    library_include ++ "/psa_crypto_rsa.c",
    library_include ++ "/psa_crypto_se.c",
    library_include ++ "/psa_crypto_slot_management.c",
    library_include ++ "/psa_crypto_storage.c",
    library_include ++ "/psa_its_file.c",
    library_include ++ "/ripemd160.c",
    library_include ++ "/rsa.c",
    library_include ++ "/rsa_alt_helpers.c",
    library_include ++ "/sha1.c",
    library_include ++ "/sha256.c",
    library_include ++ "/sha512.c",
    library_include ++ "/ssl_debug_helpers_generated.c",
    library_include ++ "/threading.c",
    library_include ++ "/timing.c",
    library_include ++ "/version.c",
    library_include ++ "/version_features.c",
    library_include ++ "/x509.c",
    library_include ++ "/x509_create.c",
    library_include ++ "/x509_crl.c",
    library_include ++ "/x509_crt.c",
    library_include ++ "/x509_csr.c",
    library_include ++ "/x509write_crt.c",
    library_include ++ "/x509write_csr.c",
    library_include ++ "/debug.c",
    library_include ++ "/net_sockets.c",
    library_include ++ "/ssl_cache.c",
    library_include ++ "/ssl_ciphersuites.c",
    library_include ++ "/ssl_client.c",
    library_include ++ "/ssl_cookie.c",
    library_include ++ "/ssl_msg.c",
    library_include ++ "/ssl_ticket.c",
    library_include ++ "/ssl_tls.c",
    library_include ++ "/ssl_tls12_client.c",
    library_include ++ "/ssl_tls12_server.c",
    library_include ++ "/ssl_tls13_keys.c",
    library_include ++ "/ssl_tls13_server.c",
    library_include ++ "/ssl_tls13_client.c",
    library_include ++ "/ssl_tls13_generic.c",
};
