// The setup file of Sumizuri for Windows. It shows a small window, unpacks the files the setup window needs into a temporary folder, starts the app's own setup from there, unpacks the rest behind the open window, and once the setup has closed it takes the folder away. It installs nothing by itself.
#![windows_subsystem = "windows"]

mod payload;
mod splash;

use std::fs::{self, File};
use std::mem::zeroed;
use std::path::Path;
use std::ptr::null;
use std::thread;
use std::time::Duration;
use windows_sys::Win32::Foundation::{CloseHandle, GetLastError, ERROR_ALREADY_EXISTS, HWND};
use windows_sys::Win32::System::Threading::{CreateMutexW, CreateProcessW, CREATE_NO_WINDOW, PROCESS_INFORMATION, STARTUPINFOW};
use windows_sys::Win32::UI::HiDpi::{SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2};
use windows_sys::Win32::UI::WindowsAndMessaging::ShowWindow;

fn main() {
    if let Err(problem) = run() {
        splash::message(&format!("The setup could not start.\n\n{problem}"));
        std::process::exit(1);
    }
}

// Runs a piece of work away from the window while the window keeps drawing.
fn behind_window<T: Send>(work: impl FnOnce() -> T + Send) -> T {
    thread::scope(|scope| {
        let job = scope.spawn(work);
        while !job.is_finished() {
            splash::wait(None, 15);
        }
        job.join().expect("the unpacking stopped")
    })
}

// Puts one argument on a Windows command line, quoted when it needs to be, in the way programs read it back.
fn quote(arg: &str) -> String {
    if !arg.is_empty() && !arg.contains([' ', '\t', '"']) {
        return arg.to_string();
    }
    let mut out = String::from('"');
    let mut slashes = 0;
    for c in arg.chars() {
        match c {
            '\\' => slashes += 1,
            '"' => {
                out.push_str(&"\\".repeat(slashes * 2 + 1));
                out.push('"');
                slashes = 0;
            }
            _ => {
                out.push_str(&"\\".repeat(slashes));
                slashes = 0;
                out.push(c);
            }
        }
    }
    out.push_str(&"\\".repeat(slashes * 2));
    out.push('"');
    out
}

// The command that starts the setup: Java itself with the arguments the packer wrote and the class archive it made, or the launcher of the app when they are missing.
fn setup_command(payload: &Path, setup: &Path) -> (String, u32) {
    let args = fs::read_to_string(setup.join("setup.args")).unwrap_or_default();
    let mut parts: Vec<String> = args.lines().filter(|it| !it.is_empty()).map(String::from).collect();
    if parts.is_empty() {
        return (quote(&payload.join("Sumizuri.exe").display().to_string()), 0);
    }
    let archive = setup.join("setup.jsa");
    if archive.is_file() {
        parts.insert(0, format!("-XX:SharedArchiveFile={}", archive.display()));
    }
    // The launcher of the app tells Java where it sits, and the setup finds the app it installs from that.
    parts.insert(0, format!("-Djpackage.app-path={}", payload.join("Sumizuri.exe").display()));
    parts.insert(0, payload.join("runtime").join("bin").join("java.exe").display().to_string());
    // Java for Windows is a console program, so it is started without a console window.
    (parts.iter().map(|it| quote(it)).collect::<Vec<_>>().join(" "), CREATE_NO_WINDOW)
}

// Starts the app's own setup and gives back its process. It hides the small window by its handle once its own has drawn.
fn start_setup(payload: &Path, setup: &Path, later: &Path, window: HWND) -> Result<PROCESS_INFORMATION, String> {
    let (program, flags) = setup_command(payload, setup);
    let command = format!("{program} --setup --splash={} {}", window as isize, quote(&format!("--later={}", later.display())));
    let mut command = splash::wide(&command);
    let folder = splash::wide(&payload.display().to_string());
    unsafe {
        let start = STARTUPINFOW { cb: size_of::<STARTUPINFOW>() as u32, ..zeroed() };
        let mut process: PROCESS_INFORMATION = zeroed();
        let started = CreateProcessW(
            null(), command.as_mut_ptr(), null(), null(), 0, flags, null(), folder.as_ptr(), &start, &mut process,
        );
        if started == 0 {
            return Err(format!("Windows could not start the setup (error {}).", GetLastError()));
        }
        CloseHandle(process.hThread);
        Ok(process)
    }
}

fn run() -> Result<(), String> {
    unsafe {
        SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
        // A second copy of the setup, opened while one runs, says so and ends.
        CreateMutexW(null(), 0, splash::wide("SumizuriSetup").as_ptr());
        if GetLastError() == ERROR_ALREADY_EXISTS {
            splash::message("The setup of Sumizuri is already open.");
            return Ok(());
        }
    }
    let me = std::env::current_exe().map_err(|e| e.to_string())?;
    let exe = File::open(&me).map_err(|e| e.to_string())?;
    let entries = payload::read_list(&exe).map_err(|e| e.to_string())?;
    let window = splash::show();
    let root = std::env::temp_dir().join(format!("sumizuri-setup-{}", std::process::id()));
    let _ = fs::remove_dir_all(&root);
    let payload = root.join("payload");
    let later = root.join("later");
    let setup = root.join("setup");
    fs::create_dir_all(&later).map_err(|e| e.to_string())?;
    let result = (|| {
        let first = [(payload::FIRST, payload.as_path()), (payload::SETUP, setup.as_path())];
        behind_window(|| payload::unpack(&exe, &entries, &first)).map_err(|e| e.to_string())?;
        let process = start_setup(&payload, &setup, &later, window)?;
        // The setup waits for one of these files before it copies, and stops with the reason when the rest could not be unpacked.
        let rest = behind_window(|| payload::unpack(&exe, &entries, &[(payload::LATER, later.as_path())]));
        let _ = match &rest {
            Ok(()) => fs::write(root.join("later.ready"), b""),
            Err(problem) => fs::write(root.join("later.failed"), problem.to_string()),
        };
        while !splash::wait(Some(process.hProcess), u32::MAX) {}
        unsafe { CloseHandle(process.hProcess) };
        Ok(())
    })();
    unsafe { ShowWindow(window, 0) };
    // The setup may still let go of its files for a moment after it ends.
    for _ in 0..40 {
        if fs::remove_dir_all(&root).is_ok() || !root.exists() {
            break;
        }
        thread::sleep(Duration::from_millis(250));
    }
    result
}
