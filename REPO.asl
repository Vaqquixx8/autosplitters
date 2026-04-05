state("REPO")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "R.E.P.O.";
    vars.Helper.UnityVersion = new Version(2022, 3);
    vars.Helper.AlertLoadless();

    vars.debugLog = false;

    vars.RunLevels = new List<string>()
    {
        "Tutorial",
        "Museum of Human Art",
        "Headman Manor",
        "Swiftbroom Academy",
        "McJannek Station"
    };

    settings.Add("tutorialSplits", true, "Split on completing Tutorial Stage");
    settings.Add("tut1", false, "Move", "tutorialSplits");
    settings.Add("tut2", false, "Jump", "tutorialSplits");
    settings.Add("tut3", false, "Crouch", "tutorialSplits");
    settings.Add("tut4", false, "Hide", "tutorialSplits");
    settings.Add("tut5", false, "Run", "tutorialSplits");
    settings.Add("tut6", false, "Tumble", "tutorialSplits");
    settings.Add("tut7", false, "Grab Objects", "tutorialSplits");
    settings.Add("tut8", false, "Scroll Objects", "tutorialSplits");
    settings.Add("tut9", false, "Rotate Objects", "tutorialSplits");
    settings.Add("tut10", false, "Toggle Items", "tutorialSplits");
    settings.Add("tut11", false, "Store Items", "tutorialSplits");
    settings.Add("tut12", false, "View Map", "tutorialSplits");
    settings.Add("tut13", false, "Grab Cart", "tutorialSplits");
    settings.Add("tut14", false, "Fill Cart", "tutorialSplits");
    settings.Add("tut15", false, "Fill Extraction", "tutorialSplits");

    settings.Add("taxSplit", true, "Split on reaching currency amount");
    settings.Add("100", false, "100K", "taxSplit");
    settings.Add("250", false, "250K", "taxSplit");
    settings.Add("500", false, "500K", "taxSplit");
    settings.Add("1000", false, "1M", "taxSplit");
    settings.Add("2000", false, "2M", "taxSplit");

    settings.Add("levelSplit", true, "Split on completing a Level");
    settings.Add("everyNLevels", true, "Split every n levels (Every 1 Level is on by default)", "levelSplit");
    for (var i = 1; i <= 10; i++)
        settings.Add("nLevel_" + i, i == 1, i + " Levels", "everyNLevels");

    settings.Add("specificLevels", true, "Split after specific levels", "levelSplit");
    for (var i = 1; i <= 200; i++)
        settings.Add("specLevel_" + i, false, "Level " + i, "specificLevels");
}

init
{
    if (vars.debugLog ?? false)
        print("INIT fired");

    vars.previousLevel = "Main Menu";
    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };
    vars.daysCompleted = 0;
    vars.hookReady = false;
    vars.dataReady = false;
    vars.pendingStart = false;
	vars.pendingStartTick = 0;
	vars.startDelayMs = 1000;
	vars.startArmed = false;
	vars.runActive = false;
    vars.attachTick = Environment.TickCount;
    vars.hookDelayMs = 3000;

    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        if (Environment.TickCount - vars.attachTick < vars.hookDelayMs)
            return false;

        try
        {
            vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");
            vars.Helper["levelsCompleted"] = mono.Make<int>("RunManager", "instance", "levelsCompleted");
            vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
            vars.Helper["tutorialStage"] = mono.Make<int>("TutorialDirector", "instance", "currentPage");
            vars.Helper["currency"] = mono.Make<int>("CurrencyUI", "instance", "currentHaulValue");

            vars.hookReady = true;
            vars.dataReady = false;

            if (vars.debugLog ?? false)
                print("TryLoad success");

            return true;
        }
        catch (Exception e)
        {
            vars.hookReady = false;
            vars.dataReady = false;

            if (vars.debugLog ?? false)
                print("TryLoad failed: " + e.Message);

            return false;
        }
    });
}

exit
{
    if (vars.debugLog ?? false)
        print("EXIT fired");

    vars.hookReady = false;
    vars.dataReady = false;
    vars.pendingStart = false;
    vars.pendingStartTick = 0;
    vars.startArmed = false;
    vars.previousLevel = "Main Menu";
    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };
    vars.daysCompleted = 0;
	vars.runActive = false;
}

onStart
{
    vars.daysCompleted = 0;
    vars.pendingStart = false;
    vars.pendingStartTick = 0;
    vars.startArmed = false;
	vars.runActive = false;
    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };
}

update
{
    if (!(vars.hookReady ?? false))
        return false;

    if (vars.debugLog ?? false)
        print("UPDATE entered");

    var currentDict = (IDictionary<string, object>)current;
    var oldDict = (IDictionary<string, object>)old;

    if (!currentDict.ContainsKey("levelName"))
    {
        if (vars.debugLog ?? false)
            print("UPDATE EXIT: current missing levelName");
        return false;
    }

    if (!currentDict.ContainsKey("state"))
    {
        if (vars.debugLog ?? false)
            print("UPDATE EXIT: current missing state");
        return false;
    }

    bool currentIsMenu = current.levelName == "Main Menu" || current.levelName == "Lobby Menu";
    bool currentIsRunLevel = vars.RunLevels.Contains((string)current.levelName);
    bool currentIsSplash = current.levelName == "Splash Screen";
    bool currentInLoading = current.state != 2 && current.state != 6;

    if (!oldDict.ContainsKey("levelName") || !oldDict.ContainsKey("state"))
    {
        if (vars.debugLog ?? false)
            print("UPDATE WARN: old data missing, using current tick only");

        if (!vars.pendingStart
            && currentIsRunLevel
            && !currentIsSplash
            && currentInLoading)
        {
            vars.pendingStart = true;
            vars.pendingStartTick = Environment.TickCount;
            vars.startArmed = false;

            if (vars.debugLog ?? false)
                print("pendingStart late-set during loading | level=" + current.levelName + " | state=" + current.state);
        }

        if (vars.pendingStart
            && !vars.startArmed
            && currentIsRunLevel
            && !currentIsSplash
            && currentInLoading
            && Environment.TickCount - vars.pendingStartTick >= vars.startDelayMs)
        {
            vars.startArmed = true;

            if (vars.debugLog ?? false)
                print("startArmed set late after delay");
        }

        vars.dataReady = true;
        return true;
    }

    vars.dataReady = true;

    bool oldIsMenu = old.levelName == "Main Menu" || old.levelName == "Lobby Menu";

    if (vars.debugLog ?? false)
    {
        print("UPDATE DATA READY | level=" + current.levelName
            + " | oldLevel=" + old.levelName
            + " | state=" + current.state
            + " | oldState=" + old.state
            + " | pendingStart=" + vars.pendingStart
            + " | startArmed=" + vars.startArmed
            + " | runLevel=" + currentIsRunLevel
            + " | splash=" + currentIsSplash);
    }

    if (current.levelName != old.levelName)
    {
        if (currentIsMenu)
        {
            vars.pendingStart = false;
            vars.pendingStartTick = 0;

            if (vars.debugLog ?? false)
                print("pendingStart/startArmed cleared: entered menu");
        }

        vars.previousLevel = old.levelName;
    }

    // Detect the first real loading screen into a run from menu
    if (!vars.pendingStart
        && oldIsMenu
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading)
    {
        vars.pendingStart = true;
        vars.pendingStartTick = Environment.TickCount;
        vars.startArmed = false;
		vars.runActive = false;

        if (vars.debugLog ?? false)
            print("pendingStart set on first loading screen: " + old.levelName + " -> " + current.levelName + " | state=" + current.state);
    }

    // Fallback in case the menu transition tick was missed
    if (!vars.pendingStart
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading)
    {
        vars.pendingStart = true;
        vars.pendingStartTick = Environment.TickCount;
        vars.startArmed = false;

        if (vars.debugLog ?? false)
            print("pendingStart late-set during loading | level=" + current.levelName + " | state=" + current.state);
    }

    // Arm the actual start 1 second after loading begins
    if (vars.pendingStart
        && !vars.startArmed
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading
        && Environment.TickCount - vars.pendingStartTick >= vars.startDelayMs)
    {
        vars.startArmed = true;

        if (vars.debugLog ?? false)
            print("startArmed set after delay");
    }

    // If we leave loading before the delay elapsed, cancel the attempt
    if (vars.pendingStart
        && !vars.startArmed
        && (!currentIsRunLevel || currentIsSplash || !currentInLoading))
    {
        vars.pendingStart = false;
        vars.pendingStartTick = 0;
        vars.startArmed = false;

        if (vars.debugLog ?? false)
            print("pendingStart cancelled before arm");
    }

    return true;
}

start
{
    if (!(vars.hookReady ?? false))
    {
        if (vars.debugLog ?? false)
            print("START EXIT: hookReady false");
        return false;
    }

    if (!(vars.dataReady ?? false))
    {
        if (vars.debugLog ?? false)
            print("START EXIT: dataReady false");
        return false;
    }

    bool currentIsRunLevel = vars.RunLevels.Contains((string)current.levelName);
    bool currentIsSplash = current.levelName == "Splash Screen";

    if (vars.debugLog ?? false)
    {
        print("START CHECK | pending=" + vars.pendingStart
            + " | armed=" + vars.startArmed
            + " | level=" + current.levelName
            + " | state=" + current.state
            + " | oldState=" + old.state
            + " | runLevel=" + currentIsRunLevel
            + " | splash=" + currentIsSplash);
    }

    if (vars.pendingStart
		&& vars.startArmed
		&& currentIsRunLevel
		&& !currentIsSplash
		&& old.state != 2
		&& current.state == 2)
	{
		vars.pendingStart = false;
		vars.pendingStartTick = 0;
		vars.startArmed = false;
		vars.runActive = true;

		if (vars.debugLog ?? false)
			print("Start triggered on gameplay after delayed arm");

		return true;
	}

    return false;
}

split
{
    if (!(vars.hookReady ?? false) || !(vars.dataReady ?? false))
        return false;

    // Tutorial splits
    if (settings["tutorialSplits"])
    {
        if (current.levelName != old.levelName)
        {
            if (current.levelName == "Main Menu")
            {
                if (old.levelName == "Tutorial" && current.tutorialStage == 16)
                    return true;

                return false;
            }
        }

        if (old.tutorialStage != current.tutorialStage)
        {
            if (current.tutorialStage >= 1 && current.tutorialStage <= 15)
            {
                if (settings["tut" + current.tutorialStage])
                    return true;
            }
        }
    }

    // Level splits
    if (settings["levelSplit"])
    {
        if (current.levelName != old.levelName)
        {
            if (current.levelName == "Main Menu")
                return false;

            if (old.levelName != "Service Station"
                && old.levelName != "Truck"
                && current.levelName != "Disposal Arena")
            {
                if (settings["specificLevels"] && settings["specLevel_" + current.levelsCompleted])
                    return true;

                if (settings["everyNLevels"])
                {
                    for (int i = 1; i <= 10; i++)
                    {
                        if (settings["nLevel_" + i] && current.levelsCompleted % i == 0)
                            return true;
                    }
                }
            }
        }
    }

    // Tax splits
    if (settings["taxSplit"])
    {
        if (old.currency != current.currency)
        {
            if (current.currency >= 100 && settings["100"] && vars.currencySplits.Contains(100))
            {
                vars.currencySplits.Remove(100);
                return true;
            }
            if (current.currency >= 250 && settings["250"] && vars.currencySplits.Contains(250))
            {
                vars.currencySplits.Remove(250);
                return true;
            }
            if (current.currency >= 500 && settings["500"] && vars.currencySplits.Contains(500))
            {
                vars.currencySplits.Remove(500);
                return true;
            }
            if (current.currency >= 1000 && settings["1000"] && vars.currencySplits.Contains(1000))
            {
                vars.currencySplits.Remove(1000);
                return true;
            }
            if (current.currency >= 2000 && settings["2000"] && vars.currencySplits.Contains(2000))
            {
                vars.currencySplits.Remove(2000);
                return true;
            }
        }
    }

    return false;
}

isLoading
{
    if (!(vars.hookReady ?? false) || !(vars.dataReady ?? false))
        return false;

    return (current.state != 2 && current.state != 6);
}

reset
{
    if (!(vars.hookReady ?? false) || !(vars.dataReady ?? false))
        return false;

    if (current.levelName != old.levelName)
    {
        if (current.levelName == "Main Menu" || current.levelName == "Disposal Arena")
        {
            vars.pendingStart = false;

            if (vars.debugLog ?? false)
                print("RESET: returned to menu/disposal");

            if (old.levelName == "Tutorial" && current.tutorialStage == 16)
                return false;

            return true;
        }
    }

    return false;
}
