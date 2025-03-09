state("REPO") 
{

}

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "R.E.P.O.";
	//ars.Helper.LoadSceneManager = true;
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
	//print("Page " + current.tutPage.ToString() + " Progress " + current.tutPro.ToString());	//print("Current: " + current.levelName + "  || Previous: " + vars.previousLevel);
}
start
{
	// Time starts after the loading screen, not necessarily when the level changes
	if(old.state != 2 && current.state == 2)
	{
		//print("Current: " + current.levelName + "  || Previous: " + vars.previousLevel);

		// Don't start in the Main Menu's
		if(current.levelName == "Main Menu"  || current.levelName == "Lobby Menu")
		{
			return false;
		}
		else
		{
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

		// If we did not come from truck, or shop
		if((old.levelName != "Service Station") && (old.levelName != "Truck"))
		{
			return true;
		}
	}
	return false;
}               
isLoading
{
	// State 2 is "Main" state, applicable to Main Menu and actual Gameplay
	return (current.state != 2);
}
reset
{
	// Level changed
	if(current.levelName != old.levelName)
	{
		// Going to Main Menu
		if(current.levelName == "Main Menu")
		{
			if(old.levelName == "Tutorial")
			{
				// Finished Tutorial, don't reset
				if(current.tutorialStage == 16)
				{
					return false;
				}
				return true;
			}
			return true;
		}
	}
	return false;
}

