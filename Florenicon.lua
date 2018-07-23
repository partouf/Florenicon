-- Author      : Partouf
-- Create Date : 11/10/2010

Florenicon_MyName = false;
Florenicon_Players = {};
Florenicon_Labels = {};
Florenicon_Heals = {};

Florenicon_Log = true;
Florenicon_CurrentCombat_Start = 0;
Florenicon_CurrentCombat_StatsPP = {};
Florenicon_CurrentlyInCombat = false;

Florenicon_SpellStart = 0;
Florenicon_SpellTimeSum = 0;


function Florenicon_SpellUp()
	if Florenicon_SpellStart == 0 then
		Florenicon_SpellTimeSum = 0;
		Florenicon_SpellStart = GetTime();
	end
end

function Florenicon_SpellDown()
	if Florenicon_SpellStart > 0 then
		Florenicon_SpellTimeSum = Florenicon_SpellTimeSum + (GetTime() - Florenicon_SpellStart);
		Florenicon_SpellStart = 0;
	end
end

function Florenicon_Stats_Find( playername )
	for index, value in ipairs(Florenicon_CurrentCombat_StatsPP) do
		if value[1] == playername then
			return index;
		end
	end

	return 0;
end

function Florenicon_Stats_Add( playername )
	tinsert(Florenicon_CurrentCombat_StatsPP, {playername, 0, 0, 0, 0});
end

function Florenicon_Stats_AddTick( playername, healamount, overhealamount, critted )
	Florenicon_SpellUp();

	local idxPlayer = Florenicon_Stats_Find(playername);
	if idxPlayer == 0 then
		Florenicon_Stats_Add(playername);
		idxPlayer = #(Florenicon_CurrentCombat_StatsPP);
	end

	Florenicon_CurrentCombat_StatsPP[idxPlayer][2] = Florenicon_CurrentCombat_StatsPP[idxPlayer][2] + 1;
	Florenicon_CurrentCombat_StatsPP[idxPlayer][3] = Florenicon_CurrentCombat_StatsPP[idxPlayer][3] + (healamount - overhealamount);
	Florenicon_CurrentCombat_StatsPP[idxPlayer][4] = Florenicon_CurrentCombat_StatsPP[idxPlayer][4] + healamount;
	if critted then
		Florenicon_CurrentCombat_StatsPP[idxPlayer][5] = Florenicon_CurrentCombat_StatsPP[idxPlayer][5] + 1;
	end
end

function Florenicon_EnterCombat()
	Florenicon_CurrentlyInCombat = true;

	wipe(Florenicon_CurrentCombat_StatsPP);

	Florenicon_CurrentCombat_Start = GetTime();
	
	if (Florenicon_SpellStart > 0) then
		Florenicon_SpellStart = 0;
		Florenicon_SpellTimeSum = 0;
		Florenicon_SpellUp();
	end
end

function Florenicon_LeaveCombat()
	Florenicon_CurrentlyInCombat = false;

	if Florenicon_Log then
		local totalspelltime = Florenicon_SpellTimeSum;
		
		if Florenicon_SpellStart > 0 then
			Florenicon_SpellDown();
			totalspelltime = Florenicon_SpellTimeSum;
			Florenicon_SpellUp();
		end

		local playercount = #(Florenicon_CurrentCombat_StatsPP);
		if playercount == 0 then
			return;
		end
		
		local totalhealamount = 0;
		local totalticks = 0;
		local maximumticks = 0;
		local maximumhealamount = 0;
		local totalspellhealamount = 0;
		local totalcritticks = 0;
		local totalcombattime = GetTime() - Florenicon_CurrentCombat_Start;

		for index, value in ipairs(Florenicon_CurrentCombat_StatsPP) do
			totalticks = totalticks + value[2];
			totalhealamount = totalhealamount + value[3];
			maximumticks = max(maximumticks, value[2]);
			maximumhealamount = max(maximumhealamount, value[3]);
			totalspellhealamount = totalspellhealamount + value[4];
			totalcritticks = totalcritticks + value[5];
		end

		local totalaveragehealamount = floor(totalhealamount / totalticks);
		local averageticksperplayer = floor(totalticks / playercount);
		local totalaveragespellheal = floor(totalspellhealamount / totalticks);
		local crithealperc = floor(totalcritticks / totalticks * 100);
		
		local uptime = floor(((totalspelltime / totalcombattime) * 10000)) / 100;
		
		local efficiency = floor(totalhealamount / (totalaveragespellheal * playercount * averageticksperplayer * (1 + (crithealperc / 100.0))) * 10000) / 100;

		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("Florenicon stats (" .. Florenicon_MyName .. ")", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Uptime: " .. uptime .. "%", 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Efficiency: " .. efficiency .. "%", 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Effective amount healed: " .. totalhealamount .. " hp", 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Amount of players healed: " .. playercount, 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Average ticks per player: " .. averageticksperplayer, 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage("Efflorescence spell stats (" .. Florenicon_MyName .. ")", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Potential healing power: " .. totalaveragespellheal .. " hp", 1.0, 1.0, 1.0);
			DEFAULT_CHAT_FRAME:AddMessage(" - Crit chance: " .. crithealperc .. "%", 1.0, 1.0, 1.0);
		end
	end
end

function Florenicon_SetCombat( incombat )
	if incombat then
		if not Florenicon_CurrentlyInCombat then
			Florenicon_EnterCombat();
		end;
	else
		if Florenicon_CurrentlyInCombat then
			Florenicon_LeaveCombat();
		end
	end
end

-- simple timer

Florenicon_Timers = {};
function Florenicon_Schedule( f, arg1 )
	local spellTimeSeconds = 4;

	local now = GetTime();
	local task = { now + spellTimeSeconds, f, arg1 };
	tinsert( Florenicon_Timers, task );
end

function Florenicon_Unschedule( arg1 )
	local c = #(Florenicon_Timers);
	local i = 1;
	while i <= c do
		local task = Florenicon_Timers[i];
		if arg1 == task[3] then
			tremove( Florenicon_Timers, i );
			c = c - 1;
		else
			i = i + 1;
		end
	end
end

function Florenicon_CheckTasks()
	Florenicon_SetCombat(UnitAffectingCombat( "player" ));

	local c = #(Florenicon_Timers);
	local i = 1;
	local currentTime = GetTime();
	while i <= c do
		local task = Florenicon_Timers[i];
		if currentTime > task[1] then
			tremove( Florenicon_Timers, i );
			c = c - 1;

			local f = task[2];
			local arg1 = task[3];
			f( arg1 );
		else
			i = i + 1;
		end
	end
end

function Florenicon_ClearList()
	Florenicon_SpellDown();
	
	wipe(Florenicon_Players);
	wipe(Florenicon_Heals);
end

function Florenicon_isListed( name )
	local c = #(Florenicon_Players);
	for i = 1, c do
		if Florenicon_Players[i] == name then
			return i;
		end
	end
	return 0;
end

function Florenicon_addToList( name, amount )
	local idxPlayer = Florenicon_isListed(name);
	if idxPlayer == 0 then
		tinsert( Florenicon_Players, name );
		tinsert( Florenicon_Heals, amount );
	else
		Florenicon_Heals[idxPlayer] = amount;
	end
end

function Florenicon_delFromList( name )
	local c = #(Florenicon_Players);
	for i = 1, c do
		if Florenicon_Players[i] == name then
			tremove( Florenicon_Players, i );
			tremove( Florenicon_Heals, i );
			break;
		end
	end
	
	if (#(Florenicon_Players) == 0) then
		Florenicon_SpellDown();
	end
end

function Florenicon_showListOnFrame( obj )
	local label = nil;
	local c = #(Florenicon_Labels);
	local d = #(Florenicon_Players);

	local h = d * 12 + 30;
	if h < 50 then
		obj:SetHeight( 50 );
	else
		obj:SetHeight( h );
	end

	local y = -5;
	for i = 1, d do
		y = y - 12;
		if i > c then
			label = CreateFrame("SimpleHtml");
			label:SetParent(obj);
			label:SetFont('Fonts\\FRIZQT__.TTF', 11);
			label:SetJustifyH("LEFT");
			label:SetWidth(220);
			label:SetHeight(22);
			label:SetPoint("TOPLEFT", 20, y);
			if Florenicon_Heals[i] > 0 then
				label:SetText( "|c0000ff00"..i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			else
				label:SetText( i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			end
			label:Show();
			
			tinsert( Florenicon_Labels, label );
		else
			label = Florenicon_Labels[i];
			label:SetPoint("TOPLEFT", 20, y);
			if Florenicon_Heals[i] > 0 then
				label:SetText( "|c0000ff00"..i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			else
				label:SetText( i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			end
			label:Show();
		end
	end

	d = d + 1;
	for j = d, c do
		label = Florenicon_Labels[j];
		label:Hide();
	end
end

function Florenicon_OnLoad( obj )
	locClass, enClass = UnitClass( "PLAYER" );

	Florenicon_MyName = UnitName( "PLAYER" );

	obj:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function Florenicon_OnEvent( obj, event, ... )
	Florenicon_CheckTasks();

	local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overheal, absorb, crit = CombatLogGetCurrentEventInfo();

	if combatEvent == "SPELL_HEAL" then
		if spellId == 81269 then
			Florenicon_Unschedule( destName );

			Florenicon_addToList( destName, amount - overheal );

			if Florenicon_Log and (sourceName == Florenicon_MyName) then
				Florenicon_Stats_AddTick( destName, amount, overheal, crit );
			end

			Florenicon_Schedule( Florenicon_delFromList, destName );
		end
	elseif Florenicon_Log and (combatEvent == "SPELL_CAST_SUCCESS") and (spellId == 81269) and (sourceName == Florenicon_MyName) then
		Florenicon_SpellUp();
	end

	Florenicon_showListOnFrame(obj);
end
