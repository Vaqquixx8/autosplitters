
state("Clucky's Picnic Adventure") { }
startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Clucky's Picnic Adventure";
	vars.Helper.LoadSceneManager = true;
	//vars.Helper.AlertLoadless();
    settings.Add("levelSplit", true, "Split on level completed");
}
init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		//vars.Helper["day"] = mono.Make<int>("MANAGER", "instance", "currentDay");
		vars.Helper["level"] = mono.Make<int>("vgame_manager", "instance", "currentLevelId");
		return true;
	});
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
}

start
{
    return current.activeScene == "SampleScene" && old.activeScene == "manager_god";
}

split
{
    if(current.level != old.level){
        return true;
    }
}
