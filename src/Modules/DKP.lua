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

DKP.entries = {};
DKP.history_entries = {};

function DKP:InitDB()
    DkpDB = core.PDKP.dkpDB
    DKP.history = DkpDB['history']

    Util:WatchVar(DkpDB['history']['all'], 'DkpDB')
end

function DKP:GetEntries(keysOnly, id)
    local history = DkpDB['history']['all']
    local deleted = DkpDB['history']['deleted']

    if id then
        local cache_entry = DKP.history_entries[id]
        if cache_entry == nil then
            if history[id] ~= nil then
                cache_entry = DKP_Entry:New(history[id])
                DKP.history_entries[id] = cache_entry
            end
        end
        return cache_entry
    end

    keysOnly = keysOnly or false
    local entry_keys, entries = {}, {};

    for key, _ in pairs(history) do
        if not tContains(deleted, key) then
            table.insert(entry_keys, key)
            if not keysOnly then
                local dkp_entry = DKP_Entry:New(history[key])
                if not dkp_entry['deleted'] then
                    entries[key] = dkp_entry
                    dkp_entry:Save()
                end
            end
        end
    end

    local compare = function(a,b)
        if type(a) == type({}) and type(b) == type({}) then
            return a['id'] > b['id']
        else
            if type(a) == type(1) and type(b) == type(1) then
                return a > b
            end
        end
    end

    table.sort(entry_keys, compare)
    table.sort(entries, compare)

    return entry_keys, entries;
end

function DKP:RaidNotOny(raid)
    return raid ~= 'Onyxia\'s Lair'
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
    GUI.adjustment_entry['names'] = { unpack(PDKP.memberTable.selected) }

    local entry = DKP_Entry:New(GUI.adjustment_entry)

    print(entry['historyText'])

    for _, name in pairs(entry['names']) do
        local member = Guild:GetMemberByName(name)
        member:NewEntry(entry)
    end

    entry:Save()
    core.PDKP.dkpDB['history']['lastEdit']=entry.id

    GUI:RefreshTables()
end

function DKP:DeleteEntry()
    local entry = GUI.popup_entry;

    print('Deleting entry', entry['id'])

    DkpDB['history']['all'][entry['id']]['deleted']=true -- Mark the entry as having been deleted.

    for key, name in pairs(entry['names']) do
        local member = Guild:GetMemberByName(name)
        member:DeleteEntry(entry)
    end
    tremove(DkpDB['history']['all'], entry['id'])
    DkpDB['history']['all'][entry['id']] = nil;
    tinsert(DkpDB['history']['deleted'], entry['id'])

    GUI.history_table:HistoryUpdated()
    GUI.memberTable:RaidChanged()

    GUI.popup_entry = nil;
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

function DKP:ResetDKP(selected)
    if selected then
        local memberTable = PDKP.memberTable
        local selectedNames = memberTable.selected;

        for _, name in pairs(selectedNames) do
            local member = Guild:GetMemberByName(name)
            member:UpdateDKPTest('Molten Core', member.guildIndex)
        end

        DkpDB['history']['all']={}
        DkpDB['history']['deleted']={}
    else

    end


    memberTable:RaidChanged()
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