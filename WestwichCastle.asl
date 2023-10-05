state("Westwich Castle") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Westwich Castle";
    //vars.Helper.LoadSceneManager = true;
    //vars.Helper.AlertLoadless();
    settings.Add("hammerSplit", false, "Split on Getting Hammer");
    settings.Add("lanternSplit", false, "Split on Getting Lantern");
    settings.Add("valveSplit", false, "Split on Getting Valve");
    settings.Add("leverSplit", false, "Split on Getting a Lever");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        //Start and Final Split
        vars.Helper["speed"] = mono.Make<float>("PlayerMovement", "instance", "currentSpeed");
        vars.Helper["outDoor"] = mono.Make<bool>("Player", "instance", "playerIsOutdoor");

        //Item Splits
        vars.Helper["lantern"] = mono.Make<bool>("Player", "instance", "pickedUpLantern");
        vars.Helper["hammer"] = mono.Make<bool>("Player", "instance", "pickedUpHammer");
        vars.Helper["valve"] = mono.Make<bool>("Player", "instance", "pickedUpValve");
        vars.Helper["lever"] = mono.Make<bool>("Player", "instance", "pickedUpLever");

        vars.Helper["inMenu"] = mono.Make<bool>("MainMenu", "instance", "inMainMenu");
        return true;
    });

    
}
start
{
    //Start Time on First Movement
    if(current.speed != 0 && old.speed == 0){
        return true;
    }
}

split
{
    //Final Split
    if(!old.outDoor && current.outDoor ){
        return true;
    }

    //Split On Getting an Item
    if(settings["lanternSplit"]&&!old.lantern && current.lantern){
        return true;
    }
    if(settings["hammerSplit"]&&current.hammer && !old.hammer){
        return true;
    }
    if(settings["valveSplit"]&&current.valve && !old.valve){
        return true;
    }
    if(settings["leverSplit"]&&current.lever && !old.lever){
        return true;
    }
}

reset
{
    if(!old.inMenu && current.inMenu){
        return true;
    }
}