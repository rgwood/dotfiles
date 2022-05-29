AddToUserPath_Idemopotent(Environment.ExpandEnvironmentVariables(@"%USERPROFILE%\bin"));
AddToUserPath_Idemopotent(Environment.ExpandEnvironmentVariables(@"%USERPROFILE%\github\nushell\target\debug"));

void AddToUserPath_Idemopotent(string directoryPath)
{
    string currPath = Environment.GetEnvironmentVariable("Path",  EnvironmentVariableTarget.User)!;

    if(currPath.Contains(directoryPath, StringComparison.OrdinalIgnoreCase))
        {Console.WriteLine($"Already exists: {directoryPath}"); return;}

    string newPath = Append(currPath, directoryPath);
    Console.WriteLine($"Current path:\n{currPath}");
    Console.WriteLine($"New path:\n{newPath}");

    Environment.SetEnvironmentVariable("Path", newPath, EnvironmentVariableTarget.User);
    Console.WriteLine($"Added {directoryPath} to user $Path");
}

string Append(string original, string addition)
{
    if(original.EndsWith(';'))
        return original + addition;
    else
        return $"{original};{addition}";
}