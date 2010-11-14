-- Author      : Kwast
-- Create Date : 11/10/2010 7:39:21 PM

Florenicon_Players = {};
Florenicon_Labels = {};
Florenicon_Heals = {};


-- simple timer

Florenicon_Timers = {};
function Florenicon_Schedule( t, f, arg1 )
	local now = GetTime();
	local task = { now + t, f, arg1 };
	table.insert( Florenicon_Timers, task );
end

function Florenicon_CheckTasks()
	local c = #(Florenicon_Timers);
	local i = 1;
	while i <= c do
		local task = Florenicon_Timers[i];
		if GetTime() > task[1] then
			table.remove( Florenicon_Timers, i );
			c = c - 1;
			i = i - 1;

			local f = task[2];
			local arg1 = task[3];
			f( arg1 );
		end
		i = i + 1;
	end
end

--

function Florenicon_ClearList()
	local c = #(Florenicon_Players);
	for i = 1, c do
		table.remove( Florenicon_Players );
		table.remove( Florenicon_Heals );
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
		table.insert( Florenicon_Players, name );
		table.insert( Florenicon_Heals, 0 );
	end
end

function Florenicon_delFromList( name )
	local c = #(Florenicon_Players);
	for i = 1, c do
		if Florenicon_Players[i] == name then
			table.remove( Florenicon_Players, i );
			table.remove( Florenicon_Heals, i );
			break;
		end
	end
end

function Florenicon_setHealAmount( name, amount )
	local i = Florenicon_isListed(name);
	if i > 0 then
		Florenicon_Heals[i] = amount;
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
	
	for i = 1, d do
		if i > c then
			label = CreateFrame("SimpleHtml");
			label:SetParent(obj);
			label:SetFont('Fonts\\FRIZQT__.TTF', 11);
			label:SetWidth(220);
			label:SetHeight(22);
			label:SetPoint("TOPLEFT", 20, -5 + i * -12);
			if Florenicon_Heals[i] > 0 then
				label:SetText( "|c0000ff00"..i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			else
				label:SetText( i..". "..Florenicon_Players[i].." ("..Florenicon_Heals[i]..")");
			end
			label:Show();
			
			table.insert( Florenicon_Labels, label );
		else
			label = Florenicon_Labels[i];
			label:SetPoint("TOPLEFT", 20, -5 + i * -12);
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
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage( "Florenicon loaded", 1.0, 0.0, 0.0);
	end

	obj:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end


-- note: the aura is written as Efflorescence
--        the healing entity as Effloresence
function Florenicon_OnEvent( obj, event, ... )
	Florenicon_CheckTasks();
	
	local timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, _, amount, overheal = ...;

	if combatEvent == "SPELL_AURA_APPLIED" then
		if spellId == 81262 then
			Florenicon_addToList( destName );
			
			Florenicon_Schedule( 15, Florenicon_delFromList, destName );
		end
	elseif combatEvent == "SPELL_AURA_REMOVED" then
		if spellId == 81262 then
			Florenicon_delFromList( destName );
		end
	elseif combatEvent == "SPELL_HEAL" then
		if sourceName == "Effloresence" then
			Florenicon_setHealAmount( destName, amount - overheal );
		end
	end

	Florenicon_showListOnFrame(obj);
end


