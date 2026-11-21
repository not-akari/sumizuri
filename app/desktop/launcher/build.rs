// The icon and the version of the setup file. The resource compiler comes with Visual Studio, so a build with the GNU tools goes without them.
fn main() {
    println!("cargo:rerun-if-changed=setup.rc");
    println!("cargo:rerun-if-env-changed=SUMIZURI_VERSION");
    if std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("msvc") {
        let version = std::env::var("SUMIZURI_VERSION").unwrap_or_else(|_| "0.0.0".into());
        let numbers: Vec<String> = version.split(['.', '-']).take(3).map(|it| it.parse::<u32>().unwrap_or(0).to_string()).collect();
        let defines = [format!("VERSION_TEXT=\\\"{version}\\\""), format!("VERSION_NUMBERS={},0", numbers.join(","))];
        embed_resource::compile("setup.rc", defines.iter()).manifest_optional().unwrap();
    } else {
        println!("cargo:warning=No resource compiler here, so the setup file has no icon or version.");
    }
}
