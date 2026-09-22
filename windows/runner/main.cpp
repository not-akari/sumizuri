#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <app_links/app_links_plugin_c_api.h>
#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>

#include "flutter_window.h"
#include "utils.h"

// No BDW_CUSTOM_FRAME: native title bar buttons register on the first click, unlike a custom frame's.
auto bdw = bitsdojo_window_configure(BDW_HIDE_ON_STARTUP);

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // A link opened while the app is running goes to that copy, which then comes to the front.
  if (SendAppLinkToInstance()) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // A debug build says so in its title, next to a release that may be open.
#ifdef _DEBUG
  const wchar_t* title = L"sumizuri (debug)";
#else
  const wchar_t* title = L"sumizuri";
#endif
  if (!window.Create(title, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
