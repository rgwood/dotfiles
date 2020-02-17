# .NET Core notes

## Linux

### Services

Use `dotnet new worker` and the Microsoft.Extensions.Hosting.Systemd package to easily run a Systemd service on Linux. [Blog post](https://devblogs.microsoft.com/dotnet/net-core-and-systemd/).

### Linux/Unix/POSIX syscalls

tl;dr use Mono.Posix.NETStandard package

Simple way to call syscalls: [P/Invoke](https://docs.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke). Example:

```csharp
[DllImport("libc", EntryPoint = "getppid")]
private static extern int GetParentPid();
```

This is OK for simple syscalls, but not all; POSIX syscalls and datatypes can vary slightly across implementations, and why reinvent the wheel? Interesting discussion by MS employees about why they still use Mono.Posix: https://github.com/dotnet/corefx/issues/15289

[Good article(https://developers.redhat.com/blog/2019/03/25/using-net-pinvoke-for-linux-system-functions/)


## Testing

`dotnet test` is a bit slow – takes about 1.5s no matter what. Tried mstest and nunit, same result.