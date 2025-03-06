
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
}
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
		vars.Helper["levelName"] = mono.MakeString("RunManager", "instance", "levelCurrent", "NarrativeName");
		vars.Helper["state"] = mono.Make<int>("GameDirector", "instance", "currentState");
		
		return true;
	});
}
update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

	if(current.levelName != old.levelName){
		vars.previousLevel = old.levelName;
	}
		print(current.levelName + " " + vars.previousLevel);

}
start
{
	if(current.levelName == "Lobby Menu")
	{
		return false;    
	} 
	if(old.state != 2 && current.state == 2 && (current.levelName != "Main Menu" && (vars.previousLevel == "Main Menu" ||vars.previousLevel == "Lobby Menu" ))){
		return true;
	}
	return false;
}

split
{
	if(old.state == 2 && current.state != 2){
		//Check which level we came from and were we are going
		// We did not come from shops, or main menu
		if((vars.previousLevel != "Main Menu") && (vars.previousLevel != "Service Station") && (vars.previousLevel != "Truck")){
			return true;
		}
		
	}
	if(vars.previousLevel == "Tutorial" && current.levelName == "Main Menu"){
			// Finished Tutorial
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
