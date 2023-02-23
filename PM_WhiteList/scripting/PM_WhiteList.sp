#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <PrimeManager>

ArrayList	g_hWhiteList;

public Plugin myinfo =
{
	name		= "[PM] White List",
	author		= "OkyHp",
	version		= "1.1.0",
	url			= "OkyHek#2441"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErr_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iErr_max, "This plugin works only on CS:GO!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hWhiteList = new ArrayList();
}

public void OnMapStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/PM_WhiteList.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(!hFile)
	{
		SetFailState("Config '%s' not found!", szBuffer);
		return;
	}

	g_hWhiteList.Clear();
	while(!hFile.EndOfFile() && hFile.ReadLine(szBuffer, sizeof(szBuffer)))
    {
        TrimString(szBuffer);
        if(!szBuffer[0] || szBuffer[0] == '/')
		{
			continue;
		}

        g_hWhiteList.Push(StringToInt(szBuffer));
    }

	delete hFile;
}

public Action PM_OnClientDataPrimeLoaded(int iClient, PrimeState &ePrime)
{
	ePrime = IgnoredPlayer;

	return (g_hWhiteList.FindValue(GetSteamAccountID(iClient)) != -1 ? Plugin_Changed : Plugin_Continue);
}
