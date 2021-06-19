#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <PrimeManager>

#undef REQUIRE_PLUGIN
#include <vip_core>

int			g_iType,
			g_iVipServerID;
bool		g_bVipLoaded,
			g_bVipMySQL;
ArrayList	g_hVipPlayers;
Database	g_hVipDatabase;

public Plugin myinfo =
{
	name		= "[PM] Kick Non Prime",
	author		= "OkyHp",
	version		= "1.0.0",
	url			= "OkyHek#2441, https://prime.napas.cc/"
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

public void OnLibraryAdded(const char[] szName)
{
	CheckVip(szName, true);
}

public void OnLibraryRemoved(const char[] szName)
{
	CheckVip(szName, false);
}

void CheckVip(const char[] szName, bool bState)
{
	if(!strcmp(szName, "vip_core"))
	{
		g_bVipLoaded = bState;
	}
}

public void OnPluginStart()
{
	ConVar Convar;
	(Convar = CreateConVar(
		"sm_pm_kick_non_prime_type",	"0",
		"Work type: 0 - Ignore non prime for admins/vips; 1 - Kick all non prime players.",
		_, true, 0.0, true, 1.0
	)).AddChangeHook(ChangeCvar_Type);
	ChangeCvar_Type(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "PM_KickNonPrime");
	LoadTranslations("PM_KickNonPrime.phrases");
	
	g_hVipPlayers = new ArrayList();

	if (g_bVipLoaded && VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

void ChangeCvar_Type(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_iType = Convar.IntValue;

	if (g_iType)
	{
		g_hVipPlayers.Clear();
	}
	
	OnMapStart();
}

public void VIP_OnVIPLoaded()
{
	if(!g_hVipDatabase)
	{
		g_hVipDatabase = VIP_GetDatabase();

		if ((g_bVipMySQL = VIP_GetDatabaseType()))
		{
			g_iVipServerID = FindConVar("sm_vip_server_id").IntValue;
		}
	}
}

public void OnMapStart()
{
	if (!g_iType && g_hVipDatabase)
	{
		char szQuery[64];
		if (g_bVipMySQL)
		{
			FormatEx(szQuery, sizeof(szQuery), "WHERE `sid` = '0' OR `sid` = '%i'", g_iVipServerID);
		}
		Format(szQuery, sizeof(szQuery), "SELECT `account_id` FROM `vip_users` %s;", szQuery);
		g_hVipDatabase.Query(SQL_GetVips_Callback, szQuery);
	}
}

void SQL_GetVips_Callback(Database hDatabase, DBResultSet hResult, const char[] szError, any Data)
{
	if (!hResult || szError[0])
	{
		LogError("SQL_GetVips_Callback: %s", szError);
		return;
	}

	g_hVipPlayers.Clear();
	while(hResult.FetchRow())
	{
		g_hVipPlayers.Push(hResult.FetchInt(0));
	}
}

public void VIP_OnVIPClientAdded(int iClient, int iAdmin)
{
	if (!g_iType)
	{
		int iAccountID = GetSteamAccountID(iClient, true);
		if (iAccountID && g_hVipPlayers.FindValue(iAccountID) == -1)
		{
			g_hVipPlayers.Push(iAccountID);
		}
	}
}

public void PM_OnClientDataPrimeLoadedPost(int iClient, int iAccountID, PrimeState ePrime)
{
	if (ePrime == NonPrimeAccount)
	{
		if (!g_iType)
		{
			if (FindAdminByIdentity(AUTHMETHOD_STEAM, GetSteamID2(iAccountID)) == INVALID_ADMIN_ID 
				|| (g_bVipLoaded && g_hVipPlayers.FindValue(iAccountID) == -1))
			{
				KickClient(iClient, "%T%T", "Kick_Reason", iClient, "Kick_AdmOrVip", iClient);
			}
		}
		else
		{
			KickClient(iClient, "%T", "Kick_Reason", iClient);
		}
	}
}

char[] GetSteamID2(int iAccountID)
{
	static char szSteamID2[22] = "STEAM_1:";
	FormatEx(szSteamID2[8], 14, "%i:%i", iAccountID & 1, iAccountID >>> 1);
	return szSteamID2;
}
