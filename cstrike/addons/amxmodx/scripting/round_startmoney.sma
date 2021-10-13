#include <amxmodx>
#include <hamsandwich>
#include <cstrike>

#define PLUGIN "round_startmoney"
#define VERSION "1.1"
#define AUTHOR "melbs"

new g_money;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_money = get_cvar_pointer("mp_startmoney");
	RegisterHam(Ham_Spawn, "player", "onSpawn", 1);
}

public onSpawn(pPlayer)
{
	if ( is_user_alive(pPlayer) )
	{
		new pMoney = get_pcvar_num(g_money);
		
		if(cs_get_user_money(pPlayer) < pMoney)
		{
			cs_set_user_money(pPlayer, pMoney);
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
