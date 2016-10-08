﻿-- Author      : Kwast
-- Create Date : 11/10/2010 7:39:21 PM

Florenicon_Players = {};
Florenicon_Labels = {};
Florenicon_Heals = {};

iMode = 0;
iSpellTime = 0;

-- simple timer

Florenicon_Timers = {};
function Florenicon_Schedule( t, f, arg1 )
	local now = GetTime();
	local task = { now + t, f, arg1 };
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
	local c = #(Florenicon_Timers);
	local i = 1;
	while i <= c do
		local task = Florenicon_Timers[i];
		if GetTime() > task[1] then
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
	local c = #(Florenicon_Players);
	for i = 1, c do
		tremove( Florenicon_Players );
		tremove( Florenicon_Heals );
	end
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

function Florenicon_addToList( name )
	if Florenicon_isListed(name) == 0 then
		tinsert( Florenicon_Players, name );
		tinsert( Florenicon_Heals, 0 );
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
end

function Florenicon_setHealAmount( name, amount )
	local i = Florenicon_isListed(name);
	Florenicon_Heals[i] = amount;
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
	
	iMode = 0;
	iSpellTime = 4;

	obj:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end


function Florenicon_OnEvent( obj, event, ... )
	Florenicon_CheckTasks();
	
	local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overheal, absorb, crit = ...;

	if combatEvent == "SPELL_HEAL" then
		if spellId == 81269 then
			Florenicon_Unschedule( destName );

			Florenicon_addToList( destName );
			Florenicon_setHealAmount( destName, amount - overheal );

			Florenicon_Schedule( iSpellTime, Florenicon_delFromList, destName );
		end
	end
	
	Florenicon_showListOnFrame(obj);
end


