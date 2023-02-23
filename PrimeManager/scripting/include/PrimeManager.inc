#if defined _prime_manager_included
 #endinput
#endif
#define _prime_manager_included

public SharedPlugin __pl_prime_manager= 
{
	name = "PrimeManager",
	file = "PrimeManager.smx",
	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_fire_players_stats_SetNTVOptional()
{
	MarkNativeAsOptional("PM_GetClientPrimeStatus");
}
#endif

enum PrimeState
{
	NotLoaded = 0,
	PrimeAccount,
	NonPrimeAccount,
    IgnoredPlayer
};

/**
 *	Get account state.
 *
 *	@param iClient				Player index.
 *	@return						Account prime state.
*/
native PrimeState PM_GetClientPrimeStatus(int iClient);

/**
 *	Called after request response.
 *
 *	@param iClient				Attacker index.
 *	@param ePrime				Account prime state.
 *	@return						Plugin_Changed, Plugin_Handled or Plugin_Stop - Change account prime state;
 								Plugin_Continue - Continue execution.
*/
forward Action PM_OnClientDataPrimeLoaded(int iClient, PrimeState &ePrime);

/**
 *	Called after responding to request and processing it in PRE.
 *
 *	@param iClient				Attacker index.
 *	@param ePrime				Account prime state.
 *	@noreturn
*/
forward void PM_OnClientDataPrimeLoadedPost(int iClient, PrimeState ePrime);