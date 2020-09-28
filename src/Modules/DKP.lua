local _, core = ...;
local _G = _G;
local L = core.L;

local DKP = core.DKP;
local GUI = core.GUI;
local Item = core.Item;
local PDKP = core.PDKP;
local Raid = core.Raid;
local Util = core.Util;
local Comms = core.Comms;
local Setup = core.Setup;
local Guild = core.Guild; -- Uppercase is the file
local guild = core.guild; -- Lowercase is the object
local Shroud = core.Shroud;
local Member = core.Member;
local Import = core.Import;
local Officer = core.Officer;
local Invites = core.Invites;
local Minimap = core.Minimap;
local Defaults = core.Defaults;
local Settings = core.Settings;
local DKP_Entry = core.DKP_Entry;

local DkpDB;

function DKP:InitDB()
    DkpDB = core.PDKP.dkpDB
    DKP.history = DkpDB['history']
end

function DKP:GetEntries(keysOnly)

    keysOnly = keysOnly or false
    local entry_keys, entries = {}, {};
    for key, _ in pairs(DkpDB['history']['all']) do
        table.insert(entry_keys, key)
        if not keysOnly then
            local dkp_entry = DKP:GetEntry(key)
            entries[key] = dkp_entry
            dkp_entry:Save()
        end
    end
    return entry_keys, entries;
end

function DKP:GetEntry(id)
    local db_entry = DkpDB['history']['all'][id]
    local entry = DKP_Entry:New(db_entry)
    return entry
end

function DKP:RaidNotOny(raid)
    return raid ~= 'Onyxia\'s Lair'
end

--- TESTING FUNCTIONS BELOW

function DKP:TestShroud()
    local memberTable = PDKP.memberTable
    local selectedNames = memberTable.selected;
    for _, name in pairs(selectedNames) do
        local member = Guild:GetMemberByName(name)
        local newTotal = member:QuickCalc('Molten Core', nil)
        print('Old total', member:GetDKP('Molten Core', 'total'), 'New total:', newTotal)
        member:UpdateDKPTest('Molten Core', newTotal)
    end
    memberTable:RaidChanged()
end

function DKP:ResetDKP()
    local memberTable = PDKP.memberTable
    local selectedNames = memberTable.selected;
    for _, name in pairs(selectedNames) do
        local member = Guild:GetMemberByName(name)
        member:UpdateDKPTest('Molten Core', member.guildIndex)
    end
    memberTable:RaidChanged()
end

function DKP:Submit()
    if not Settings:CanEdit() then
        Util:Debug('Officers are the only ones who can edit DKP')
        return
    end

    local pName = Util:GetMyName()
    if Settings:IsDebug() then
        pName = 'Neekio'
    end

    GUI.adjustment_entry['officer']= pName

    Util:WatchVar(GUI.adjustment_entry, 'adjustment_Entry')

    local entry = DKP_Entry:New(GUI.adjustment_entry)

    for _, name in pairs(entry['names']) do
        local member = Guild:GetMemberByName(name)
        member:NewEntry(entry)
    end
    PDKP.memberTable:RaidChanged()

    entry:Save()
    core.PDKP.dkpDB['history']['lastEdit']=entry.id
end

function DKP:CalculateButton(b_type)
    b_type = b_type or 'Shroud'
    local st = PDKP.memberTable
    if #st.selected == 1 then
        for _, name in pairs(st.selected) do
            local _, rowIndex = tfind(st.rows, name, 'name')
            if rowIndex then
                local row = st.rows[rowIndex]
                if row.dataObj['name'] == name then
                    local member = Guild:GetMemberByName(name)
                    local new_total = member:QuickCalc(Settings.current_raid, b_type)
                    return new_total
                end
            end
        end
    end
end