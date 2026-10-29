state("Gnomium") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
}

init
{
    version = "1.1.0";

    vars.Ready = false;
    vars.RunActive = false;
    vars.DayDisplayBaseline = 0;

    current.activeScene = "";
    current.loading = false;

    vars.UharaLogPrefix = "[BG-ASL 1.1.0] ";

    vars.IsGameplayScene = (Func<string, bool>)((name) =>
    {
        try
        {
            if (name == null) return false;
            return name.ToLowerInvariant().StartsWith("gameplay");
        }
        catch { return false; }
    });

    try
    {
        vars.JitSave = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
        vars.Utils = vars.Uhara.CreateTool("Unity", "Utils");

        IntPtr pLoadingStarted = vars.JitSave.AddFlag("PlayerController", "Instance_onServerStartedLoadingLevel");
        IntPtr pGameStarted = vars.JitSave.AddFlag("PlayerController", "Instance_onGameStarted");
        IntPtr pDisplayDay = vars.JitSave.AddFlag("PlayerController", "DisplayDay");

        vars.JitSave.ProcessQueue();

        vars.Resolver.Watch<int>("loadingStarted", pLoadingStarted);
        vars.Resolver.Watch<int>("gameStarted", pGameStarted);
        vars.Resolver.Watch<int>("displayDay", pDisplayDay);

        vars.Ready = true;
    }
    catch (Exception e)
    {
        try { vars.Uhara.Log(vars.UharaLogPrefix + "init failed: " + e.Message); } catch {}
        vars.Ready = false;
    }
}

update
{
    if (!vars.Ready)
        return true;

    vars.Uhara.Update();

    try
    {
        string scene = vars.Utils.GetActiveSceneName();
        if (scene != null)
            current.activeScene = scene;
    }
    catch {}

    try
    {
        current.loading = current.loadingStarted > current.gameStarted;
    }
    catch
    {
        current.loading = false;
    }

    return true;
}

start
{
    if (!vars.Ready)
        return false;

    if (current.gameStarted != old.gameStarted)
    {
        vars.RunActive = true;

        try { vars.DayDisplayBaseline = current.displayDay; }
        catch { vars.DayDisplayBaseline = 0; }

        return true;
    }

    return false;
}

split
{
    if (!vars.Ready || !vars.RunActive)
        return false;

    try
    {
        if (current.displayDay > vars.DayDisplayBaseline)
        {
            vars.DayDisplayBaseline = current.displayDay;
            return true;
        }
    }
    catch {}

    return false;
}

isLoading
{
    if (!vars.Ready)
        return false;

    return current.loading;
}

reset
{
    if (!vars.Ready)
        return false;

    if (old.activeScene != "MainMenu" && current.activeScene == "MainMenu")
    {
        vars.RunActive = false;
        try { vars.DayDisplayBaseline = current.displayDay; }
        catch { vars.DayDisplayBaseline = 0; }
        current.loading = false;
        return true;
    }

    return false;
}

exit
{
    vars.RunActive = false;
    current.loading = false;
}
