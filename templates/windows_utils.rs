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
