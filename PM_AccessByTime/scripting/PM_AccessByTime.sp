#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <PrimeManager>

#define START	0
#define STOP	1

bool	g_bCanAccess;
float	g_fCheckTime[2];

public Plugin myinfo =
{
	name		= "[PM] Access By Time",
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

public void OnPluginStart()
{
	ConVar Convar;
	(Convar = CreateConVar(
		"sm_pm_access_by_time_start",	"02.00",
		"Time of start ignore non-prime players."
	)).AddChangeHook(ChangeCvar_TimeStart);
	ChangeCvar_TimeStart(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar(
		"sm_pm_access_by_time_stop",	"06.00",
		"Time of stop ignore non-prime players."
	)).AddChangeHook(ChangeCvar_TimeStop);
	ChangeCvar_TimeStop(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "PM_AccessByTime");
}

void ChangeCvar_TimeStart(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_fCheckTime[START] = Convar.FloatValue;
}

void ChangeCvar_TimeStop(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_fCheckTime[STOP] = Convar.FloatValue;
}

public void OnMapStart()
{
	char szBuffer[8];
	FormatTime(szBuffer, sizeof(szBuffer), "%H.%M");
	float fTime = StringToFloat(szBuffer);

	g_bCanAccess = (g_fCheckTime[START] < g_fCheckTime[STOP]) ? (
			fTime >= g_fCheckTime[START] && fTime < g_fCheckTime[STOP]
		) : (
			(fTime >= g_fCheckTime[START] && fTime > g_fCheckTime[STOP]) || (fTime <= g_fCheckTime[START] && fTime < g_fCheckTime[STOP])
		);
	
	PrintToServer("[PM] Access By Time: %s | CurTime: %.2f | StartTime: %.2f | StopTime: %.2f", 
		g_bCanAccess ? "TRUE":"FALSE", 
		fTime, 
		g_fCheckTime[START], 
		g_fCheckTime[STOP]
	);
}

public Action PM_OnClientDataPrimeLoaded(int iClient, PrimeState &ePrime)
{
	if (g_bCanAccess && ePrime == NonPrimeAccount)
	{
		ePrime = IgnoredPlayer;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
