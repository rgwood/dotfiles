use std::{
    ffi::OsString,
    os::windows::prelude::{OsStrExt, OsStringExt},
};

pub fn string_from_null_terminated(wide_string: &[u16]) -> OsString {
    let first_null_index = wide_string
        .iter()
        .position(|&c| c == 0)
        .unwrap_or_else(|| wide_string.len()); // if no null terminator, return entire string

    OsString::from_wide(&wide_string[..first_null_index])
}

pub fn to_windows_wide_string(string: &str) -> Vec<u16> {
    OsString::from(string)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect()
}

pub fn unix_time_from_filetime(ft: &windows::Win32::Foundation::FILETIME) -> i64 {
    /// January 1, 1970 as Windows file time
    const EPOCH_AS_FILETIME: u64 = 116444736000000000;
    const HUNDREDS_OF_NANOSECONDS: u64 = 10000000;

    let time_u64 = ((ft.dwHighDateTime as u64) << 32) | (ft.dwLowDateTime as u64);
    let rel_to_linux_epoch = time_u64 - EPOCH_AS_FILETIME;
    let seconds_since_unix_epoch = rel_to_linux_epoch / HUNDREDS_OF_NANOSECONDS;

    seconds_since_unix_epoch as i64
}

// A port of Superluminal's C++ dark theme check: https://gist.github.com/rovarma/7b85f3db80f40cc144866812cad09919
//
// The Windows 10 Anniversary Update (1803) introduced support for dark mode. This is mainly intended for UWP apps, but things like Explorer follow it as well.
// There is no API to query the value of this setting directly, but it is stored in the registry, so we can simply read it from there.
// Note that if the regkey is not found in the registry (i.e. in earlier versions of Windows), we default to light theme.
fn is_dark_theme_active() -> bool {
    let hkey = HKEY_CURRENT_USER;
    let lpsubkey = windows_utils::to_windows_wide_string(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
    );
    let lpvalue = windows_utils::to_windows_wide_string("AppsUseLightTheme");
    let mut pcbdata = size_of::<u32>() as u32;
    let mut pvdata: u32 = Default::default();

    unsafe {
        // Read value of the registry key; if it's 0 it means dark theme is enabled.
        let res = RegGetValueW(
            hkey,
            PCWSTR(lpsubkey.as_ptr()),
            PCWSTR(lpvalue.as_ptr()),
            RRF_RT_REG_DWORD, // force RegGetValue to return a DWORD
            std::ptr::null_mut(),
            &mut pvdata as *mut u32 as *mut c_void,
            &mut pcbdata,
        );

        if res == ERROR_SUCCESS {
            eprintln!("great success");
            return pvdata == 0;
        }
    }

    // Regkey not found, default to light theme.
    false
}
