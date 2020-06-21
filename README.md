# nCX_Lua
LUA Part for nCX Server mod

* Rewritten all Lua entity scripts for optimal performance
* One file for each GameRule
* OnUpdate functions replaced with OnTimer (each sec) or moved to C++
* Entity scripts and xmls modding support without affecting sv_cheatprotection
* Includes LUA mod extension (CryMP) for nCX_Server.dll
* New entity ServerTrigger (super fast) replaces previous ProximityTrigger
* Request revive reacts without delay
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

