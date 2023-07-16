
state("Spacky's Nightshift") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Spacky's Nightshift";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
	settings.Add("burger", false, "Split on burger thrown");
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		vars.Helper["day"] = mono.Make<int>("MANAGER", "instance", "currentDay");
		vars.Helper["won"] = mono.Make<bool>("GAME", "instance", "hasWon");
		vars.Helper["freezeMovement"] = mono.Make<bool>("PlayerController", "instance", "frozen_movementOnly");
		vars.Helper["burger"] = mono.Make<bool>("PLAYER", "instance", "holdingFood");
		return true;
	});
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
}

start
{
	//Split when moving form Main Menu to Game Scene
    if((old.activeScene == "MANAGER" && current.activeScene == "SampleScene") && (current.day == 0 || current.day == 2)){
		return true;
	}
}

split
{
	//Split when frozen at the end of day 7
	if(current.freezeMovement && !old.freezeMovement){
		return true;
	}

	//Split upon completing level
	if(current.activeScene == "SampleScene" && current.won && !old.won){
		return true;
	}

	//Split on throwing Burger
	if(settings["burger"] && !current.burger && old.burger){
		return true;
	}
}

isLoading
{
	return current.activeScene != "SampleScene";
}