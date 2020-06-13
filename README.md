# nCX_Lua
LUA Part for nCX Server mod

* Rewritten all Lua entity scripts for optimal performance
* One file per gamerule
* OnUpdate functions replaced with OnTimer (each sec) or moved to C++
* Entity scripts and xmls support modding without affecting sv_cheatprotection
* Includes LUA mod extension (CryMP) for nCX_Server.dll
* New entity ServerTrigger (super fast) replaces previous ProximityTrigger
* Removed pregame

Fixes:
* Fixed Vehicle buyzone missing for client connected after vehicle was spawned
* Fixed missing weapon in hand after leaving spawn truck
* Fixed grenade switch freezing bug which blocked weapon reload and shooting
* Fixed rmi script crash vulnerabilities
* Fixed warfactory doors opening wrong direction
* Fixed prototype leaving buyzone area

CryMP (LUA extension)
* Supports numerous events
* Plugin System
* Automatic Plugin finder (add Pluginname to config to load it)

