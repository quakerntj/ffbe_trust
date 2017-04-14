-- Copyright © 2017 Quaker NTj <quakerntj@hotmail.com>
-- <https://github.com/quakerntj/ffbe_autoscript>

--[[
    This script is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This script is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

require("battle_scene")

BattleData = {}
BattleData.__index = BattleData

setmetatable(BattleData, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function BattleData.new()
	local self = setmetatable({}, BattleData)
	self.init = false
    self.enables = {}
    self.actions = {}
    self.indices = {}
    self.orders = {}
    self.isEnemys = {}
    self.targets = {}
	return self
end

DesignedBattle = {}
DesignedBattle.__index = DesignedBattle

setmetatable(DesignedBattle, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function DesignedBattle.new(rounds)
	local self = setmetatable({}, DesignedBattle)
	self.init = false
	self.rounds = rounds
    self.scene = BattleScene()
    self.roundsData = {}
    self.roundAction = 1
	return self
end

function DesignedBattle:triggerReturn()
--    R18_0711:existsClick("right_bottom_return.png")
end

function DesignedBattle:triggerAuto()
    if R28_0711:exists("04_Auto.png") then
        match = R28_0711:getLastMatch()
        R28_0711:click(match)
        wait(1)
        R28_0711:click(match) -- cancel auto
    end
end

function DesignedBattle:hasRepeatButton()
    local m = R28_0711:exists("Repeat.png")
    if m ~= nil then
        local r, g, b = getColor(m)
        return b > 50
    else
        return false
    end
end

function DesignedBattle:triggerRepeat()
    if (R28_0711:existsClick("Repeat.png")) then
        -- make sure all unit run.
        self:triggerAuto()
    end
end

function DesignedBattle:chooseOrders(data, round)
    local UnitOrders = { "1", "2", "3", "4", "5", "6" }
    local UnitTargets = { "1", "2", "3", "4", "5", "6", "All" }

    dialogInit()
        addTextView("順序小的先發動, 相同的就按兵員順序")newRow()
        addTextView("選擇是否為敵方, 若是己方則選擇治療目標")newRow()
        addTextView("敵方不支援指定目標, 選什麼都無效")newRow()
        addTextView("沒有打勾的兵員最後會被Auto觸發")newRow()
        -- addSpinnerIndex and addSpinner accept only global variable
        for i = 1, 6 do
            addTextView("兵員"..i.." 順序")addSpinnerIndex("unitOrder"..i, UnitOrders, UnitOrders[3])
            addCheckBox("unitIsEnemy"..i, "敵方?", true)addTextView("目標")
            addSpinnerIndex("unitTarget"..i, UnitTargets, 7)newRow()
        end
    dialogShow("順序與目標 for Round "..round)

    data.orders = { unitOrder1, unitOrder2, unitOrder3, unitOrder4, unitOrder5, unitOrder6 }
    data.isEnemys = { unitIsEnemy1, unitIsEnemy2, unitIsEnemy3, unitIsEnemy4, unitIsEnemy5, unitIsEnemy6 }
    data.targets = { unitTarget1, unitTarget2, unitTarget3, unitTarget4, unitTarget5, unitTarget6 }

    -- clean used global variable
    for i = 1, 6 do
        _G["unitOrder"..i] = nil
        _G["unitIsEnemy"..i] = nil
        _G["unitTarget"..i] = nil
    end
end

function DesignedBattle:chooseActions(data, round)
    if round == nil then round = 1 end
    UnitActions = { "攻擊", "能力", "道具", "防禦" }
    dialogInit()
        addTextView("輸入技能與道具的'欄位'自左向右, 然後換行, 由1開始, 1是極限技")newRow()
        addTextView("目前道具只能用在自己身上")newRow()
        for i = 1, 6 do
        offset = i + (round - 1) * 6
            addCheckBox("unitEnable"..i, "兵員"..i, true)
            addTextView("行動")addSpinnerIndex("unitAction"..offset, UnitActions, 1)
            addTextView("欄位")addEditNumber("unitIndex"..offset, 1)newRow()
        end
    dialogShow("行動與欄位 for Round "..round)

    for i = 1, 6 do
        offset = i + (round - 1) * 6

        -- fill tables.
        local en = loadstring("return unitEnable"..offset)
        local act = loadstring("return unitAction"..offset)
        local id = loadstring("return unitIndex"..offset)
        data.enables[i] = en()
        data.actions[i] = act()
        data.indices[i] = id()

        -- clean used global variable
        _G["unitEnable"..i] = nil
        _G["unitAction"..i] = nil
        _G["unitIndex"..i] = nil
    end
end

function DesignedBattle:run(data)
    -- create shortcuts
    local enables  = data.enables
    local actions  = data.actions
    local indices  = data.indices
    local orders   = data.orders
    local isEnemys = data.isEnemys
    local targets  = data.targets

    local waitAction = 0.3
    local waitChooseItem = 0.3
    local waitChooseTarget = 0.3
    
    local units = self.scene.units
    local page = self.scene.page

    -- Start config actions.
    for unit = 1, 6 do
        if enables[unit] then
            local action = actions[unit]
            if action == 1 then
                -- action == 1 do nothing.
            elseif action == 4 then
                units[unit]:defence()
                wait(waitAction)
            else -- 2 or 3
                if action == 2 then
                    units[unit]:abilityPage()
                elseif action == 3 then
                    units[unit]:itemPage()
                end
                wait(waitAction)
                if page:choose(indices[unit]) then
                    wait(waitChooseItem)
                    if (isEnemys[unit] and (targets[unit] == 7)) then
                        -- Do nothing
                    elseif (isEnemys[unit] and (not (targets[unit] == 7))) then
                        -- TODO Not support attack specified target now...
                    elseif ((not isEnemys[unit]) and (targets[unit] == 7)) then
                        units[1]:submit()
                        wait(waitChooseTarget)
                    elseif (not isEnemys[unit]) then
                        units[targets[unit]]:submit()
                        wait(waitChooseTarget)
                    end
                else
                    -- TODO click right-bottom return
                end
            end
            wait(0.1)
        end
    end
    
    if not self.trigger then return end

    -- Sort unit by orders, and Submit
    for i = 1, 6 do
        local keys = {}
        keys = hasValue(orders, i)
        for j,unit in ipairs(keys) do
            if enables[unit] then
                self.scene.units[unit]:submit()
            end
        end
    end
    
    -- Let rest units run auto.
    self:triggerAuto()
end

function DesignedBattle:interaction(round)
	vibrate(1)
    dialogInit()
        addTextView("請等到所有隊員皆有行動力之後再按確認")newRow()
        addRadioGroup("DB_ROUND_ACTION", 1)
            addRadioButton("Repeat 指定回合指令", 1)
            addRadioButton("執行本回合("..round..")指令", 2)
            if round ~= 1 then
                addRadioButton("不增加回合, 重複上回合指令", 3)
                addRadioButton("不增加回合, 並且使用Auto", 4)
                addRadioButton("不增加回合, 並且使用Repeat", 5)
                addRadioButton("結束互動式, 按照上一回合設定的行動", 10)
            end
        addCheckBox("DB_TRIGGER", "設定完技能後是否觸發動作", true)newRow()
    	vibrate(1)
    dialogShow("回合"..round)

    self.roundAction = DB_ROUND_ACTION
    self.trigger = DB_TRIGGER
end

function DesignedBattle:initialize()
    -- total 4 * 3 rounds.  Maybe enough.
    local Rounds = { "1回合", "2回合", "3回合", "4回合", "5回合", "6回合",
        "7回合", "8回合", "9回合", "10回合", "11回合", "12回合", "不重複" }
    dialogInit()
        addTextView("建議手動將所有隊員可用的能力與道具的編號先手抄下來")newRow()
        addTextView("第一次執行每個回合都要設一次資料, 但是設定會被記住")newRow()
        addTextView("之後別改兵員與幻獸即可通用")newRow()
        addTextView("如果無法一回合內清光敵人, 請增加回合數")newRow()newRow()
        
        addCheckBox("DB_NEED_INTERACTION", "回合互動式, 每回合問一次行動", false)newRow()newRow()
        addTextView("總回合數: ")addSpinnerIndex("DB_TOTAL_ROUNDS", Rounds, self.rounds)newRow()
        addTextView("自動重複第")addSpinnerIndex("DB_REPEAT_ROUNDS", Rounds, Rounds[13])newRow()
        addCheckBox("DB_TRIGGER", "設定完技能後是否觸發動作", true)newRow()
    dialogShow("Initialize")
    
    self.needInteraction = DB_NEED_INTERACTION
    self.trigger = DB_TRIGGER
    self.rounds = DB_TOTAL_ROUNDS
    self.repeatRound = DB_REPEAT_ROUNDS
    if self.repeatRound == 13 then
        -- No specified repeat round.  Each round will need config action once.
        self.roundAction = 2
    else
        -- specified repeat round.  if round data not exist, create new data.
        self.roundAction = 1
    end
    self.init = true
end

function DesignedBattle:obtain(round)
    if self.roundsData[round] == nil then
        self.roundsData[round] = BattleData()
    end

    local data = self.roundsData[round]
    if not data.init then
        self:chooseActions(data, round)
        self:chooseOrders(data, round)
        data.init = true
    end
    return data
end


function DesignedBattle:loop()
    if (not self.init) then
        self:initialize()
    end

    local rounds = self.rounds
    local data
    for round = 1, rounds do
        toast("round "..round)
        repeat until self:hasRepeatButton()

        if self.needInteraction then
            self:interaction(round)
        end
        toast("round "..round.."/"..rounds.."start")

        if self.roundAction == 1 then
            data = self:obtain(self.repeatRound)
            self:run(data)
        elseif self.roundAction == 2 then
            data = self:obtain(round)
            self:run(data)
        elseif self.roundAction == 3 then
            round = round - 1
            self:run(data)
        elseif self.roundAction == 4 then
            round = round - 1
            self:triggerAuto()
        elseif self.roundAction == 5 then
            round = round - 1
            self:triggerRepat()
        end
    end
end