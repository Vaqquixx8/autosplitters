
state("Little Screamies") 
{

}

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Little Screamies";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	settings.Add("level", true, "Split on Completing Level");
	settings.Add("BasherIntro" , true, "BasherIntro", "level");
    settings.Add("Opening" , true, "Opening", "level");
    settings.Add("FloorOne" , true, "FloorOne", "level");
    settings.Add("FloorOne.Rusty" , true, "FloorOne.Rusty", "level");
    settings.Add("FloorTwo" , true, "FloorTwo", "level");
    settings.Add("Octobird" , true, "Octobird", "level");

	
}
  

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		return true;
	});
	vars.scenes = new string[]
    {
         "BasherIntro" ,
         "Opening",
         "FloorOne",         
         "FloorOne.Rusty",
         "FloorTwo",        
         "Octobird"
    };
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;
}
start
{
	//Start when moving from Main Menu to Intro Scene
    if(old.activeScene == "Bootstrapper" && current.activeScene == "BasherIntro"){
		return true;
	}
}
// Levels in Order
// BasherIntro
// Opening
// FloorOne
// FloorOne.Rusty
// FloorTwo
// Octobird
// Screamcut.Power
split
{
	// Split on beating game
	if(current.activeScene == "Credits" || current.loadingScene == "Credits"){
		return true;
	}

	// Level Splits
	foreach (string scene in vars.scenes)
    {
        if (old.activeScene == scene && current.activeScene != scene && settings[scene])
        {
            return true;
        }
    }
	return false;
	// No Screamcut.Power as that's the Final Level, and is handled above.

}               
isLoading
{
	return (current.loadingScene == "Bootstrapper") || (current.activeScene == "Bootstrapper");
}
