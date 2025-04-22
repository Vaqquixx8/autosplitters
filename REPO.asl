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

	settings.Add("everyNLevels", true, "Split every n levels", "levelSplit");
    for (var i = 1; i <= 10; i += 1)
    {
        settings.Add("nLevel_" + i, false, i + " Levels", "everyNLevels");
    }

	settings.Add("specificLevels", true, "Split after specific levels", "levelSplit");
    for (var i = 1; i <= 200; i += 1)
    {
        settings.Add("specLevel_" + i, false, "Level " + i, "specificLevels");
    }
}
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.previousLevel = "Main Menu";
        vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
        vars.Helper["levelsCompleted"] = mono.Make<int>("RunManager", "instance", "levelsCompleted");
        vars.Helper["tutorialStage"] = mono.Make<int>("TutorialDirector", "instance", "currentPage");
        vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");

		vars.Helper["currency"] = mono.Make<int>("CurrencyUI", "instance", "currentHaulValue");

        return true;
    });
	vars.currencySplits = new List<int>(){100, 250, 500, 1000, 2000};
	vars.daysCompleted = 0;
}
onStart
{
	vars.daysCompleted = 0;
    vars.currencySplits = new List<int>(){100, 250, 500, 1000, 2000};
}
update
{
	// Game uses custom level system instead of Unity's built in Scenes
	if(current.levelName != old.levelName)
	{
		vars.previousLevel = old.levelName;
	}
	print(current.levelsCompleted.ToString());
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

			// If we did not come from truck, or shop, check if died as well, Check levelSplits
			if((old.levelName != "Service Station") && (old.levelName != "Truck")  && (current.levelName != "Disposal Arena"))
			{
				// Split after completing specific level
				if(settings["specificLevels"] && settings["specLevel_" + current.levelsCompleted])
				{
					return true;
				}
				// Split every n levels
				if (settings["everyNLevels"])
				{
					for(int i = 1; i <= 10; i++)
                    {
                        if(settings["nLevel_" + i])
                        {
                            if(current.levelsCompleted % i == 0)
							{
							    return true;
							}

                        }
                    }
				}
			}
		}
	}
	//{100, 250, 500, 1000, 2000};
	// If playing Taxes%
	if(settings["taxSplit"])
	{
		// Total Earned Amount Changed
		if(old.currency != current.currency)
		{
			if(current.currency >= 100 && settings["100"] && vars.currencySplits.Contains(100))
			{
				vars.currencySplits.Remove(100);
				return true;
			}
			if(current.currency >= 250 && settings["250"] && vars.currencySplits.Contains(250))
			{
				vars.currencySplits.Remove(250);
				return true;
			}
			if(current.currency >= 500 && settings["500"] && vars.currencySplits.Contains(500))
			{
				vars.currencySplits.Remove(500);
				return true;
			}
			if(current.currency >= 1000 && settings["1000"] && vars.currencySplits.Contains(1000))
			{
				vars.currencySplits.Remove(1000);
				return true;
			}
			if(current.currency >= 2000 && settings["2000"] && vars.currencySplits.Contains(2000))
			{
				vars.currencySplits.Remove(2000);
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
	// State 2 is "Main" state, applicable to Main Menu and actual Gameplay, State 6 is "Death" State
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
