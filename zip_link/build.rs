fn main() {
    cc::Build::new()
        .file("src/wstp_stubs.c")
        .compile("wstp_stubs");
}
