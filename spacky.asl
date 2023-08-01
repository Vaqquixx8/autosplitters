
state("Spacky's Nightshift") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Spacky's Nightshift";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
	settings.Add("daySplit", true, "Split on Day Completed");
	settings.Add("basementSplit", true, "Split on Entering the Basement");
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		vars.Helper["day"] = mono.Make<int>("MANAGER", "instance", "currentDay");
		vars.Helper["won"] = mono.Make<bool>("GAME", "instance", "hasWon");
		vars.Helper["freezeMovement"] = mono.Make<bool>("PlayerController", "instance", "frozen_movementOnly");
		vars.Helper["basementEnterFreeze"] = mono.Make<bool>("PlayerController", "instance", "frozen");
		vars.Helper["paused"] = mono.Make<bool>("GAME", "instance", "gamePaused");
		return true;
	});
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
}

start
{
	//Start when moving from Main Menu to Game Scene
    if((old.activeScene == "MANAGER" && current.activeScene == "SampleScene") && (current.day == 0 || current.day == 2 || current.day == 6)){
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
	if(settings["daySplit"] && current.activeScene == "SampleScene" && current.won && !old.won){
		return true;
	}

	//Split on entering basement
	if(settings["basementSplit"] && current.basementEnterFreeze && !old.basementEnterFreeze && !current.paused){
		return true;
	}

}

isLoading
{
	return current.activeScene != "SampleScene";
}