state("Slay Bells") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Slay Bells";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("crowbarSplit", false, "Split on Getting Crowbar");
    settings.Add("axeSplit", false, "Split on Getting Axe");
    settings.Add("pistolSplit", false, "Split on Getting Pistol");
    settings.Add("areaSplit", false, "Split on Entering New Area");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["inDialogue"] = mono.Make<bool>("Dialogue", "isInteracting");

        vars.Helper["hasCrowbar"] = mono.Make<bool>("inventory", "hasCrowbar");
        vars.Helper["hasAxe"] = mono.Make<bool>("inventory", "hasAxe");
        vars.Helper["hasPistol"] = mono.Make<bool>("inventory", "hasPistol");

        return true;
    });

    
}
start
{
    if(!current.inDialogue && old.inDialogue){
        return true;
    }
}
update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    //current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
}
split
{
    
    //Split on obtaining new item
    if(settings["crowbarSplit"]&&!old.hasCrowbar && current.hasCrowbar){
        return true;
    }
    if(settings["axeSplit"]&&!old.hasAxe && current.hasAxe){
        return true;
    }
    if(settings["pistolSplit"]&&!old.hasPistol && current.hasPistol){
        return true;
    }

    //Split on entering new area
    if(settings["areaSplit"]&&(current.activeScene != old.activeScene) && old.activeScene != "Main Menu"){
        return true;
    }

    //Ending Split
    if(current.activeScene == "End Screen" && old.activeScene != "End Screen"){
        return true;
    }
}

isLoading
{
    if(current.activeScene != "Map 04_Boss" && current.activeScene != "Map 03" && current.activeScene != "Map 02" && current.activeScene != "Map 01"){
        return true;
    }
    //return current.loadingScene != current.activeScene;
}
reset
{
    if(current.activeScene == "Main Menu" && old.activeScene != "Main Menu"){
        return true;
    }
}
