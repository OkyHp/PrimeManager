#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <PrimeManager>

int			m_pPersonaDataPublic = -1;
PrimeState	g_ePlayerPrime[MAXPLAYERS+1];
Handle		g_hGlobalForward_OnClientDataPrimeLoaded,
			g_hGlobalForward_OnClientDataPrimeLoadedPost;

public Plugin myinfo =
{
	name		= "Prime Manager",
	author		= "OkyHp",
	version		= "2.0.0",
	url			= "OkyHek#2441"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErr_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iErr_max, "This plugin works only on CS:GO!");
		return APLRes_SilentFailure;
	}

	CreateNative("PM_GetClientPrimeStatus", Native_PM_GetClientPrimeStatus);
	RegPluginLibrary("PrimeManager");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	m_pPersonaDataPublic = FindSendPropInfo("CCSPlayer", "m_unMusicID") + 0xA;
	
	g_hGlobalForward_OnClientDataPrimeLoaded		= CreateGlobalForward("PM_OnClientDataPrimeLoaded", ET_Hook, Param_Cell, Param_CellByRef);
	g_hGlobalForward_OnClientDataPrimeLoadedPost	= CreateGlobalForward("PM_OnClientDataPrimeLoadedPost", ET_Ignore, Param_Cell, Param_Cell);
}

Action CallForward_OnClientDataPrimeLoaded(int iClient, PrimeState &ePrime)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForward_OnClientDataPrimeLoaded);
	Call_PushCell(iClient);
	Call_PushCellRef(ePrime);
	Call_Finish(Result);
	return Result;
}

void CallForward_OnClientDataPrimeLoadedPost(int iClient, PrimeState ePrime)
{
	Call_StartForward(g_hGlobalForward_OnClientDataPrimeLoadedPost);
	Call_PushCell(iClient);
	Call_PushCell(ePrime);
	Call_Finish();
}

// PrimeState PM_GetClientPrimeStatus(int iClient);
int Native_PM_GetClientPrimeStatus(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient < 1 || iClient > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[PM] Invalid client index '%i'.", iClient);
		return 0;
	}

	return view_as<int>(g_ePlayerPrime[iClient]);
}

// Thanks Wend4r
bool IsPrimeClient(int iClient)
{
	Address pPersonaDataPublic = view_as<Address>(GetEntData(iClient, m_pPersonaDataPublic));
	if(pPersonaDataPublic != Address_Null)
	{
		return view_as<bool>(LoadFromAddress(pPersonaDataPublic + view_as<Address>(20), NumberType_Int8));
	}
	
	return false;
}

public void OnClientPutInServer(int iClient)
{
	if (!IsFakeClient(iClient) && !IsClientSourceTV(iClient))
	{
		g_ePlayerPrime[iClient] = IsPrimeClient(iClient) ? PrimeAccount : NonPrimeAccount;
		PrimeState ePlayerPrime = g_ePlayerPrime[iClient];

		Action aResult = CallForward_OnClientDataPrimeLoaded(iClient, ePlayerPrime);
		if (aResult != Plugin_Continue)
		{
			g_ePlayerPrime[iClient] = ePlayerPrime;
		}
		CallForward_OnClientDataPrimeLoadedPost(iClient, g_ePlayerPrime[iClient]);
	}
}

public void OnClientDisconnect(int iClient)
{
	g_ePlayerPrime[iClient] = NotLoaded;
}