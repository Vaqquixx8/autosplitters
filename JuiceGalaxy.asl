state("Juice Galaxy") { }
startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Juice Galaxy";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

    settings.Add("Reset", false, "Reset Upon Returning to Title Screen");
}
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["checkpoint"] = mono.Make<int>("Story", "checkpoint");
        return true;
    });
    
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    print("Cuurent Checkpoint: " + current.checkpoint);
}
start
{
    return current.activeScene == "JG_Overworld" && old.activeScene == "Loading Screen";
}
isLoading
{
    return current.activeScene == "Loading Screen";
}
reset
{
    if(settings["Reset"]){
        return (current.activeScene == "Title Screen" && old.activeScene != "Title Screen");
    }
}
split{
    if(current.checkpoint == 4 && old.checkpoint != 4){
        return true;
    }
}