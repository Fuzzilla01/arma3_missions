diag_log format["createPickupLZ called, _this: %1", _this];
private _lzLocation = _this select 0;
private _assignExtra = _this select 1;

private _squad = [_lzLocation] call createSquad;

private _enemies = [];
private _lzhot = false;
//Make the LZ hot if the roll demands it
if ((random 1) < hotLZChance) then
{
    _lzhot = true
};
private _lzAA = false;
if ((random 1) < AAChance) then
{
    _lzhot = true;
    _lzAA = true;
};
if (_lzhot)
{
    _enemies = _enemies + ([_lzLocation, _lzAA] call createEnemySquads);
};

lzCounter = lzCounter + 1;
publicVariable "lzCounter";

private _shortestDesc = format["LZ %1", lzCounter];
private _longdesc = format["%1 wants a pickup from this location", _squad];
private _shortdesc = format["Pick up %1", _squad];
if (_lzAA and _lzhot) then
{
    _longdesc = _longdesc + "<br/><strong>Be advised:</strong> Intel reports heavy enemy activity with AA assets at the location";
};
if (!_lzAA and _lzhot) then
{
    _longdesc = _longdesc + "<br/><strong>Be advised:</strong> Intel reports enemy activity at the location";
};

private _assignTo = [west];
if (!(_assignExtra isEqualTo false)) then
{
    _assignTo = _assignTo + _assignExtra;
};

// PONDER: make a parent task "ferry squad X" ??
private _taskid = format["pickup_%1", lzCounter];
[_assignTo,[_taskid],[_longdesc, _shortdesc, _shortestDesc],_lzLocation,"AUTOASSIGNED",1,true, "meet", true] call BIS_fnc_taskCreate;

private _handlePickup=false;
private _trg = createTrigger["EmptyDetector",getPos _lzLoc, true];
_trg setTriggerArea[lzSize,lzSize,0,false];
_trg setTriggerActivation["WEST","PRESENT",false];
_trg setTriggerTimeout [2.5, 2.5, 2.5, true];
_trg setTriggerStatements["([thisList] call playerVehicleInListBool)", "_handlePickup = true;", ""];


// TODO: implement deadline so the task doesn't linger forever
scopeName "main";
while {true} do
{
    scopeName "mainloop";

    if ({alive _x} count units _squad == 0) then
    {
        // Everybody died before we got there :(
        [_taskid, "FAILED" ,true] spawn BIS_fnc_taskSetState;
        breakOut "mainloop";
    }

    if (_handlePickup) then
    {
        private _newLZLocation = (lzList - [_lzLocation]) call BIS_fnc_SelectRandom;
        private _veh = [list _trg] call playerVehicleInList;
        private _handle = [_veh, _squad, _taskid] execVM "loadSquad.sqf";
        waitUntil {isNull _handle};

        private _handle = [_newLZLocation, _veh, _squad, _taskid] execVM "createDropoffLZ.sqf";
        waitUntil {isNull _handle};
        breakOut "mainloop";
    };
	sleep 1;
};

deleteVehicle _trg;
// Make sure there are no lingering enemy or own units
[_enemies + [_squad]] call deleteSquads;
