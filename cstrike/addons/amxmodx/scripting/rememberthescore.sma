/*
	Plugin: Remember the Score
	Current Version: 1.0.791
	
	Author: Nextra
	E-Mail: nextra.24@gmail.com
	
	Support-Thread: http://forums.alliedmods.net/showthread.php?t=88034
	
			AMX Mod X script.
		
		This program is free software; you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation; either version 2 of the License, or (at
		your option) any later version.

		This program is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
		General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program; if not, write to the Free Software Foundation,
		Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

		In addition, as a special exception, the author gives permission to
		link the code of this program with the Half-Life Game Engine ("HL
		Engine") and Modified Game Libraries ("MODs") developed by Valve,
		L.L.C ("Valve"). You must obey the GNU General Public License in all
		respects for all of the code used other than the HL Engine and MODs
		from Valve. If you modify this file, you may extend this exception
		to your version of the file, but you are not obligated to do so. If
		you do not wish to do so, delete this exception statement from your
		version.
	
	.: Description
	
		This plugin will keep track of players' scores through a mysql (or optionally sqlite) database.
		Everytime the user joins the server his score will be set to what is saved in the database (i.e.
		the score he has left the server with last time).
		It was done as per request.
		
	.: Features
	
		- Automatic saving on disconnect + configurable prevention saving to minimize loss of data after a crash
		- Automatic pruning and per-map storing
		- Uses threaded-querying
		- Configuration of when and what to save
		- API to allow for easy implementation into other plugins
		
	.: Cvars
	
		rts_host 	- DB Host
		rts_user 	- DB User
		rts_pass 	- DB Password
		rts_db		- DB
		rts_table	- DB Table
		rts_type	- DB Type (mysql or sqlite)
		rts_auth	- Track users by:
						0 = steamid
						1 = ip
						2 = name
		rts_max		- Maximum of Score/Deaths to save (score saved in db will not go beyond this value)
		rts_min		- Score minimum to save (deaths minimum if rts_track = 2)
		rts_prune	- When to prune data (in days, 0 = disable)
		rts_permap	- Only save for one map. Table gets emptied completely on a new map. (Overrides rts_prune, rts_max and rts_min)
		rts_track	- What to track:
						1 = track score
						2 = track deaths
						3 = track both
						0 = plugin disabled
		rts_save	- The plugin saves on disconnect, additionally (prevents loss of data on crash) save on: 
						0 = never
						1 = roundend 
						2 = every respawn (for deathmatch servers) 
						3 = every score update (may cause lots of traffic)
	
	.: Required Modules
	
		- CStrike
		- FakeMeta
		- Ham Sandwich
		- MySQL / SQLite
		
	.: Notes
	
		#1 - I know that there is a plugin that essentially does the same but as I said this was a request,
		done due to the other one not working for the requester. I just wanted to share this in the hope it 
		will be useful for others. For clearance why there are no credits: This was entirely done from scratch -
		no code was taken from any (esp. not rememberthefrags) plugins in the creation process.
		
		#2 - I made the plugin rts_complement to showcase the API functions of RTS. It is made to be used
		as a reference and therefore only includes limited features, do not expect anything special from it.
		
		#3 - This plugin did not go through much testing, unlike I usually prefer to do it with my stuff. 
		This is because I currently do not need it myself. It is, however, working without errors for a few 
		days on the	requesters server (MySQL). SQLite has been only tested locally but everything should work
		fine. Please report any bugs you may encounter.
	
	.: Changelog
	
		* 1.0.785
		- Initial release.
		
		* 1.0.786
		- Optimization by caching is_user_connected and is_user_bot.
		
		* 1.0.790
		- Implemented cvar to define how players are tracked (steamid, ip, name).
		
		* 1.0.791
		- Fixed not escaping strings for nickname saving.
		
		* 1.0.800
		- Fixed Auth problems.
		- Added integrity checks and sync setting for SQLite, fixing problems that occured for some.
		
		* 1.0.810
		- Fixed typo.
		- Changed errorlogging in startup routine to now use set_fail_and_fwd.
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#pragma loadlib	sqlite
#pragma loadlib	mysql

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>

//----------------------------------------------------------------------------------------
// Do not change anything below this line if you don't know exactly what you are doing!
//----------------------------------------------------------------------------------------
new const PLUGIN[] 	= "Remember the Score";
new const VERSION[] = "1.0.810";
new const AUTHOR[]	= "Nextra";

#define IsValidPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )

new g_szQuery[512];

new Handle:g_SqlTuple, Handle:g_SqlConn;

new g_Table[64], g_Auth, g_msgid_ScoreInfo, g_iMaxPlayers, g_iAuthFwd, g_iActiveFwd, g_iDeActiveFwd, g_iFwdReturn;

new p_Host, p_User, p_Pass, p_Db, p_Table, p_Type, p_Auth, p_Max, p_Min, p_Prune, p_Permap, p_Track, p_Save;

enum STORAGE
{
	SCORE,
	DEATHS,
	USERID,
	CONNECT,
	BOT,
	SETUP
};

new g_Storage[33][STORAGE];

enum
{
	TRACK_SCORE,
	TRACK_DEATHS
};

enum DBTYPES
{
	MYSQL,
	SQLITE
};

new DBTYPES:g_DBType;

new szTimeStamp[DBTYPES][] =
{
	"UNIX_TIMESTAMP( )",
	"strftime( '%s', 'now', 'localtime' )"
};

enum
{
	SETUP_PLAYER,
	SAVE_PLAYER,
	INSERT_PLAYER
};

const TASK_SETUP = 1230;

public plugin_natives( )
{
	register_library( "rememberthescore" );
	
	register_native( "rts_save_score"	, "_native_save_player" 	);
	register_native( "rts_update_score"	, "_native_update_player" 	);
	register_native( "rts_is_authorized", "_native_is_authorized"	);
}


public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_cvar( "rts_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY );
	
	g_msgid_ScoreInfo = get_user_msgid( "ScoreInfo" );
	
	p_Host 		= register_cvar( "rts_host"		, ""		, FCVAR_PROTECTED 	),
	p_User 		= register_cvar( "rts_user"		, ""		, FCVAR_PROTECTED 	),
	p_Pass 		= register_cvar( "rts_pass"		, ""		, FCVAR_PROTECTED 	),
	p_Db		= register_cvar( "rts_db"		, ""		, FCVAR_PROTECTED 	),
	p_Table		= register_cvar( "rts_table"	, ""		, FCVAR_PROTECTED	),
	p_Type		= register_cvar( "rts_type"		, "mysql"	, FCVAR_PROTECTED	),
	p_Auth		= register_cvar( "rts_auth"		, "0"		),
	p_Max		= register_cvar( "rts_max"		, "1000"	),
	p_Min		= register_cvar( "rts_min"		, "0"		),
	p_Prune		= register_cvar( "rts_prune"	, "0"		),
	p_Permap	= register_cvar( "rts_permap"	, "0"		),
	p_Track		= register_cvar( "rts_track"	, "3"		),
	p_Save		= register_cvar( "rts_save"		, "0"		);
	
	RegisterHam( Ham_Spawn, "player", "on_Spawn", 1 );  
	
	register_logevent( "on_RoundEnd", 2, "1=Round_End" );
	register_message( g_msgid_ScoreInfo, "msg_ScoreInfo" );
	
	g_iAuthFwd 		= CreateMultiForward( "rts_user_authorized"	, ET_IGNORE, FP_CELL );
	g_iDeActiveFwd 	= CreateMultiForward( "rts_plugin_inactive"	, ET_IGNORE, FP_CELL );
	g_iActiveFwd 	= CreateMultiForward( "rts_plugin_active"	, ET_IGNORE );
	
	if( !g_iAuthFwd )
		log_amx( "[RTS] Authorized forward could not be created. Other plugins may malfunction." );
	if( !g_iDeActiveFwd )
		log_amx( "[RTS] Deactivation forward could not be created. Other plugins may malfunction." );
	if( !g_iActiveFwd )
		log_amx( "[RTS] Activation forward could not be created. Other plugins may malfunction." );
	
	g_iMaxPlayers = get_maxplayers( );
}

public plugin_cfg( )
{
	new szFile[128];
	get_configsdir( szFile, charsmax(szFile) );
	add( szFile, charsmax(szFile), "/sql.cfg" );
	
	server_cmd( "exec %s", szFile );
	server_exec( );
	
	new szAffinity[8], szNewAffinity[8];
	
	get_pcvar_string( p_Type, szNewAffinity, charsmax(szNewAffinity) );
	SQL_GetAffinity( szAffinity, charsmax(szAffinity) );
	
	if( !equali( szAffinity, szNewAffinity ) )
	{
		if( !SQL_SetAffinity( szNewAffinity ) )
			log_amx( "Failed to set database type from %s to %s.", szAffinity, szNewAffinity );
		else
			szAffinity = szNewAffinity;
	}
	
	if( equali( szAffinity, "mysql" ) )
		g_DBType = MYSQL;
	else if( equali( szAffinity, "sqlite" ) )
		g_DBType = SQLITE;
	else
		set_fail_and_fwd( "[RTS] Unsupported database type" );
	
	
	new szHost[32], szUser[32], szPass[32], szDb[32];
	
	get_pcvar_string( p_Host, szHost, charsmax(szHost)	);
	get_pcvar_string( p_User, szUser, charsmax(szUser)	);
	get_pcvar_string( p_Pass, szPass, charsmax(szPass)	);
	get_pcvar_string( p_Db	, szDb	, charsmax(szDb)	);
	
	get_pcvar_string( p_Table, g_Table, charsmax(g_Table) );
	
	g_Auth = get_pcvar_num( p_Auth );
	
	g_SqlTuple = SQL_MakeDbTuple( szHost, szUser, szPass, szDb );
	
	if( g_SqlTuple == Empty_Handle )
	{
		set_fail_and_fwd( "[RTS] Database handle could not be created." );
		return;
	}
	
	new iError;
	
	g_SqlConn = SQL_Connect( g_SqlTuple, iError, g_szQuery, charsmax(g_szQuery) );
	
	if( g_SqlConn == Empty_Handle )
	{
		set_fail_and_fwd( "[RTS] Database connection could not be established." );
		return;
	}
	
	if( g_DBType == MYSQL )
	{
		formatex( g_szQuery, charsmax(g_szQuery),
			"CREATE TABLE IF NOT EXISTS `%s` ( \
				`id` INT NOT NULL AUTO_INCREMENT, \
				`player_id` VARCHAR( 32 ) DEFAULT NULL, \
				`score` INT( 11 ) NOT NULL DEFAULT '0', \
				`deaths` INT( 11 ) NOT NULL DEFAULT '0', \
				`time` INT( 11 ) NOT NULL DEFAULT '0', \
				PRIMARY KEY ( `id` ), \
				UNIQUE ( `player_id` ) \
			)",
		g_Table );
	}
	else
	{
		formatex( g_szQuery, charsmax(g_szQuery),
			"CREATE TABLE IF NOT EXISTS `%s` ( \
				`id` INTEGER PRIMARY KEY AUTOINCREMENT, \
				`player_id` TEXT UNIQUE DEFAULT NULL, \
				`score` INTEGER NOT NULL DEFAULT '0', \
				`deaths` INTEGER NOT NULL DEFAULT '0', \
				`time` INTEGER NOT NULL DEFAULT '0' \
			)",
		g_Table );
	}
	
	SimpleQueryAndErr( g_SqlConn, g_szQuery );
	
	if( g_DBType == SQLITE )
	{
		new Handle:SqlIntegrityQuery = SQL_PrepareQuery( g_SqlConn, "PRAGMA integrity_check" );
		
		if( !SQL_Execute( SqlIntegrityQuery ) )
		{
			set_fail_and_fwd( "[RTS] Integrity check could not be performed. Ceasing any further operation." );
			return;
		}
		
		new szIntegrity[64];
		if( SQL_NumResults( SqlIntegrityQuery ) )
		{
			SQL_ReadResult( SqlIntegrityQuery, 0, szIntegrity, charsmax(szIntegrity) );
		}

		SQL_FreeHandle( SqlIntegrityQuery );

		if( !equali( szIntegrity, "OK" ) )
		{
			log_amx( "[RTS] Integrity Check returned: %s", szIntegrity );
			set_fail_and_fwd( "[RTS] Integrity check failed. Ceasing any further operation." );
			return;
		}
		
		if( !SimpleQueryAndErr( g_SqlConn, "PRAGMA synchronous = 1" ) )
		{
			set_fail_and_fwd( "[RTS] SQLite synchronous setting failed. Ceasing any further operation." );
			return;
		}
	}
	
	if( get_pcvar_num( p_Permap ) )
		clean_db( );
	else if( get_pcvar_num( p_Prune ) > 0 )
		prune_db( );
	else
		SQL_FreeHandle( g_SqlConn );
}


public plugin_pause( )
{
	for( new id = 1; id <= g_iMaxPlayers; id++ )
		g_Storage[id][USERID] = 0;
		
	if( !ExecuteForward( g_iDeActiveFwd, g_iFwdReturn, 0 ) )
		log_amx( "[RTS] Error executing inactive forward." );
}


public plugin_unpause( )
{
	for( new id = 1; id <= g_iMaxPlayers; id++ )
	{
		if( g_Storage[id][CONNECT] )
			setup_player( id );
	}
	
	if( !ExecuteForward( g_iActiveFwd, g_iFwdReturn ) )
		log_amx( "[RTS] Error executing activation forward." );
}


clean_db( )
{
	if( g_DBType == MYSQL )
	{
		formatex( g_szQuery, charsmax(g_szQuery),
			"TRUNCATE TABLE `%s`;",
		g_Table );
	}
	else
	{
		formatex( g_szQuery, charsmax(g_szQuery),
			"DELETE FROM `%s`;",
		g_Table );
	}
	
	SimpleQueryAndErr( g_SqlConn, g_szQuery );
	
	SQL_FreeHandle( g_SqlConn );
}


prune_db( )
{
	formatex( g_szQuery, charsmax(g_szQuery),
		"DELETE \
		FROM `%s` \
		WHERE %s - `time` > %d;",
	g_Table, szTimeStamp[g_DBType], ( get_pcvar_num( p_Prune ) * 86400 ) );
	
	SimpleQueryAndErr( g_SqlConn, g_szQuery );
	
	SQL_FreeHandle( g_SqlConn );
}


public client_connect( id )
{
	g_Storage[id][SCORE] 	= 0,
	g_Storage[id][DEATHS] 	= 0,
	g_Storage[id][SETUP] 	= 0,
	g_Storage[id][USERID] 	= 0;
}


public client_putinserver( id )
{
	g_Storage[id][CONNECT] 	= 1,
	g_Storage[id][BOT]		= is_user_bot( id );
}


public client_disconnected( id )
{
	save_player( id, 1 );
	g_Storage[id][CONNECT] = 0;
}


public on_RoundEnd( )
{
	if( get_pcvar_num( p_Track ) && get_pcvar_num( p_Save ) == 1 )
		save_all( 0 );
}


public msg_ScoreInfo( )
{
	new id = get_msg_arg_int( 1 );
	
	if( !g_Storage[id][CONNECT] )
		return PLUGIN_CONTINUE;
	
	new iScore 	= get_msg_arg_int( 2 ),
		iDeaths = get_msg_arg_int( 3 );
	
	if( !iScore && !iDeaths )
	{
		if( !g_Storage[id][USERID] )
			setup_player( id );
		else
			set_score( id );
	}
	else
	{
		g_Storage[id][SCORE] 	= iScore,
		g_Storage[id][DEATHS] 	= iDeaths;
		
		if( get_pcvar_num( p_Save ) == 3 )
			save_player( id, 0 );
	}
	
	return PLUGIN_CONTINUE;
}


public on_Spawn( const id )
{
	if( get_pcvar_num( p_Save ) == 2 )
		save_player( id, 0 );
}


public setup_player( id )
{
	if( id >= TASK_SETUP )
		id -= TASK_SETUP;
	
	if( g_Storage[id][SETUP] )
		return;
	else if( g_Storage[id][BOT] )
		return;
		
	g_Storage[id][SETUP] = 1;
	
	new szAuth[32];
	get_auth( id, szAuth, charsmax(szAuth) );
		
	
	new data[2];
	data[0] = SETUP_PLAYER,
	data[1] = id;
	
	formatex( g_szQuery, charsmax(g_szQuery), 
		"SELECT `score`, `deaths`, `id` \
		FROM `%s` \
		WHERE `player_id` = '%s';",
	g_Table, szAuth );
	
	SQL_ThreadQuery( g_SqlTuple, "Handle_SQL", g_szQuery, data, sizeof data );
}


get_score( Handle:Query, const id )
{
	if( !g_Storage[id][CONNECT] )
		return;
	
	if( SQL_MoreResults( Query ) )
	{
		new iTrack = get_pcvar_num( p_Track );
		
		if( iTrack & (1<<TRACK_SCORE) )
			g_Storage[id][SCORE] = SQL_ReadResult( Query, 0 );
		
		if( iTrack & (1<<TRACK_DEATHS) )
			g_Storage[id][DEATHS] = SQL_ReadResult( Query, 1 );
		
		g_Storage[id][USERID] = SQL_ReadResult( Query, 2 );
		
		set_score( id );
		
		if( !ExecuteForward( g_iAuthFwd, g_iFwdReturn, id ) )
			log_amx( "[RTS] Error executing auth forward." );
			
		g_Storage[id][SETUP] = 0;
	}
	else
	{
		new szAuth[32];
		get_auth( id, szAuth, charsmax(szAuth) );
		
		new data[2];
		data[0] = INSERT_PLAYER,
		data[1] = id;
		
		formatex( g_szQuery, charsmax(g_szQuery),
			"INSERT INTO `%s` \
			( `player_id`, `time` ) \
			VALUES ( '%s', %s );",
		g_Table, szAuth, szTimeStamp[g_DBType] );
		
		SQL_ThreadQuery( g_SqlTuple, "Handle_SQL", g_szQuery, data, sizeof data );
	}
}


get_userid( Handle:Query, const id )
{
	if( !g_Storage[id][CONNECT] )
		return;
	
	g_Storage[id][SETUP] = 0;
	
	new uid = SQL_GetInsertId( Query );
	
	if( !uid )
		set_task( 1.0, "setup_player", TASK_SETUP + id );
	else
	{
		g_Storage[id][USERID] = uid;
		
		if( !ExecuteForward( g_iAuthFwd, g_iFwdReturn, id ) )
			log_amx( "[RTS] Error executing auth forward." );
	}
}


save_all( const iTimestamp )
{
	for( new id = 1; id <= g_iMaxPlayers; id++ )
	{
		if( g_Storage[id][CONNECT] )
			save_player( id, iTimestamp );
	}
}


save_player( const id, const iTimestamp )
{
	if( g_Storage[id][CONNECT] )
	{
		if( g_Storage[id][BOT] || !g_Storage[id][USERID] )
			return;
	}
	
	new iTrack = get_pcvar_num( p_Track );
	
	if( !iTrack )
	{
		g_Storage[id][USERID] = 0;
		return;
	}
	
	new iScore = g_Storage[id][SCORE], iDeaths = g_Storage[id][DEATHS];
	
	if( !get_pcvar_num( p_Permap ) )
	{
		new iMax = get_pcvar_num( p_Max ), iMin = get_pcvar_num( p_Min );
		
		if( iTrack == (1<<TRACK_DEATHS) && iDeaths < iMin )
			iDeaths = 0;
		else if( iScore < iMin )
			iScore = iDeaths = 0;
		else
		{
			iScore 	= min( iScore, iMax ),
			iDeaths = min( iDeaths, iMax );
		}
	}
	
	static const szTime[DBTYPES][] = 
	{
		", `time` = UNIX_TIMESTAMP( )",
		", `time` = strftime( '%s', 'now', 'localtime' )"
	};
	
	new data[2];
	data[0] = SAVE_PLAYER,
	data[1] = id;
	
	formatex( g_szQuery, charsmax(g_szQuery),
		"UPDATE `%s` \
		SET `score` = '%i', `deaths` = '%i'%s \
		WHERE `id` = '%i';",
	g_Table, ( iTrack & (1<<TRACK_SCORE) ? iScore : 0 ), ( iTrack & (1<<TRACK_DEATHS) ? iDeaths : 0 ), 
		iTimestamp ? szTime[g_DBType] : "", g_Storage[id][USERID] );

	SQL_ThreadQuery( g_SqlTuple, "Handle_SQL", g_szQuery, data, sizeof data );
}


public _native_save_player( iPlugin, iParams )
{
	if( iParams != 1 )
	{
		log_error( AMX_ERR_PARAMS, "[RTS] Allowed parameter count is 1." );
		return 0;
	}

	new id = get_param( 1 );

	if( !IsValidPlayer( id ) )
		return 0;
	else if( !g_Storage[id][CONNECT] || g_Storage[id][BOT] )
		return 0;
		
	save_player( id, 0 );
	
	return 1;
}


public _native_update_player( iPlugin, iParams )
{
	if( iParams != 1 )
	{
		log_error( AMX_ERR_PARAMS, "[RTS] Allowed parameter count is 1." );
		return 0;
	}

	new id = get_param( 1 );

	if( !IsValidPlayer( id ) )
		return 0;
	else if( !g_Storage[id][CONNECT] || g_Storage[id][BOT] )
		return 0;
	
	new iScore = get_user_frags( id ), iDeaths = cs_get_user_deaths( id );
	
	if( iScore != g_Storage[id][SCORE] )
		g_Storage[id][SCORE] = iScore;
	
	if( iDeaths != g_Storage[id][DEATHS] )
		g_Storage[id][DEATHS] = iDeaths;
		
	return 1;
}


public _native_is_authorized( iPlugin, iParams )
{
	if( iParams != 1 )
	{
		log_error( AMX_ERR_PARAMS, "[RTS] Allowed parameter count is 1." );
		return 0;
	}
	
	new id = get_param( 1 );
	
	if( !IsValidPlayer( id ) )
		return 0;
	else if( !g_Storage[id][CONNECT] || g_Storage[id][BOT] )
		return 0;
	
	return ( g_Storage[id][USERID] ? 1 : 0 );
}


set_score( const id )
{
	set_pev( id, pev_frags, float( g_Storage[id][SCORE] ) );
	cs_set_user_deaths( id, g_Storage[id][DEATHS] );
	
	message_begin( MSG_ALL, g_msgid_ScoreInfo );
	write_byte( id );
	write_short( g_Storage[id][SCORE] );
	write_short( g_Storage[id][DEATHS] );
	write_short( 0 );
	write_short( get_user_team( id ) );
	message_end( );
}


public plugin_end( )
{
	DestroyForward( g_iDeActiveFwd 	);
	DestroyForward( g_iActiveFwd 	);
	DestroyForward( g_iAuthFwd 		);
	SQL_FreeHandle( g_SqlTuple 		);
}


public Handle_SQL( iFailState, Handle:Query, szError[], iErrorcode, Data[], iSize, Float:fQueueTime )
{
	if( iFailState )
	{
		SQL_GetQueryString( Query, g_szQuery, charsmax(g_szQuery) );
		
		log_amx( "[RTS] Error: (%d) %s", iErrorcode, szError );
		log_amx( "[RTS] Query: %s", g_szQuery );
		
		pause( "a" );
		return;
	}
	
	// log_amx( "[RTS] fQueueTime: %f. Func: %i.", QueueTime, Data[0] );
	
	switch( Data[0] )
	{
		case SETUP_PLAYER	: get_score	( Query, Data[1] );
		case INSERT_PLAYER	: get_userid( Query, Data[1] );
	}
}


get_auth( const id, szAuth[], iLen )
{
	switch( g_Auth )
	{
		case 0: get_user_authid( id, szAuth, iLen );
		case 1: get_user_ip( id, szAuth, iLen, 1 );
		case 2: 
		{	
			get_user_name( id, szAuth, iLen );
	
			if( g_DBType == MYSQL )
				replace_all( szAuth, iLen, "'"	, "\\'" );
			else
				replace_all( szAuth, iLen, "'"	, "''"	);
		}
	}
}


SimpleQueryAndErr( Handle:SqlCon, const szQuery[] )
{
	new szError[256];
	if( !SQL_SimpleQuery( SqlCon, szQuery, szError, charsmax(szError) ) )
	{
		log_amx( "[RTS] Error: %s", szError );
		log_amx( "[RTS] Query: %s", szQuery );
	
		return 0;
	}
	
	return 1;
}


set_fail_and_fwd( const szError[] )
{
	if( !ExecuteForward( g_iDeActiveFwd, g_iFwdReturn, 1 ) )
		log_amx( "[RTS] Error executing deactivation forward." );

	set_fail_state( szError );
}
