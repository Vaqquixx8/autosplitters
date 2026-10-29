state("REPO")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "R.E.P.O.";
    vars.Helper.UnityVersion = new Version(2022, 3);
    vars.Helper.AlertLoadless();

    vars.RunLevels = new List<string>()
    {
        "Tutorial",
        "Museum of Human Art",
        "Headman Manor",
        "Swiftbroom Academy",
        "McJannek Station",
        "Sunstone Valley Resort"
    };

    settings.Add("version04OrHigher", true, "Turn on if R.E.P.O. is version 0.4.0 or higher");
    settings.SetToolTip("version04OrHigher", "Used only when automatic version detection is unavailable or ambiguous. Leave off for versions below 0.4.0.");

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

    settings.Add("log", false, "Enable logging");
}

init
{
    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };

    vars.hookReady = false;
    vars.dataReady = false;
    vars.pendingStart = false;
    vars.pendingStartTick = 0;
    vars.startDelayMs = 1000;
    vars.startArmed = false;

    vars.attachTick = Environment.TickCount;
    vars.hookDelayMs = 8000;

    // Clear per-process detection and diagnostic state on every attachment.
    vars.versionProbeDone = false;
    vars.detectedVersion = "";
    vars.detectedPre04 = false;
    vars.lastLoggedLevel = null;
    vars.lastDeathMode = "";
    vars.deathState = settings["version04OrHigher"] ? 7 : 6;
    version = "unknown (manual fallback)";

    if (settings["log"])
        print("[REPO] Attached to process " + game.Id + "; waiting for successful TryLoad before probing game version.");

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

            if (settings["log"])
                print("[REPO] Hook ready; waiting for level data.");

            return true;
        }
        catch (Exception e)
        {
            vars.hookReady = false;
            vars.dataReady = false;

            if (settings["log"])
                print("[REPO] TryLoad failed: " + e.Message);

            return false;
        }
    });
}

exit
{
    vars.hookReady = false;
    vars.dataReady = false;
    vars.pendingStart = false;
    vars.pendingStartTick = 0;
    vars.startArmed = false;

    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };
}

onStart
{
    vars.pendingStart = false;
    vars.pendingStartTick = 0;
    vars.startArmed = false;

    vars.currencySplits = new List<int>() { 100, 250, 500, 1000, 2000 };
}

update
{
    if (!(vars.hookReady ?? false))
        return false;

    // The helper has completed TryLoad before update is allowed through.
    // Run once per attachment, before selecting the effective death state.
    if (!vars.versionProbeDone)
    {
        vars.versionProbeDone = true;
        if (settings["log"])
            print("[REPO] TryLoad complete; probing game version now.");
        try
        {
            // Accept only a
            // unique length-prefixed 0.x.y string from this attached installation.
            // Unity's executable metadata can contain the engine version instead.
            string exePath = modules.First().FileName;
            string versionPath = Path.Combine(Path.GetDirectoryName(exePath),
                "REPO_Data", "globalgamemanagers");
            var candidates = new HashSet<string>();
            string detectionSource = "globalgamemanagers";
            try
            {
                byte[] bytes = File.ReadAllBytes(versionPath);
                for (int i = 0; i <= bytes.Length - 9; i++)
                {
                    int length = BitConverter.ToInt32(bytes, i);
                    if (length < 5 || length > 64 || length > bytes.Length - i - 4
                        || bytes[i + 4] != (byte)'0' || bytes[i + 5] != (byte)'.')
                        continue;

                    string text = System.Text.Encoding.ASCII.GetString(bytes, i + 4, length);
                    var match = System.Text.RegularExpressions.Regex.Match(text,
                        @"\A(0\.\d+\.\d+(?:\.\d+)?)(?:[-+][A-Za-z0-9.-]+)?\z");
                    Version parsed;
                    if (match.Success && Version.TryParse(match.Groups[1].Value, out parsed))
                        candidates.Add(match.Groups[1].Value);
                }
            }
            catch (Exception e)
            {
                if (settings["log"])
                    print("[REPO] globalgamemanagers probe failed: " + e.Message);
            }

            if (settings["log"])
                print("[REPO] Version probe: globalgamemanagers candidates=["
                    + String.Join(", ", candidates.ToArray()) + "]");

            if (candidates.Count != 1)
            {
                // Older builds may not put the game version in PlayerSettings.
                // Read the version UI asset: length-prefixed "Version - ..."
                // name, 4-byte alignment, then its length-prefixed version value.
                // Scan in chunks so the whole shared asset file is never loaded.
                candidates.Clear();
                detectionSource = "sharedassets0.assets version UI";
                string assetsPath = Path.Combine(Path.GetDirectoryName(exePath),
                    "REPO_Data", "sharedassets0.assets");
                byte[] marker = System.Text.Encoding.ASCII.GetBytes("Version - ");
                byte[] buffer = new byte[65536];
                using (var stream = File.OpenRead(assetsPath))
                using (var reader = new BinaryReader(stream))
                {
                    long scanPosition = 0;
                    while (scanPosition < stream.Length)
                    {
                        stream.Position = scanPosition;
                        int count = stream.Read(buffer, 0, buffer.Length);
                        if (count < marker.Length)
                            break;
                        for (int i = 0; i <= count - marker.Length; i++)
                        {
                            if (buffer[i] != marker[0])
                                continue;
                            bool matches = true;
                            for (int j = 1; j < marker.Length; j++)
                                if (buffer[i + j] != marker[j])
                                {
                                    matches = false;
                                    break;
                                }
                            long nameOffset = scanPosition + i - 4;
                            if (!matches || nameOffset < 0)
                                continue;
                            stream.Position = nameOffset;
                            int nameLength = reader.ReadInt32();
                            if (nameLength < marker.Length || nameLength > 128
                                || nameLength > stream.Length - stream.Position)
                                continue;
                            string name = System.Text.Encoding.ASCII.GetString(reader.ReadBytes(nameLength));
                            if (!name.StartsWith("Version - ", StringComparison.Ordinal))
                                continue;
                            long valueOffset = (stream.Position + 3L) & ~3L;
                            if (valueOffset > stream.Length - 4)
                                continue;
                            stream.Position = valueOffset;
                            int valueLength = reader.ReadInt32();
                            if (valueLength < 5 || valueLength > 64
                                || valueLength > stream.Length - stream.Position)
                                continue;
                            string rawVersion = System.Text.Encoding.ASCII.GetString(reader.ReadBytes(valueLength));
                            if (settings["log"])
                                print("[REPO] Version UI: name=\"" + name
                                    + "\" | value=\"" + rawVersion + "\"");
                            var match = System.Text.RegularExpressions.Regex.Match(rawVersion.Trim(),
                                @"\A[vV]?(0\.\d+\.\d+(?:\.\d+)?)(?:[-+][A-Za-z0-9.-]+)?\z");
                            Version parsed;
                            if (match.Success && Version.TryParse(match.Groups[1].Value, out parsed))
                                candidates.Add(match.Groups[1].Value);
                        }
                        // Keep enough overlap for markers spanning chunk boundaries.
                        scanPosition += count - marker.Length + 1;
                    }
                }
                if (settings["log"])
                    print("[REPO] Version probe: " + detectionSource + " candidates=["
                        + String.Join(", ", candidates.ToArray()) + "]");
            }

            if (candidates.Count == 1)
            {
                string detected = candidates.First();
                vars.detectedVersion = detected;
                vars.detectedPre04 = new Version(detected) < new Version(0, 4);
                if (settings["log"])
                    print("[REPO] Detected version=" + detected
                        + " | version04OrHigher=" + (vars.detectedPre04 ? "OFF" : "ON")
                        + " | source=" + detectionSource);
            }
            else if (settings["log"])
                print("[REPO] Version detection unavailable/ambiguous; using manual fallback.");
        }
        catch (Exception e)
        {
            if (settings["log"])
                print("[REPO] Version probe failed; using manual fallback: " + e.Message);
        }
    }

    // Override the behavior internally; the manual checkbox is a fallback.
    bool useDetectedVersion = vars.detectedVersion != "";
    bool pre04 = useDetectedVersion ? (bool)vars.detectedPre04 : !settings["version04OrHigher"];
    vars.deathState = pre04 ? 6 : 7;
    version = useDetectedVersion ? (string)vars.detectedVersion : "manual " + (pre04 ? "pre-0.4" : "0.4+");
    string deathMode = version + " | version04OrHigher=" + (pre04 ? "OFF" : "ON")
        + " | deathState=" + vars.deathState;
    if (deathMode != vars.lastDeathMode)
    {
        vars.lastDeathMode = deathMode;
        if (settings["log"])
            print("[REPO] Effective mode: " + deathMode);
    }

    var currentDict = (IDictionary<string, object>)current;
    var oldDict = (IDictionary<string, object>)old;

    if (!currentDict.ContainsKey("levelName"))
    {
        return false;
    }

    if (!currentDict.ContainsKey("state"))
    {
        return false;
    }

    // Log the FIRST readable name as well as changes, including unknown maps.
    string observedLevel = (string)current.levelName;
    if (!String.IsNullOrEmpty(observedLevel) && observedLevel != vars.lastLoggedLevel)
    {
        vars.lastLoggedLevel = observedLevel;
        bool known = vars.RunLevels.Contains(observedLevel);
        if (settings["log"])
        {
            print("[REPO] LEVEL NarrativeName=\"" + observedLevel + "\""
                + " | knownRunLevel=" + known + " | state=" + current.state);
            if (!known && observedLevel != "Main Menu" && observedLevel != "Lobby Menu"
                && observedLevel != "Splash Screen" && observedLevel != "Service Station"
                && observedLevel != "Truck" && observedLevel != "Disposal Arena")
                print("[REPO] Unknown run level; its NarrativeName is not in RunLevels.");
        }
    }

    bool currentIsMenu = current.levelName == "Main Menu" || current.levelName == "Lobby Menu";
    bool currentIsRunLevel = vars.RunLevels.Contains((string)current.levelName);
    bool currentIsSplash = current.levelName == "Splash Screen";
    bool currentInLoading = current.state != 2 && current.state != vars.deathState;

    if (!oldDict.ContainsKey("levelName") || !oldDict.ContainsKey("state"))
    {
        if (!vars.pendingStart
            && currentIsRunLevel
            && !currentIsSplash
            && currentInLoading)
        {
            vars.pendingStart = true;
            vars.pendingStartTick = Environment.TickCount;
            vars.startArmed = false;
        }

        if (vars.pendingStart
            && !vars.startArmed
            && currentIsRunLevel
            && !currentIsSplash
            && currentInLoading
            && Environment.TickCount - vars.pendingStartTick >= vars.startDelayMs)
        {
            vars.startArmed = true;
        }

        vars.dataReady = true;
        return true;
    }

    vars.dataReady = true;

    bool oldIsMenu = old.levelName == "Main Menu" || old.levelName == "Lobby Menu";

    if (current.levelName != old.levelName && currentIsMenu)
    {
        vars.pendingStart = false;
        vars.pendingStartTick = 0;
        vars.startArmed = false;
    }

    if (!vars.pendingStart
        && oldIsMenu
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading)
    {
        vars.pendingStart = true;
        vars.pendingStartTick = Environment.TickCount;
        vars.startArmed = false;
    }

    if (!vars.pendingStart
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading)
    {
        vars.pendingStart = true;
        vars.pendingStartTick = Environment.TickCount;
        vars.startArmed = false;
    }

    if (vars.pendingStart
        && !vars.startArmed
        && currentIsRunLevel
        && !currentIsSplash
        && currentInLoading
        && Environment.TickCount - vars.pendingStartTick >= vars.startDelayMs)
    {
        vars.startArmed = true;
    }

    if (vars.pendingStart
        && !vars.startArmed
        && (!currentIsRunLevel || currentIsSplash || !currentInLoading))
    {
        vars.pendingStart = false;
        vars.pendingStartTick = 0;
        vars.startArmed = false;
    }

    return true;
}

start
{
    if (!(vars.hookReady ?? false))
    {
        return false;
    }

    if (!(vars.dataReady ?? false))
    {
        return false;
    }

    bool currentIsRunLevel = vars.RunLevels.Contains((string)current.levelName);
    bool currentIsSplash = current.levelName == "Splash Screen";

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

        if (settings["log"])
            print("[REPO] START triggered | level=" + current.levelName);

        return true;
    }

    return false;
}

split
{
    if (!(vars.hookReady ?? false) || !(vars.dataReady ?? false))
        return false;

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

    // update selects the effective death state before timer decisions.

    return current.state != 2 && current.state != vars.deathState;
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
            vars.pendingStartTick = 0;
            vars.startArmed = false;

            if (old.levelName == "Tutorial" && current.tutorialStage == 16)
                return false;

            return true;
        }
    }

    return false;
}
