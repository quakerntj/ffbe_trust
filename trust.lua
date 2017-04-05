--
-- Created by IntelliJ IDEA.
-- User: vic
-- Date: 2016/10/31
-- Time: 下午 01:38
-- To change this template use File | Settings | File Templates.
--

-- ========== Settings ================
Settings:setCompareDimension(true, 1440)--執行圖形比對時螢度的解析度。根據compareByWidth的值的值設定成寬度或高度
Settings:setScriptDimension(true, 1440)--用於參考App解析度腳本內座標位置
Settings:set("MinSimilarity", 0.65)
setImmersiveMode(true)
setBrightness(10)
screen = getAppUsableScreenSize()
X = screen:getX()
Y = 2560 -- screen:getY()
DEBUG = false

dialogInit()
CLEAR_LIMIT = 999                -- Step now
addTextView("執行次數：")addEditNumber("CLEAR_LIMIT", 999)newRow()
--addTextView("體力不足時等待 (分)：")addEditNumber("WAIT_TIME", 3)newRow()
addTextView("選擇關卡：")newRow()
addRadioGroup("QUEST", 1)addRadioButton("入口", 1)addRadioButton("最深處", 2)newRow()
addCheckBox("FRIEND", "選擇朋友", false)newRow()
addCheckBox("BUY", "使用寶石回復體力 ", false)addEditNumber("BUY_LOOP", 2)addTextView(" 回")newRow()
dialogShow("Trust Master Maker".." - "..X.." × "..Y)

X12 = X / 2
X14 = X / 4
X34 = X * 3 / 4
X13 = X / 3
X23 = X * 2 / 3

Y12 = Y / 2
Y14 = Y / 4
Y34 = Y * 3 / 4
Y13 = Y / 3
Y23 = Y * 2 / 3

all = Region(0,0,X,Y)
-- 1/2
upper = Region(0, 0, X, Y12)
center= Region(0, Y14, X, Y34)
lower = Region(0, Y12, X, Y)
left  = Region(0, 0, X12, Y)
right = Region(X12, 0, X, Y)
-- 1/3
middle = Region(0, Y/3, X, 2*Y/3)
lowerMiddle = Region(X13, Y23, X23, Y)
-- 1/4
upperLeft  = Region(0, 0, X12, Y12)
upperRight = Region(X12,0, X, Y12)
lowerLeft  = Region(0, Y12, X12, Y)
lowerRight = Region(X12,Y12, X, Y)
upperUpper = Region(0, 0, X, Y14)
upperLower = Region(0, Y14, X, Y12)
lowerUpper = Region(0, Y12, X, Y34)
lowerLower = Region(0, Y34, X, Y)
leftLeft   = Region(0, 0, X14, Y)
leftRight  = Region(X14,0, X12, Y)
rightLeft  = Region(X12,0, X34, Y)
rightRight = Region(X34,0, X, Y)

-- 1/6
middleRight = Region(X13, Y12, X23, Y)

-- 1/8
upperUpperLeft  = Region(0, 0, X12, Y14)
upperUpperRight = Region(X12, 0, X, Y14)
upperLowerLeft  = Region(0, Y14, X12, Y12)
upperLowerRight = Region(X12, Y14, X, Y12)
lowerUpperLeft  = Region(0, Y12, X12, Y34)
lowerUpperRight = Region(X12, Y12, X, Y34)
lowerLowerLeft  = Region(0, Y34, X12, Y)
lowerLowerRight = Region(X12, Y34, X, Y)

lowerUpperMiddle = Region(X13, Y12, X23, Y34)
lowerLowerMiddle = Region(X13, Y34, X23, Y)
-- ==========  main program ===========
STEP = 1
CLEAR = 0                -- Stage clear times
ON_AUTO = false
ERROR_COUNT = 0
if (QUEST == 1) then
    QUEST_NAME= "01_The_Temple_of_Earth_Entry.png"
elseif (QUEST == 2) then
    QUEST_NAME=  "01_The_Temple_of_Earth_End.png"
else
    QUEST_NAME= "01_The_Temple_of_Earth_Entry.png"
end

if (FRIEND) then
    FRIEND_NAME = "02_Pick_up_friend.png";
else
    FRIEND_NAME = "02_No_friend.png";
end
switch = {
    [  1 ] = function()
        if (existsClick(QUEST_NAME)) then
            if (lowerLowerMiddle:existsClick("06_Next.png")) then
                if (upperLower:existsClick(FRIEND_NAME)) then
                    STEP = 2
                end
            else
                if (BUY and middleRight:existsClick("Use_Gem.png")) then
                    lowerUpperRight:existsClick("Buy_Yes.png")
                    print("使用寶石回復體力")
                    break;
                else
                    if (lowerUpperMiddle:existsClick("Stamina_Back.png")) then
                        toast('體力不足，等待中...')
                        print("Wait for stamina")
                        setScanInterval(10)
                        wait(30)
                        setScanInterval(2)
                    end
                end
            end
        else
            toast('找不到 "土之神殿。入口 "')
            existsClick("06_Next.png")
            existsClick("09_Return.png")
            STEP = 1
        end
    end,
    [ 2 ] = function()
        if (existsClick("03_Go.png")) then
            STEP = 3
        end
    end,
    [ 3 ] = function()
        if (ON_AUTO) then
            if (lowerLowerMiddle:existsClick("06_Next1.png")) then
                ON_AUTO = false
                STEP = 4
                setScanInterval(2)
            end
        elseif (lowerLowerLeft:existsClick("04_Auto1.png")) then
            ON_AUTO = true
            setScanInterval(10)
        end
    end,
    [ 4 ] = function()
        if (upperRight:existsClick("07_Next_2.png")) then
            wait(1)
        elseif (lowerLowerMiddle:exists("06_Next.png")) then
            STEP = 5
        end
    end,
    [ 5 ] = function()
        if (lowerLowerMiddle:existsClick("06_Next.png")) then
            lowerLowerMiddle:existsClick("06_Next.png")
            existsClick("08_No_Friend.png", 5)
            STEP = 1
            CLEAR = CLEAR + 1
        elseif (exists("01_The_Temple_of_Earth.png")) then
            STEP = 1
        end
    end
}

repeat
    switch[STEP]()
    if (middle:exists("Communication_Error.png")) then
        middle:existsClick("OK.png")
    end
    FINISH = false
    if (CLEAR == CLEAR_LIMIT) then    -- Step repeat check
        FINISH = true
        print("Quest clear:"..CLEAR.."/"..CLEAR_LIMIT)
    elseif (ERROR_COUNT == 5) then
        FINISH = true
        print("程式錯誤，腳本跳出")
        toast("程式錯誤，腳本跳出")
    else
        FINISH = false
        if (STEP == 1) then
            toast("Quest clear:"..CLEAR.."/"..CLEAR_LIMIT)
        end
    end
until FINISH
