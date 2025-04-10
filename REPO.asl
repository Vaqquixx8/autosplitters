state("REPO") 
{
	
}

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "R.E.P.O.";
	vars.Helper.AlertLoadless();

	settings.Add("levelSplit", true, "Split on completing a Level");

	settings.Add("taxSplit", true, "Split on reaching currency amount");
    settings.Add("100", false, "100K", "taxSplit");
    settings.Add("250", false, "250K", "taxSplit");
    settings.Add("500", false, "500K", "taxSplit");
    settings.Add("1000", false, "1M", "taxSplit");
    settings.Add("2000", false, "2M", "taxSplit");
	
}
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.previousLevel = "Main Menu";
        vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
        vars.Helper["tutorialStage"] = mono.Make<int>("TutorialDirector", "instance", "currentPage");
        vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");

		vars.Helper["currency"] = mono.Make<int>("CurrencyUI", "instance", "currentHaulValue");

        return true;
    });
}
update
{
	// Game uses custom level system instead of Unity's built in Scenes
	if(current.levelName != old.levelName)
	{
		vars.previousLevel = old.levelName;
	}
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
	// Only Split if the user has selected levelSplit
	if(settings["levelSplit"])
	{
		// If level name changes
		if(current.levelName != old.levelName)
		{
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
	}
	// If playing Taxes%
	if(settings["taxSplit"])
	{
		// Total Earned Amount Changed
		if(old.currency != current.currency)
		{
			// If the amount is equal to the selected category amount, return true
			if(settings.ContainsKey(current.currency.ToString()) && settings[current.currency.ToString()])
			{
				return true;
			}
			return false;
		}
		return false;
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
