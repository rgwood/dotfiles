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
