#pragma semicolon 1

#include <sourcemod>
#include <PrimeManager>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= 	"[PM] Tag",
	author		= 	"Fr4nch",
	version		= 	"1.0",
	description =	"Changing the clan tag to non-Prime players",
	url			= 	"Fr4nch#3657, https://prime.napas.cc/"
};

char g_sTag[16];

public void OnPluginStart()
{
	ConVar Convar;

	(Convar = CreateConVar("sm_pm_tag",		"[No Prime]", 
		"RU: Клан тег для игроков без прайма \n\
		EN: Clan tag for non-prime players"
	)).AddChangeHook(ChangeCvar_Tag);
	ChangeCvar_Tag(Convar, NULL_STRING, NULL_STRING);
	
	AutoExecConfig(true, "PM_Tag");
}

void ChangeCvar_Tag(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	Convar.GetString(g_sTag, sizeof g_sTag);
}

public void PM_OnClientDataPrimeLoadedPost(int iClient, PrimeState ePrime)
{
	if (IsValidClient(iClient))
	{
		if (ePrime == NonPrimeAccount)
		{
			CS_SetClientClanTag(iClient, g_sTag);
		}
	}
}

public void OnClientSettingsChanged(int iClient)
{
	if (IsValidClient(iClient))
	{
		if (PM_GetClientPrimeStatus(iClient) == NonPrimeAccount)
		{
			static char sBuffer[16];

			CS_GetClientClanTag(iClient, sBuffer, sizeof sBuffer);

			if (strcmp(sBuffer, g_sTag) != 0)
			{
				CS_SetClientClanTag(iClient, g_sTag);
			}
		}
	}
}

bool IsValidClient(int iClient)
{
	if (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		return true;
	}
	return false;
}