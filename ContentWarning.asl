state("Content Warning") {
    
 }

startup
{
    //vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    vars.quotasCompleted = 1;
    vars.quotaDay = 0;

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Content Warning";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();

    settings.Add("deathSplit", false, "Split on Dying");
    settings.Add("quotaSleepSplit", true, "Split on Waking Up (For Quota)");
}

init
{
            
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["day"] = mono.Make<int>("SurfaceNetworkHandler", "RoomStats", "CurrentDay");
        
        vars.Helper["HP"] = mono.Make<float>("Player","localPlayer", "data", "health");
        vars.Helper["HP2"] = mono.Make<bool>("Player","justDied");

        vars.Helper["rested"] = mono.Make<bool>("Player","localPlayer", "data", "rested");

        vars.Helper["startedGame"] = mono.Make<bool>("SurfaceNetworkHandler","m_Started");

        
        return true;
    });

    
}
start
{
    if(current.startedGame){
        return true;
    }
}
onStart
{
    vars.quotasCompleted = 1;
    vars.quotaDay = 0;
    vars.quotaDay = (vars.quotasCompleted * 3) + 1;
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    print(current.HP2.ToString());
}
split
{
    if(settings["deathSplit"]&& ){
        if((!old.HP2 && current.HP2) || (old.HP > 0 && current.HP <= 0)){
        return true;
        }

    }
    if(settings["quotaSleepSplit"]  && !old.rested && current.rested){
        if(current.day == vars.quotaDay){
            vars.quotasCompleted++;
            vars.quotaDay = (vars.quotasCompleted * 3) + 1;
            return true;
        }
    }
}
isLoading
{
    return current.loadingScene != current.activeScene;
}
reset
{
    return current.activeScene == "NewMainMenu";
}

