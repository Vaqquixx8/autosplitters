state("REPO") { }

startup
{
    vars.Watch = (Action<string>)(key => { if (vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "R.E.P.O.";
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.previousLevel = "";
        vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
        vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");

        return true;
    });
}

update
{
    if (old.levelName != current.levelName)
        vars.previousLevel = old.levelName;
}

start
{
    return old.state != 2 && current.state == 2 // Main
        && vars.previousLevel != "Main Menu";
}

split
{
    return old.state == 2 && current.state != 2 // Main
        && vars.previousLevel != "Main Menu"
        && vars.previousLevel != "Service Station"
        && vars.previousLevel != "Truck";
}         

isLoading
{
    return current.state == 0  // Load
        || current.state == 1  // Start
        || current.state == 3  // Outro
        || current.state == 4  // End
        || current.state == 5; // EndWait
}
