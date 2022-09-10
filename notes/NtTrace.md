Like strace but for Windows. Shows kernel calls.
https://github.com/rogerorr/NtTrace

Trace `foo.exe`, only return calls with "Write" in them:
`NtTrace -filter Write foo.exe`
