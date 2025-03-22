state("REPO") 
{

}

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "R.E.P.O.";
	vars.Helper.AlertLoadless();
}
init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		// Initialize the previousLevel or else the timer won't start the first time
		vars.previousLevel = "Main Menu";

		// Get the current level name, and current gameState
		vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
		vars.Helper["tutorialStage"] = mono.Make<int>("TutorialDirector", "instance", "currentPage");
		vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");

		
		return true;
	});
}
update
{
	// Game uses custom level system instead of Unity's built in Scenes (for some reason????)
	if(current.levelName != old.levelName)
	{
		vars.previousLevel = old.levelName;
	}
	//print("Page " + current.tutPage.ToString() + " Progress " + current.tutPro.ToString());	
	//print("Current: " + current.levelName + "  || Previous: " + vars.previousLevel);
}
start 
{
    // Timer should start only after the loading screen (state changes to 2; Main)
    if(old.state != 2 && current.state == 2) {
        // Do not start if the current level is a menu
        if(current.levelName == "Main Menu" || current.levelName == "Lobby Menu") {
            return false;
        }
        // If coming from a menu (either Main Menu or Lobby Menu), start the timer
        if(vars.previousLevel == "Main Menu" || vars.previousLevel == "Lobby Menu") {
            return true;
        }
    }
    return false;
}


split
{
	// If level name changes
	if(current.levelName != old.levelName){
		// if going to main menu, ignore, unless coming from completed tutorial
		if(current.levelName == "Main Menu") 
		{
			if(old.levelName == "Tutorial" && current.tutorialStage == 16)
			{
				return true;
			}
			return false;
		}

		// If we did not come from truck, or shop, check if died as well
		if((old.levelName != "Service Station") && (old.levelName != "Truck")  && (current.levelName != "Disposal Arena"))
		{
			return true;
		}
	}
	return false;
}               
isLoading
{
	// State 2 is "Main" state, applicable to Main Menu and actual Gameplay, State 6 is "Death" State, unless in tutorial ig idfk
	return (current.state != 2 && current.state != 6);
}
reset
{
	// Level changed
	if(current.levelName != old.levelName)
	{
		// Going to Main Menu
		if(current.levelName == "Main Menu" || current.levelName == "Disposal Arena")
		{
			if(old.levelName == "Tutorial" && current.tutorialStage == 16)
			{
				return false;
				// Finished Tutorial, don't reset
			}
			return true;
		}
	}
	return false;
}
