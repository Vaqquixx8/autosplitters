
state("REPO") 
{

}

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "R.E.P.O.";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	// settings.Add("level", true, "Split on Completing Level");
}
  // 2 main menu ingame, 3 4 5 0 1 loading?

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		vars.states = new int[]
    {
         0,
         1,
         3,         
         4,
         5,        
    };
	vars.previousLevel = "";
		//runStarted
		vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
		vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");
		//vars.Helper["isShop"] = mono.Make<bool>("SemiFunc", "RunIsShop()");
		return true;
	});
}
// Levels:
// Main Menu: Main
update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
	if(current.levelName != old.levelName){
		vars.previousLevel = old.levelName;
	}
    //print(current.levelName.ToString());
	//print(current.activeScene);
}
start
{
	
    if(old.state != 2 && current.state == 2 && (vars.previousLevel != "Main Menu")){
		return true;
	}
	return false;
}

split
{
	if((old.state == 2 && current.state != 2) && ((vars.previousLevel != "Main Menu") && (vars.previousLevel != "Service Station") && (vars.previousLevel != "Truck"))){
		return true;
	}

	return false;
}               
isLoading
{
	foreach (int state in vars.states)
    	{
    	    if (current.state == state)
    	    {
    	        return true;
    	    }
    	}
		return false;
}
