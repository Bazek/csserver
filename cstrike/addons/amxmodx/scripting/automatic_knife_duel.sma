/******************************************************************************/
// If you change one of the following settings, do not forget to recompile
// the plugin and to install the new .amx file on your server.
// You can find the list of admin flags in the amx/examples/include/amxconst.inc file.

#define FLAG_AMX_KNIFECHALLENGE ADMIN_LEVEL_A

// Uncomment the following line to enable the AMX logs for this plugin.
//#define USE_LOGS

/******************************************************************************/

#define PLUGINNAME	"Automatic Knife Duel"
#define VERSION	"0.4"
#define AUTHOR		"JGHG"

/*
Copyleft 2005-2012
Plugin -> http://www.amxmod.net


AUTOMATIC KNIFE DUEL
====================
Where I come from, if you cut the wall repeteadly with your knife it means you're challenging your last opponent to a knife duel. ;-)

I decided to automate this process.

If only you and another person on the opposite team remain in the round, you can hit a wall (or another object) with your knife.
By this action you challenge your opponent to a knife duel. The person you challenge gets a menu where he can accept/decline your
challenge. The challenged person has 10 seconds to decide his mind, else the challenge is automatically declined, and the menu should be closed automatically.

Should a knife duel start, it works out pretty much like a round of Knife Arena: you can only use the knife (and the C4!).
As soon as the round ends the Knife Arena mode is turned off.

/JGHG


VERSIONS
========
120618	0.4	Some modifications/improvements and made available all the time the cmd to force ONE knife duel.
050219	0.3	Added a cvar "autoduel_knifehits" to change the number of times you have to knife a wall/surface to trigger the duel (by KRoT@L).
050208	0.2	Fixed seconds display.
			Bots should now respond correctly and a little human like. They will mostly accept challenges. ;-)
			Small fixes here and there. :-)
050208	0.1	First version - largely untested
*/

#include <translator>
#include <amxmod>
#include <amxmisc>
#include <fun>
#include <VexdUM>

#define MENUSELECT1				0
#define MENUSELECT2				1
#define TASKID_CHALLENGING		2348923
#define TASKID_BOTTHINK			3242321
#define DECIDESECONDS			10.0

#define cs_get_user_team(%1) get_offset_int(%1, 114)

#if !defined charsmax
	#define charsmax(%1) sizeof(%1) - 1
#endif

// Globals below
const g_allowedWeapons = (1<<CSW_KNIFE|1<<CSW_C4)
const TASKID_reset_knife_hits = 1019798

new g_MAXPLAYERS
new bool:g_challenging = false
new bool:g_knifeArena = false
new bool:g_noChallengingForAWhile = false
new g_challengemenu
new g_challenger
new g_challenged
new knife_hits[33]
new g_cvar_autoduel_knifehits
new g_cvar_mp_friendlyfire
// Globals above

public plugin_init() {
	load_translations("automatic_knife_duel")
	register_plugin(_T(PLUGINNAME), VERSION, AUTHOR)
	register_concmd("amx_knifechallenge", "challengefn", FLAG_AMX_KNIFECHALLENGE, _T("<challenger: name|#userid|authid> <challenged: name|#userid|authid> - starts knife duel challenge"))

	g_cvar_autoduel_knifehits = register_cvar("autoduel_knifehits", "3")
	g_cvar_mp_friendlyfire = get_cvar_pointer("mp_friendlyfire")

	g_challengemenu = register_menuid("You are challenged by ")
	register_menucmd(g_challengemenu, MENU_KEY_1|MENU_KEY_2, "challenged_menu")

	register_event("DeathMsg", "event_death", "a")
	register_event("CurWeapon", "event_holdwpn", "be", "1=1")
	register_event("ResetHUD", "spawn_event", "be")
	register_logevent("event_roundend", 2, "1=Round_End")
	//register_event("SendAudio", "event_roundend", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	//register_event("TextMsg", "event_roundend", "a", "2&#Game_C", "2&#Game_w")
	register_logevent("NoChallengingForAWhileToFalse", 2, "0=World triggered", "1=Round_Start")

	g_MAXPLAYERS = get_maxplayers()
}

public challengefn(id, level, cid) {
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	if(g_knifeArena) {
		console_print(id, _T("There is already a knife challenge between two players, only one challenge is allowed at the same time."))
		return PLUGIN_HANDLED
	}

	new challenger[32], challenged[32]
	read_argv(1, challenger, charsmax(challenger))
	read_argv(2, challenged, charsmax(challenged))
	new challengerIndex = cmd_target(id, challenger, 7)
	new challengedIndex = cmd_target(id, challenged, 7)
	if(!challengerIndex || !challengedIndex)
		return PLUGIN_HANDLED

	if(challengerIndex == challengedIndex) {
		console_print(id, _T("You can't start a knife challenge with the same player for challenger and challenged."))
		return PLUGIN_HANDLED
	}

	if(get_cvarptr_num(g_cvar_mp_friendlyfire) == 0 && cs_get_user_team(challengerIndex) == cs_get_user_team(challengedIndex)) {
		console_print(id, _T("You can't start a knife challenge with two players of the same team when ^"mp_friendlyfire^" cvar is disabled (0)."))
		return PLUGIN_HANDLED
	}

	new szAdminName[32], szChallengerName[32], szChallengedName[32]
	get_user_name(challengerIndex, szChallengerName, charsmax(szChallengerName))
	get_user_name(challengedIndex, szChallengedName, charsmax(szChallengedName))

	if(id > 0) {
		if(id != challengerIndex && id != challengedIndex) {
			get_user_name(id, szAdminName, charsmax(szAdminName))
		}
		else {
			szAdminName = (id == challengerIndex) ? szChallengerName : szChallengedName
		}
	}
	else {
		copy(szAdminName, charsmax(szAdminName), "SERVER")
	}

	console_print(id, _T("You started a knife challenge with ^"%s^" as challenger and ^"%s^" as challenged."), szChallengerName, szChallengedName)

	#if !defined COLORED_ACTIVITY
	show_activity(id, szAdminName, _T("start a knife challenge with ^"%s^" as challenger and ^"%s^" as challenged."), szChallengerName, szChallengedName)
	#else
	show_activity_color(id, szAdminName, _T("start a knife challenge with ^"%s^" as challenger and ^"%s^" as challenged."), szChallengerName, szChallengedName)
	#endif

	Challenge(challengerIndex, challengedIndex)
	if(is_user_bot(challengedIndex)) {
		g_challenging = false
		Accept()
	}

	#if defined USE_LOGS
	new szChallengerAuthID[24], szChallengerIPAddress[24]
	new szChallengedAuthID[24], szChallengedIPAddress[24]
	get_user_authid(challengerIndex, szChallengerAuthID, charsmax(szChallengerAuthID))
	get_user_ip(challengerIndex, szChallengerIPAddress, charsmax(szChallengerIPAddress))
	get_user_authid(challengedIndex, szChallengedAuthID, charsmax(szChallengedAuthID))
	get_user_ip(challengedIndex, szChallengedIPAddress, charsmax(szChallengedIPAddress))

	if(id > 0) {
		new szAdminAuthID[24], szAdminIPAddress[24]
		if(id != challengerIndex && id != challengedIndex) {
			get_user_authid(id, szAdminAuthID, charsmax(szAdminAuthID))
			get_user_ip(id, szAdminIPAddress, charsmax(szAdminIPAddress))
		}
		else {
			szAdminAuthID = (id == challengerIndex) ? szChallengerAuthID : szChallengedAuthID
			szAdminIPAddress = (id == challengerIndex) ? szChallengerIPAddress : szChallengedIPAddress
		}
		log_amx("%s: ^"<%s><%d><%s><%s>^" start a knife challenge with: ^"<%s><%d><%s><%s>^" (challenger) ^"<%s><%d><%s><%s>^" (challenged).",
		PLUGINNAME, szAdminName, get_user_userid(id), szAdminAuthID, szAdminIPAddress,
		szChallengerName, get_user_userid(challengerIndex), szChallengerAuthID, szChallengerIPAddress,
		szChallengedName, get_user_userid(challengedIndex), szChallengedAuthID, szChallengedIPAddress)
	}
	else {
		log_amx("%s: <SERVER> start a knife challenge with: ^"<%s><%d><%s><%s>^" (challenger) ^"<%s><%d><%s><%s>^" (challenged).",
		PLUGINNAME, szChallengerName, get_user_userid(challengerIndex), szChallengerAuthID, szChallengerIPAddress,
		szChallengedName, get_user_userid(challengedIndex), szChallengedAuthID, szChallengedIPAddress)
	}
	#endif

	return PLUGIN_HANDLED
}

public emitsound(entity, const sample[]) {
	if(g_noChallengingForAWhile || g_knifeArena || g_challenging || entity < 1 || entity > g_MAXPLAYERS
	|| !(sample[8] == 'k' && sample[14] == 'h' && sample[21] == '1' && equal(sample, "weapons/knife_hitwall1.wav")) || !is_user_alive(entity))
		return PLUGIN_CONTINUE

	new knifehits = get_cvarptr_num(g_cvar_autoduel_knifehits)
	if(++knife_hits[entity] == knifehits) {
		new team = cs_get_user_team(entity), otherteam = 0, matchingOpponent = 0
		// Make sure exactly one person on each team is alive.
		for(new i = 1; i <= g_MAXPLAYERS; i++) {
			if(entity == i || !is_user_alive(i))
				continue

			if(cs_get_user_team(i) == team) {
				// No fun.
				return PLUGIN_CONTINUE
			}
			else {
				if (++otherteam > 1) {
					// No fun.
					return PLUGIN_CONTINUE
				}
				matchingOpponent = i
			}
		}

		if(matchingOpponent == 0)
			return PLUGIN_CONTINUE

		Challenge(entity, matchingOpponent)
		if(is_user_bot(matchingOpponent)) {
			new Float:val = DECIDESECONDS
			if (val < 2.0)
				val = 2.0
			remove_task(TASKID_BOTTHINK)
			set_task(random_float(1.0, DECIDESECONDS - 1.0), "BotDecides", TASKID_BOTTHINK)
		}
	}
	else {
		if(!task_exists(TASKID_reset_knife_hits+entity)) {
			set_task((knifehits*1.0)-1.0, "reset_knife_hits", TASKID_reset_knife_hits+entity)
		}
	}

	return PLUGIN_CONTINUE
}

public reset_knife_hits(id) {
	knife_hits[id - TASKID_reset_knife_hits] = 0
}

public BotDecides() {
	if(!g_challenging)
		return

	if(random(4) > 0)
		Accept()
	else {
		DeclineMsg()
	}
	g_challenging = false
	remove_task(TASKID_CHALLENGING)
}

Challenge(challenger, challenged) {
	g_challenger = challenger
	g_challenged = challenged
	g_challenging = true
	new challenger_name[32], challenged_name[32]
	get_user_name(challenger, challenger_name, charsmax(challenger_name))
	get_user_name(challenged, challenged_name, charsmax(challenged_name))

	client_print(challenger, print_chat, _T("You challenge %s to a knife duel! Await the answer within %.f seconds..."), challenged_name, DECIDESECONDS)

	new menu[256]
	const keys = MENU_KEY_1|MENU_KEY_2
	formatex(menu, charsmax(menu), _T("You are challenged by \y%s \wto a knife duel!^n^nWhat will it be? You have \y%.f \wseconds to answer!^n^n1. Bring it on!^n2. No, I'd rather use my boomstick!", challenged), challenger_name, DECIDESECONDS)
	show_menu(challenged, keys, menu, -1, "You are challenged by ")
	set_task(DECIDESECONDS, "timed_closemenu", TASKID_CHALLENGING)
}

public timed_closemenu() {
	if(g_challenging) {
		new challenger_name[32], challenged_name[32]
		get_user_name(g_challenger, challenger_name, 31)
		get_user_name(g_challenged, challenged_name, 31)
		client_print(0, print_chat, _T("%s didn't answer %s's knife duel challenge fast enough..."), challenged_name, challenger_name)
		CancelAll()
	}
}

public challenged_menu(id, key) {
	switch(key) {
		case MENUSELECT1: {
			// Accept
			Accept()
		}
		case MENUSELECT2: {
			// Decline
			DeclineMsg()
		}
	}
	g_challenging = false
	remove_task(TASKID_CHALLENGING)

	return PLUGIN_HANDLED
}

DeclineMsg() {
	new challenger_name[32], challenged_name[32]
	get_user_name(g_challenger, challenger_name, 31)
	get_user_name(g_challenged, challenged_name, 31)
	client_print(0, print_chat, _T("%s turns down %s's knife duel challenge..."), challenged_name, challenger_name)
}

Accept() {
	new challenger_name[32], challenged_name[32]
	get_user_name(g_challenger, challenger_name, 31)
	get_user_name(g_challenged, challenged_name, 31)

	client_print(0, print_chat, _T("%s accepts %s's knife duel challenge!"), challenged_name, challenger_name)
	g_knifeArena = true

	new const itemName[] = "weapon_knife"

	if(!has_user_weapon(g_challenger, CSW_KNIFE))
		give_item(g_challenger, itemName)
	if(!has_user_weapon(g_challenged, CSW_KNIFE))
		give_item(g_challenged, itemName)

	engclient_cmd(g_challenger, itemName)
	engclient_cmd(g_challenged, itemName)
}

public event_holdwpn(id) {
	if(!g_knifeArena || id != g_challenger && id != g_challenged)
		return

	new weaponType = 1<<read_data(2)

	if((weaponType & g_allowedWeapons) == 0)
		engclient_cmd(id, "weapon_knife")
}

public spawn_event(id) {
	knife_hits[id] = 0
}

public event_roundend() {
	if(g_challenging || g_knifeArena)
		CancelAll()
	g_noChallengingForAWhile = true
}

public NoChallengingForAWhileToFalse() {
	g_noChallengingForAWhile = false
}

CancelAll() {
	if(g_challenging) {
		g_challenging = false
		// Close menu of challenged
		new usermenu, userkeys
		get_user_menu(g_challenged, usermenu, userkeys) // get user menu
		if(usermenu == g_challengemenu) // Close it!
			show_menu(g_challenged, 0, "NULL", 0, "NULL") // show empty menu
	}
	if(g_knifeArena) {
		g_knifeArena = false
	}
	remove_task(TASKID_BOTTHINK)
	remove_task(TASKID_CHALLENGING)
}

public event_death() {
	new victim
	if((g_challenging || g_knifeArena) && ((victim = read_data(2)) == g_challenger || victim == g_challenged))
		CancelAll()
}

public client_disconnect(id) {
	if((g_challenging || g_knifeArena) && (id == g_challenger || id == g_challenged)) {
		new szName[32]
		get_user_name(id, szName, charsmax(szName))
		client_print((id == g_challenger) ? g_challenged : g_challenger, print_chat, _T("Your opponent ^"%s^" has left the server. Knife challenge canceled."), szName)
		if(id == g_challenged) {
			g_challenging = false
		}
		CancelAll()
	}
}
