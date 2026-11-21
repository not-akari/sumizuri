// The small window shown while the app unpacks: the logo, the name and a line that the setup is getting ready, in the light or dark of Windows.

use std::mem::zeroed;
use std::ptr::{null, null_mut};
use std::sync::OnceLock;
use windows_sys::Win32::Foundation::{HANDLE, HWND, LPARAM, LRESULT, RECT, WAIT_OBJECT_0, WPARAM};
use windows_sys::Win32::Graphics::Dwm::{DwmSetWindowAttribute, DWMWA_WINDOW_CORNER_PREFERENCE, DWMWCP_ROUND};
use windows_sys::Win32::Graphics::Gdi::*;
use windows_sys::Win32::Graphics::GdiPlus::*;
use windows_sys::Win32::System::LibraryLoader::GetModuleHandleW;
use windows_sys::Win32::System::Registry::{RegGetValueW, HKEY_CURRENT_USER, RRF_RT_REG_DWORD};
use windows_sys::Win32::UI::HiDpi::GetDpiForSystem;
use windows_sys::Win32::UI::Shell::SHCreateMemStream;
use windows_sys::Win32::UI::WindowsAndMessaging::*;

const LOGO: &[u8] = include_bytes!("../splash-logo.png");

// The colors and logo the window paints with, made once.
struct Look {
    page: u32,
    ink: u32,
    quiet: u32,
    logo: usize,
    scale: f32,
}

static LOOK: OnceLock<Look> = OnceLock::new();

pub fn wide(text: &str) -> Vec<u16> {
    text.encode_utf16().chain(Some(0)).collect()
}

// Whether Windows shows apps dark, read from the same place Windows keeps it.
fn windows_is_dark() -> bool {
    let mut value: u32 = 1;
    let mut size = 4u32;
    let found = unsafe {
        RegGetValueW(
            HKEY_CURRENT_USER,
            wide("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize").as_ptr(),
            wide("AppsUseLightTheme").as_ptr(),
            RRF_RT_REG_DWORD,
            null_mut(),
            &mut value as *mut u32 as *mut _,
            &mut size,
        )
    };
    found == 0 && value == 0
}

// The logo, read by GDI+ from the picture built into this file.
fn load_logo() -> usize {
    unsafe {
        let input = GdiplusStartupInput { GdiplusVersion: 1, DebugEventCallback: 0, SuppressBackgroundThread: 0, SuppressExternalCodecs: 0 };
        let mut token = 0usize;
        if GdiplusStartup(&mut token, &input, null_mut()) != 0 {
            return 0;
        }
        let stream = SHCreateMemStream(LOGO.as_ptr(), LOGO.len() as u32);
        let mut bitmap: *mut GpBitmap = null_mut();
        if stream.is_null() || GdipCreateBitmapFromStream(stream, &mut bitmap) != 0 {
            return 0;
        }
        bitmap as usize
    }
}

// Colors are written blue, green, red, as Windows takes them.
fn look() -> &'static Look {
    LOOK.get_or_init(|| {
        let dark = windows_is_dark();
        let scale = unsafe { GetDpiForSystem() } as f32 / 96.0;
        let (page, ink, quiet) = if dark { (0x1D1816, 0xE6EAEC, 0x8F989B) } else { (0xECF4F7, 0x241F1E, 0x636B6E) };
        Look { page, ink, quiet, logo: load_logo(), scale }
    })
}

fn px(value: i32) -> i32 {
    (value as f32 * look().scale).round() as i32
}

// A line of text in the middle of the window, at the height given.
unsafe fn centered(dc: HDC, width: i32, top: i32, text: &str, points: i32, bold: bool, color: u32) {
    let height = -(points as f32 * look().scale * 96.0 / 72.0).round() as i32;
    let font = CreateFontW(
        height, 0, 0, 0,
        if bold { FW_BOLD as i32 } else { FW_NORMAL as i32 },
        0, 0, 0,
        DEFAULT_CHARSET as u32, OUT_DEFAULT_PRECIS as u32, CLIP_DEFAULT_PRECIS as u32, CLEARTYPE_QUALITY as u32,
        (DEFAULT_PITCH | FF_DONTCARE) as u32,
        wide("Segoe UI").as_ptr(),
    );
    let old = SelectObject(dc, font);
    SetTextColor(dc, color);
    let mut area = RECT { left: 0, top, right: width, bottom: top + px(40) };
    let words = wide(text);
    DrawTextW(dc, words.as_ptr(), (words.len() - 1) as i32, &mut area, DT_CENTER | DT_SINGLELINE | DT_TOP);
    SelectObject(dc, old);
    DeleteObject(font);
}

unsafe fn paint(window: HWND) {
    let look = look();
    let mut ps: PAINTSTRUCT = zeroed();
    let dc = BeginPaint(window, &mut ps);
    let mut area: RECT = zeroed();
    GetClientRect(window, &mut area);
    let brush = CreateSolidBrush(look.page);
    FillRect(dc, &area, brush);
    DeleteObject(brush);
    if look.logo != 0 {
        let mut graphics: *mut GpGraphics = null_mut();
        if GdipCreateFromHDC(dc, &mut graphics) == 0 {
            GdipSetInterpolationMode(graphics, InterpolationModeHighQualityBicubic);
            let size = px(80);
            GdipDrawImageRectI(graphics, look.logo as *mut GpImage, (area.right - size) / 2, px(36), size, size);
            GdipDeleteGraphics(graphics);
        }
    }
    SetBkMode(dc, TRANSPARENT as i32);
    centered(dc, area.right, px(126), "Sumizuri", 15, true, look.ink);
    centered(dc, area.right, px(162), "Getting the setup ready\u{2026}", 9, false, look.quiet);
    EndPaint(window, &ps);
}

unsafe extern "system" fn procedure(window: HWND, message: u32, w: WPARAM, l: LPARAM) -> LRESULT {
    match message {
        WM_PAINT => {
            paint(window);
            0
        }
        // The window moves when dragged anywhere, and it does not close on its own.
        WM_NCHITTEST => HTCAPTION as LRESULT,
        WM_CLOSE => 0,
        _ => DefWindowProcW(window, message, w, l),
    }
}

// Opens the window in the middle of the screen and draws it at once.
pub fn show() -> HWND {
    unsafe {
        let instance = GetModuleHandleW(null());
        let name = wide("SumizuriSetupSplash");
        let class = WNDCLASSEXW {
            cbSize: size_of::<WNDCLASSEXW>() as u32,
            lpfnWndProc: Some(procedure),
            hInstance: instance,
            hIcon: LoadIconW(instance, 1 as _),
            hCursor: LoadCursorW(null_mut(), IDC_ARROW),
            lpszClassName: name.as_ptr(),
            ..zeroed()
        };
        RegisterClassExW(&class);
        let (width, height) = (px(340), px(220));
        let left = (GetSystemMetrics(SM_CXSCREEN) - width) / 2;
        let top = (GetSystemMetrics(SM_CYSCREEN) - height) / 2;
        let window = CreateWindowExW(
            WS_EX_APPWINDOW, name.as_ptr(), wide("Sumizuri").as_ptr(), WS_POPUP,
            left, top, width, height, null_mut(), null_mut(), instance, null(),
        );
        let corner = DWMWCP_ROUND;
        DwmSetWindowAttribute(window, DWMWA_WINDOW_CORNER_PREFERENCE as u32, &corner as *const _ as *const _, 4);
        ShowWindow(window, SW_SHOW);
        UpdateWindow(window);
        window
    }
}

// Handles the messages of the window for a while, or until the handle given is done, so it keeps drawing and other windows never wait on it. True when the handle is done.
pub fn wait(handle: Option<HANDLE>, ms: u32) -> bool {
    unsafe {
        let handles: Vec<HANDLE> = handle.into_iter().collect();
        let result = MsgWaitForMultipleObjects(handles.len() as u32, handles.as_ptr(), 0, ms, QS_ALLINPUT);
        let mut message: MSG = zeroed();
        while PeekMessageW(&mut message, null_mut(), 0, 0, PM_REMOVE) != 0 {
            TranslateMessage(&message);
            DispatchMessageW(&message);
        }
        handle.is_some() && result == WAIT_OBJECT_0
    }
}

pub fn message(text: &str) {
    unsafe {
        MessageBoxW(null_mut(), wide(text).as_ptr(), wide("Sumizuri Setup").as_ptr(), MB_OK | MB_ICONERROR);
    }
}
