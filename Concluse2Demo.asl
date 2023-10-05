
state("Concluse2") { }

startup
{
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Concluse 2";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		return true;
	});
}

updateb
{
	current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
}

start
{
	
}

split
{
	
}

isLoading
{
	return (current.activeScene != "01 - EdisonHotel-EXTERIOR" && current.activeScene != "01 - EdisonHotel-EXTERIOR - Twisted" && current.activeScene != "01 - EdisonHotel-EXTERIOR - Boss Fight");
}