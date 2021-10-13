#include <amxmodx> 
#include <hamsandwich> 
#include <fun> 
#include <fakemeta> 

#pragma semicolon 1 

#define PLUGIN "Anti Spawn Kill" 
#define VERSION "1.5.bazek"
#define AUTHOR "FuckTheSchool ( Eyal282 )" 

new cEnable, cType, cShoot, cTimer, Timer[33]; 
new get_maximumplayers; 
new const TASKID_SK = 938459348; 
new bool:Shot[33]; 

new Weapons[][] =  
{ 
    "weapon_p228", 
    "weapon_scout", 
    "weapon_hegrenade", 
    "weapon_xm1014", 
    "weapon_mac10", 
    "weapon_aug", 
    "weapon_smokegrenade", 
    "weapon_elite", 
    "weapon_fiveseven", 
    "weapon_ump45", 
    "weapon_sg550", 
    "weapon_galil", 
    "weapon_famas", 
    "weapon_usp", 
    "weapon_glock18", 
    "weapon_awp", 
    "weapon_mp5navy", 
    "weapon_m249", 
    "weapon_m3", 
    "weapon_m4a1", 
    "weapon_tmp", 
    "weapon_g3sg1", 
    "weapon_flashbang", 
    "weapon_deagle", 
    "weapon_sg552", 
    "weapon_ak47", 
    "weapon_knife", 
    "weapon_p90" 
}; 

new SecWeapons[][] = 
{ 
    "weapon_scout",  
    "weapon_aug", 
    "weapon_sg550", 
    "weapon_awp", 
    "weapon_g3sg1", 
    "weapon_knife", 
    "weapon_sg552" 
}; 
public plugin_init() 
{ 
    register_plugin(PLUGIN, VERSION, AUTHOR); 
     
    cEnable = register_cvar("amx_antisk_enable", "1"); // 1 = Plugin is enabled, 0 = Plugin is not enabled. 
    cType = register_cvar("amx_antisk_type", "1"); // 0 = Godmode will be given to player, 1 = Player will not receive any damage from other players ( fall damage and others ) 
    cTimer = register_cvar("amx_antisk_timer", "5"); // For how long will anti SK Work 
    cShoot = register_cvar("amx_antisk_shoot", "1"); // 1 = Shooting / Sniping will remove spawn kill protection, 0 = Shooting / Sniping will not remove spawn kill protection 
     
    register_event("HLTV", "RoundStart", "a", "1=0", "2=0"); 
     
    for(new i;i < sizeof(Weapons);i++) 
        RegisterHam(Ham_Weapon_PrimaryAttack, Weapons[i], "RemoveProtection"); 
     
    for(new i;i < sizeof(SecWeapons);i++) 
        RegisterHam(Ham_Weapon_SecondaryAttack, SecWeapons[i], "RemoveProtection"); // Not all weapons have sec attacks. 
         
    RegisterHam(Ham_TakeDamage, "player", "HamBurger_Damage"); 
    RegisterHam(Ham_Spawn, "player", "HamBurger_Spawn", 1); 

    get_maximumplayers = get_maxplayers(); 
     
    set_task(1.0, "ShowTimer", TASKID_SK,_,_, "b"); 
    //register_dictionary("AntiSpawnKill.txt"); 
} 

public RoundStart() 
{ 
    if(!get_pcvar_num(cEnable)) 
        return; 
     
    arrayset(Shot, false, sizeof(Shot)); 
    change_task(TASKID_SK); 
} 

public HamBurger_Damage(victim, inflictor, attacker, Float:damage, damagebits) 
{ 
    if(!is_user_connected(victim)) 
        return HAM_IGNORED; 
         
    if(get_pcvar_num(cType) && Timer[victim] > 0 && victim != attacker && 1 <= attacker <= get_maximumplayers) 
        return HAM_SUPERCEDE; 
     
    return HAM_IGNORED; 
} 

public HamBurger_Spawn(id) 
{ 
	if(is_user_alive(id))
		Timer[id] = get_pcvar_num(cTimer) + 1; 
} 


public ShowTimer() 
{         
	new players[32], num, i, pcvarType = get_pcvar_num(cType); 
	get_players(players, num, "a"); 
	
	for(new id;id < num;id++) 
	{     
		i = players[id];
		
		if(Shot[i]) 
		continue; 
			
		Timer[i]--; 
			
		if(Timer[i] == 0) 
		{ 
			set_hudmessage(255, 255, 0, -1.0, -1.0, 0, 0.0, 1.5, 0.0, 1.0); 
			show_hudmessage(i, "Spawn Protection Expired.");     
		
			if(pcvarType) 
				set_user_godmode(i, 0); 
		} 
		else if(Timer[i] > 0) 
		{ 
			set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 0.0, 0.99, 0.0, 0.0); 
			show_hudmessage(i, "Spawn Protection: %i Second%s Left...", Timer[i], Timer[i] == 1 ? "" : "s"); 
			
			if(pcvarType) 
				set_user_godmode(i, 1); 
		} 
	} 
}  
	
public RemoveProtection(Weapon) 
{ 
    if(pev_valid(Weapon)) 
    { 
        new id = get_pdata_cbase(Weapon, 41, 4); // The offset name of 41 is m_pPlayer. 
         
        if(Timer[id] == 0) 
            return HAM_IGNORED; 
             
        else if(!get_pcvar_num(cEnable)) 
            return HAM_IGNORED; 
             
        else if(!get_pcvar_num(cShoot)) 
            return HAM_IGNORED; 

        set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 0.0, 1.5, 0.0, 0.0); 
        show_hudmessage(id, "Spawn Protection Disabled - Weapon Used!"); 

        Shot[id] = true; 
        set_user_godmode(id); 
    } 
             
    return HAM_IGNORED; 
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1037\\ f0\\ fs16 \n\\ par }
*/
