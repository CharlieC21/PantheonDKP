local _, core = ...;
local _G = _G;
local L = core.L;

local Defaults = core.Defaults;
local Settings = core.Settings;
local Util = core.Util;
local Char = core.Character;
local GUI = core.GUI;
local PDKP = core.PDKP;
local Guild = core.Guild;
local Comms = core.Comms;

local IsInRaid, GetRaidRosterInfo = IsInRaid, GetRaidRosterInfo
local GetInstanceInfo, GetNumSavedInstances, GetSavedInstanceInfo = GetInstanceInfo, GetNumSavedInstances, GetSavedInstanceInfo
local GetNumLootItems, GetLootSlotInfo = GetNumLootItems, GetLootSlotInfo
local LoggingCombat, SendChatMessage = LoggingCombat, SendChatMessage
local StaticPopupDialogs, StaticPopup_Show = StaticPopupDialogs, StaticPopup_Show
local InviteUnit, ConvertToRaid = InviteUnit, ConvertToRaid;

local trim, lower, contains = strtrim, strlower, tContains

local tostring, print, setmetatable, pairs = tostring, print, setmetatable, pairs
local canEdit, bossIDS = core.canEdit, core.bossIDS;

local Raid = core.Raid;

Raid.raid = nil;
Raid.events_frame = nil;

Raid.recent_boss_kill = {};

Raid.__index = Raid; -- Set the __index parameter to reference Raid

local raid_events = {'GROUP_ROSTER_UPDATE', 'CHAT_MSG_WHISPER'}

function Raid:new()
    local self = {};
    setmetatable(self, Raid); -- Set the metatable so we used Members's __index

    Raid.raid = self

    -- Variables / Attributes.
    self.classes = {};
    self.MasterLooter = nil;
    self.dkpOfficer = nil;
    self.members = {};
    self.assistants = {};
    self.leader = {};

    self:RegisterEvents();
    self:Init();



    return self
end

function Raid:Init()
    local raid_info = self:GetRaidInfo() or {}
    self.members = raid_info['names']
    self.classes = raid_info['classes']
    self.MasterLooter = raid_info['ML']
    self.assistants = raid_info['assist']
    self.leader = raid_info['leader']
    GUI:UpdateRaidClassGroups()

    if Raid:InRaid() and self.dkpOfficer == nil then
        Comms:SendCommsMessage('pdkpWhoIsDKP', nil, 'RAID', nil, nil, nil)
    end
end

function PDKP_Raid_OnEvent(self, event, arg1, ...)

    local regular_events = {
        ['CHAT_MSG_WHISPER']=function(arg1, ...)
            local msg, _, _, _, name, _, _, _, _, _, _, _, _, _, _, _, _ = arg1, ...
            msg = lower(msg)
            msg = trim(msg)
            local invite_cmds = GUI.invite_control['commands']
            if contains(invite_cmds, msg) then return Raid:InviteName(name) end
        end,
    }

    if regular_events[event] then return regular_events[event](arg1, ...) end

    if not Raid:InRaid() then return Util:Debug("Not In Raid, Ignoring event") end
    local raid_size = GetNumGroupMembers()

    local raid_group_events = {
        ['GROUP_ROSTER_UPDATE']=function()
            if not GetRaidRosterInfo(raid_size) then return end
            Raid.raid:Init()
            GUI:UpdateInRaidFilter()
        end,
    }

    if raid_group_events[event] then raid_group_events[event]() end
end

function Raid:RegisterEvents()
    if Raid.events_frame ~= nil then
        Util:Debug('Setting up raid events')
        for _, eventName in pairs(raid_events) do Raid.events_frame:UnregisterEvent(eventName) end
        Raid.events_frame = nil
    end

    Raid.events_frame = CreateFrame("Frame", nil, UIParent)
    for _, eventName in pairs(raid_events) do Raid.events_frame:RegisterEvent(eventName) end
    Raid.events_frame:SetScript("OnEvent", PDKP_Raid_OnEvent)
end

function Raid:InviteName(name)
    local ignore_from = GUI.invite_control['ignore_from']
    if contains(ignore_from, name) then
        return print("Invite request from", name, "has been ignored")
    end

    if Raid:InRaid() then
        if not (Raid.raid.leader == Char:GetMyName() or tContains(Raid.raid.assistants, Char:GetMyName())) then
            SendChatMessage("Whisper " .. Raid.raid.leader .. " for invite, I don\'t have assist", "WHISPER", nil, name)
            return
        end
    else
        ConvertToRaid()
    end
    InviteUnit(name)
end

function Raid:GetClassNames(class)
    local raid_roster = Raid:GetRaidInfo() or {}
    if tEmpty(raid_roster) then return {} end
    return raid_roster['classes'][class]
end

function Raid:GetRaidSize()
    return GetNumGroupMembers()
end

function Raid:InRaid()
    return UnitInRaid("player") ~= nil
end

function Raid:NewBossKill()
    --return Raid:BossKill(669, 'Sulfuron Harbinger');
end

function Raid:GetRaidInfo()
    if not Raid:InRaid() then return end

    local raidRoster = {
        ['names']={},
        ['classes']={},
        ['ML']=nil,
        ['dkpOfficer']=nil,
        ['dead']={},
        ['assist']= {},
        ['leader']='',
    }

    for key, class in pairs(Defaults.classes) do raidRoster['classes'][class] = {} end
    raidRoster['classes']['Tank'] = {}

    for i=1, 40 do
        local name, rank, subgroup, level, class, fileName,
        zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if name ~= nil then
            table.insert(raidRoster['names'], name)
            if role ~= nil and role == 'MAINTANK' then
                table.insert(raidRoster['classes']['Tank'], name)
            else
                table.insert(raidRoster['classes'][class], name)
            end

            if isML then raidRoster['ML']=name end
            if isDead then table.insert(raidRoster['dead'], name) end
            if rank == 2 then raidRoster['leader'] = name end
            if rank == 1 then table.insert(raidRoster['assist'], name) end
        end
    end
    return raidRoster
end

function Raid:BossKill()
    --if not canEdit then return end; -- If you can't edit, then you shoudln't be here.
    --
    --local bk
    --for raidName, raidObj in pairs(bossIDS) do
    --    if bk == nil then
    --        for pdkpBossID, pdkpBossName in pairs(raidObj) do
    --            if pdkpBossID == bossID or pdkpBossName == bossName then
    --                bk = {
    --                    name=pdkpBossName,
    --                    id=pdkpBossID,
    --                    raid=raidName,
    --                }
    --                break
    --            end
    --        end
    --    else
    --        break
    --    end
    --end
    --
    --if bk == nil then return end; -- We should have found the boss kill by now.
    --
    ---- You are the DKP Officer
    ---- There is no dkp Officer, but you're the master looter
    --
    --local dkpOfficer = Raid.dkpOfficer
    --
    --if ( ( dkpOfficer and Raid:IsDkpOfficer() ) or ( not dkpOfficer and RaidIsMasterLooter() ) ) then
    --    Util:Debug('You are not the master looter, and not dkpOffcier.')
    --    return
    --end
    --
    --local popup = StaticPopupDialogs["PDKP_RAID_BOSS_KILL"];
    --popup.text = bk.name .. ' was killed! Award 10 DKP?'
    --popup.bossInfo = bk;
    --StaticPopup_Show('PDKP_RAID_BOSS_KILL')
end

function Raid:GetCurrentRaid()
    name, instance_type, difficultyIndex, difficultyName, maxPlayers,
    dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()
    if tContains(Defaults.raids, name) then
        return name
    elseif currentRaid ~= nil and tContains(Defaults.raids, currentRaid) then
        return currentRaid
    else
        return Settings.current_raid;
    end
end

function Raid:GetInstanceInfo()
    name, instance_type, difficultyIndex, difficultyName, maxPlayers,
    dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()
end

function Raid:IsRaidLead()
    if Raid.raid == nil or not Raid:InRaid() then return false end
    return Char:GetMyName() == Raid.raid['leader']
end

function Raid:IsAssist()
    local myName = Char:GetMyName()
    local assists = Raid.raid['assistants']
    local member = Guild:GetMemberByName(myName)

end

function Raid:SetLootCommon()
    if not Raid:InRaid() or not Raid:IsRaidLead() then return end -- Nothing to set if we're not in a raid and not the leader.
    local ml = Raid.raid['MasterLooter'] or Char:GetMyName()
    SetLootMethod("Master", ml, '1')
    print("Loot threshold updated")
end

function Raid:PromoteLeadership()
    if not Raid:IsRaidLead() then return end
    local raid_names = Raid.raid.members

    for i=1, 40 do
        local name, _, _, _, _, _, _, _, _, _, isML, _ = GetRaidRosterInfo(i);
        if name ~= nil then -- The member actually exists in the raid
            local m = Guild:GetMemberByName(name)
            if m ~= nil then -- We have the member in the GuildDB
                if m.isClassLeader or m.isOfficer or isML then
                    PromoteToAssistant('raid' .. i)
                end
            end
        end
    end
end

function Raid:MemberIsInRaid(name)
    if Raid.raid == nil then return false end
    return tContains(Raid.raid['members'], name)
end

function Raid:SetDkpOfficer(isDkpOfficer, charName)
    print(isDkpOfficer, charName)
    if isDkpOfficer then
        Raid.raid.dkpOfficer = nil
        PDKP:Print(charName .. ' is no longer the DKP Officer')
    else
        Raid.raid.dkpOfficer = charName;
        PDKP:Print(charName .. ' is now the DKP Officer')
    end
end

function Raid:IsDkpOfficer()
    local dkpOfficer = Raid.raid.dkpOfficer
    if dkpOfficer == nil then return false end
    return dkpOfficer == Char:GetMyName()
end

function Raid:IsMasterLooter()
    if Raid.raid.MasterLooter == nil then return false end
    return Char:GetMyName() == Raid.raid.MasterLooter
end

--- Debug funcs
function Raid:TestBossKill()
    local raids = Defaults.bossIDS
    local raid_bosses = raids[Settings.current_raid]
    for id, name in pairs(raid_bosses) do
        return {
            ['name']=name,
            ['id']=id,
            ['raid']=Settings.current_raid
        }
    end
end

-- Events: PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA, GROUP_ROSTER_UPDATE,
-- CHAT_MSG_ADDON -- This might allow us to unregister from non-wanted events when in raid