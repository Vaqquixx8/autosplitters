
state("Clucky's Picnic Adventure") { }
startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Clucky's Picnic Adventure";
	vars.Helper.LoadSceneManager = true;
	//vars.Helper.AlertLoadless();
    settings.Add("levelSplit", true, "Split on level completed");
    settings.Add("trophySplit", false, "Split on gaining Trophy");
}
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["level"] = mono.Make<int>("vgame_manager", "instance", "currentLevelId");
        vars.Helper["trophyList"] = mono.MakeArray<IntPtr>("trophies","instance", "trophiesList");

        var t = mono["trophy"];
        vars.ReadTrophy = (Func<IntPtr, dynamic>)(trophy =>
        {
            dynamic ret = new ExpandoObject();
            ret.display_name = vars.Helper.ReadString(trophy + t["display_name"]);
            ret.acquired = vars.Helper.Read<bool>(trophy + t["acquired"]);
            return ret;
        });

        return true;
    });
    
    vars.CompletedSplits = new List<string>();
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    
}

start
{
    return current.activeScene == "SampleScene" && old.activeScene == "manager_god";
}
onStart
{
    vars.CompletedSplits = new List<string>();
}

split
{ 
    //Split on gaining trophy
    if(settings["trophySplit"]){
    foreach (var trophy in current.trophyList)
    {
        var troph = vars.ReadTrophy(trophy);
        if (troph.acquired && !vars.CompletedSplits.Contains(troph.display_name))
        {
            vars.Log("Collected " + troph.display_name + "!");
            vars.CompletedSplits.Add(troph.display_name);
            return true;
        }
    }
    }
    //Split on level complete
    if(current.level != old.level){
    if(settings["levelSplit"]){
        return true;
    }
    if(old.level == 5){
        return true;
    }
    }
}
