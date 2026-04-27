-- ~/.hammerspoon/init.lua
-- Migrated from ~/.phoenix.js + scroll mode

-------------------------------------------------------
-- Reload
-------------------------------------------------------
hs.hotkey.bind({'cmd', 'ctrl'}, 'r', hs.reload)

-------------------------------------------------------
-- Mode state (forward declared for interop)
-------------------------------------------------------
local scrollMode = false
local cursorMode = false
local exitScrollMode -- defined below
local exitCursorMode -- defined below

-------------------------------------------------------
-- Scroll Mode (NEW - like Vimac)
-------------------------------------------------------
local scrollBorder = nil
local scrollKeys = {}
local scrollSpeed = 5

local function showScrollBorder()
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:frame()
    scrollBorder = hs.canvas.new(f):appendElements({
        type = 'rectangle',
        action = 'stroke',
        strokeColor = { red = 1, green = 0, blue = 0, alpha = 0.8 },
        strokeWidth = 4,
    }):level(hs.canvas.windowLevels.overlay):show()
end

local function hideScrollBorder()
    if scrollBorder then scrollBorder:delete(); scrollBorder = nil end
end

local function setScrollKeys(enabled)
    for _, k in ipairs(scrollKeys) do
        if enabled then k:enable() else k:disable() end
    end
end

exitScrollMode = function()
    scrollMode = false
    hideScrollBorder()
    setScrollKeys(false)
end

local function enterScrollMode()
    if scrollMode then return end
    if cursorMode then exitCursorMode() end
    scrollMode = true
    showScrollBorder()
    setScrollKeys(true)
end

scrollKeys = {
    -- j/k: scroll down/up (hold to repeat)
    hs.hotkey.new({}, 'j', function()
        hs.eventtap.scrollWheel({0, -scrollSpeed}, {})
    end, nil, function()
        hs.eventtap.scrollWheel({0, -scrollSpeed}, {})
    end),
    hs.hotkey.new({}, 'k', function()
        hs.eventtap.scrollWheel({0, scrollSpeed}, {})
    end, nil, function()
        hs.eventtap.scrollWheel({0, scrollSpeed}, {})
    end),
    -- h/l: scroll left/right (hold to repeat)
    hs.hotkey.new({}, 'h', function()
        hs.eventtap.scrollWheel({scrollSpeed, 0}, {})
    end, nil, function()
        hs.eventtap.scrollWheel({scrollSpeed, 0}, {})
    end),
    hs.hotkey.new({}, 'l', function()
        hs.eventtap.scrollWheel({-scrollSpeed, 0}, {})
    end, nil, function()
        hs.eventtap.scrollWheel({-scrollSpeed, 0}, {})
    end),
    -- d/u: half page down/up
    hs.hotkey.new({}, 'd', function()
        hs.eventtap.scrollWheel({0, -scrollSpeed * 10}, {})
    end),
    hs.hotkey.new({}, 'u', function()
        hs.eventtap.scrollWheel({0, scrollSpeed * 10}, {})
    end),
    -- escape: exit
    hs.hotkey.new({}, 'escape', exitScrollMode),
}
setScrollKeys(false)

hs.hotkey.bind({'cmd', 'ctrl'}, 'j', enterScrollMode)

-- auto-exit on window focus change
hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function()
    if scrollMode then exitScrollMode() end
end)

-------------------------------------------------------
-- Cursor Mode (鼠标 hint 跳转)
-------------------------------------------------------
local cursorCanvas = nil
local cursorKeys = {}
local cursorTargetFrame = nil
local cursorHints = {
    'e', 'r', 'u', 'i',
    'd', 'f', 'j', 'k',
    'c', 'v', 'n', 'm',
}
local cursorCols = 4
local cursorRows = 3
local cursorPendingCell = nil -- {row, col, key} 一级已选、等二级时非 nil

-- 一级 hint → cell 行列
local cursorPrimaryMap = {
    e = {0, 0}, r = {0, 1}, u = {0, 2}, i = {0, 3},
    d = {1, 0}, f = {1, 1}, j = {1, 2}, k = {1, 3},
    c = {2, 0}, v = {2, 1}, n = {2, 2}, m = {2, 3},
}
-- 默认二级九宫格（中心 j = 居中）
local cursorSecondaryDefault = {
    y = {0, 0}, u = {0, 1}, i = {0, 2},
    h = {1, 0}, j = {1, 1}, k = {1, 2},
    n = {2, 0}, m = {2, 1}, [','] = {2, 2},
}
-- 一级与九宫格冲突时（u/i/k/n/m），用此 fallback 键补回那个位置
local cursorFallbackKey = 'g'
-- 需绑定的所有键：一级 ∪ 二级 ∪ fallback
local cursorAllKeys = {
    'e', 'r', 'u', 'i', 'd', 'f', 'j', 'k',
    'c', 'v', 'n', 'm', 'y', 'h', ',', 'g',
}

-- 给定一级字母 cellKey + 用户按下的二级 key，返回九宫格 {row,col} 或 nil
local function cursorResolveSecondary(cellKey, key)
    if key == cellKey then return {1, 1} end -- 重复一级 = 居中
    if key == cursorFallbackKey then
        return cursorSecondaryDefault[cellKey] -- 一级在九宫格里才有效
    end
    return cursorSecondaryDefault[key]
end

local function hideCursorOverlay()
    if cursorCanvas then cursorCanvas:delete(); cursorCanvas = nil end
end

local function setCursorKeys(enabled)
    for _, k in ipairs(cursorKeys) do
        if enabled then k:enable() else k:disable() end
    end
end

exitCursorMode = function()
    cursorMode = false
    cursorTargetFrame = nil
    cursorPendingCell = nil
    hideCursorOverlay()
    setCursorKeys(false)
end

local function showCursorOverlay(frame)
    cursorCanvas = hs.canvas.new(frame)
    cursorCanvas:appendElements({
        type = 'rectangle', action = 'fill',
        fillColor = { black = 1, alpha = 0.15 },
    })
    local cw = frame.w / cursorCols
    local ch = frame.h / cursorRows
    for r = 0, cursorRows - 1 do
        for c = 0, cursorCols - 1 do
            local idx = r * cursorCols + c + 1
            local hint = cursorHints[idx]
            if hint then
                local x = c * cw
                local y = r * ch
                cursorCanvas:appendElements({
                    type = 'rectangle', action = 'stroke',
                    strokeColor = { white = 1, alpha = 0.5 },
                    strokeWidth = 1,
                    frame = { x = x, y = y, w = cw, h = ch },
                })
                local bw = 40
                local bh = 32
                local bx = x + (cw - bw) / 2
                local by = y + (ch - bh) / 2
                cursorCanvas:appendElements({
                    type = 'rectangle', action = 'fill',
                    fillColor = { black = 1, alpha = 0.75 },
                    roundedRectRadii = { xRadius = 6, yRadius = 6 },
                    frame = { x = bx, y = by, w = bw, h = bh },
                })
                cursorCanvas:appendElements({
                    type = 'text',
                    text = string.upper(hint),
                    textColor = { white = 1 },
                    textFont = '.AppleSystemUIFont',
                    textSize = 20,
                    textAlignment = 'center',
                    frame = { x = bx, y = by + 4, w = bw, h = bh },
                })
            end
        end
    end
    cursorCanvas:level(hs.canvas.windowLevels.overlay)
    cursorCanvas:show()
end

local function showSecondaryOverlay(cellRow, cellCol, cellKey)
    if cursorCanvas then cursorCanvas:delete(); cursorCanvas = nil end
    local f = cursorTargetFrame
    if not f then return end
    local cw = f.w / cursorCols
    local ch = f.h / cursorRows
    local cellX = f.x + cellCol * cw
    local cellY = f.y + cellRow * ch

    -- 默认九宫格布局，冲突位置改为 fallback 键
    local layout = {
        { 'y', 'u', 'i' },
        { 'h', 'j', 'k' },
        { 'n', 'm', ',' },
    }
    local conflict = cursorSecondaryDefault[cellKey]
    if conflict and not (conflict[1] == 1 and conflict[2] == 1) then
        layout[conflict[1] + 1][conflict[2] + 1] = cursorFallbackKey
    end

    cursorCanvas = hs.canvas.new({ x = cellX, y = cellY, w = cw, h = ch })
    cursorCanvas:appendElements({
        type = 'rectangle', action = 'fill',
        fillColor = { black = 1, alpha = 0.25 },
    })
    local sw = cw / 3
    local sh = ch / 3
    local bw = math.min(32, sw * 0.7)
    local bh = math.min(26, sh * 0.7)
    local fontSize = math.min(16, sh * 0.35)
    for r = 0, 2 do
        for c = 0, 2 do
            local hint = layout[r + 1][c + 1]
            local x = c * sw
            local y = r * sh
            cursorCanvas:appendElements({
                type = 'rectangle', action = 'stroke',
                strokeColor = { white = 1, alpha = 0.4 },
                strokeWidth = 1,
                frame = { x = x, y = y, w = sw, h = sh },
            })
            local bx = x + (sw - bw) / 2
            local by = y + (sh - bh) / 2
            cursorCanvas:appendElements({
                type = 'rectangle', action = 'fill',
                fillColor = { black = 1, alpha = 0.8 },
                roundedRectRadii = { xRadius = 4, yRadius = 4 },
                frame = { x = bx, y = by, w = bw, h = bh },
            })
            cursorCanvas:appendElements({
                type = 'text',
                text = string.upper(hint),
                textColor = { white = 1 },
                textFont = '.AppleSystemUIFont',
                textSize = fontSize,
                textAlignment = 'center',
                frame = { x = bx, y = by + (bh - fontSize) / 2 - 1, w = bw, h = bh },
            })
        end
    end
    cursorCanvas:level(hs.canvas.windowLevels.overlay)
    cursorCanvas:show()
end

local function enterCursorModeWindow()
    if cursorMode then return end
    if scrollMode then exitScrollMode() end
    local w = hs.window.focusedWindow()
    if not w then return end
    cursorTargetFrame = w:frame()
    cursorMode = true
    showCursorOverlay(cursorTargetFrame)
    setCursorKeys(true)
end

local function enterCursorModeFine()
    if cursorMode then return end
    if scrollMode then exitScrollMode() end
    local w = hs.window.focusedWindow()
    if not w then return end
    local wf = w:frame()
    local subW = wf.w / cursorCols
    local subH = wf.h / cursorRows
    local mouse = hs.mouse.absolutePosition()
    cursorTargetFrame = {
        x = mouse.x - subW / 2,
        y = mouse.y - subH / 2,
        w = subW,
        h = subH,
    }
    cursorMode = true
    showCursorOverlay(cursorTargetFrame)
    setCursorKeys(true)
end

for _, key in ipairs(cursorAllKeys) do
    table.insert(cursorKeys, hs.hotkey.new({}, key, function()
        local f = cursorTargetFrame
        if not f then exitCursorMode(); return end
        if cursorPendingCell then
            local pos = cursorResolveSecondary(cursorPendingCell.key, key)
            if not pos then return end
            local cw = f.w / cursorCols
            local ch = f.h / cursorRows
            local cellX = f.x + cursorPendingCell.col * cw
            local cellY = f.y + cursorPendingCell.row * ch
            local sw = cw / 3
            local sh = ch / 3
            local mx = cellX + pos[2] * sw + sw / 2
            local my = cellY + pos[1] * sh + sh / 2
            exitCursorMode()
            hs.mouse.absolutePosition({ x = mx, y = my })
        else
            local cellPos = cursorPrimaryMap[key]
            if not cellPos then return end
            cursorPendingCell = { row = cellPos[1], col = cellPos[2], key = key }
            showSecondaryOverlay(cellPos[1], cellPos[2], key)
        end
    end))
end
table.insert(cursorKeys, hs.hotkey.new({}, 'escape', exitCursorMode))
setCursorKeys(false)

hs.hotkey.bind({'cmd', 'ctrl'}, 'k', enterCursorModeWindow)
hs.hotkey.bind({'cmd', 'ctrl', 'shift'}, 'k', enterCursorModeFine)
hs.hotkey.bind({'cmd', 'ctrl'}, 'g', function()
    hs.eventtap.leftClick(hs.mouse.absolutePosition())
end)

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function()
    if cursorMode then exitCursorMode() end
end)

-------------------------------------------------------
-- Help Modal (cmd+ctrl+/)
-------------------------------------------------------
local helpText =
    'cmd ctrl F     全屏\n' ..
    'cmd ctrl M     中等大小居中\n' ..
    'cmd ctrl S     低等大小居中\n' ..
    'cmd ctrl H     左半边\n' ..
    'cmd ctrl L     右半边\n' ..
    'cmd ctrl =     平铺多个窗口\n' ..
    'cmd ctrl .     移动当前窗口到下一个 SPACE\n' ..
    'cmd ctrl ,     移动当前窗口到上一个 SPACE\n' ..
    'cmd ctrl ]     移动当前窗口到下一个屏幕\n' ..
    'cmd ctrl [     移动当前窗口到上一个屏幕\n' ..
    'cmd ctrl I     上半屏\n' ..
    'cmd ctrl N     下半屏\n' ..
    'cmd ctrl J     滚动模式\n' ..
    'cmd ctrl K     鼠标 hint 跳转（窗口）\n' ..
    'cmd ctrl shift K  鼠标 hint 跳转（细粒度，鼠标周围）\n' ..
    'cmd ctrl G     在当前鼠标位置左键点击'

local helpCanvas = nil

local function showHelp()
    if helpCanvas then return end
    local screen = hs.screen.mainScreen()
    local sf = screen:frame()

    -- measure text size
    local style = { font = { name = '.AppleSystemUIFont', size = 14 }, color = { white = 1 } }
    local textSize = hs.drawing.getTextDrawingSize(helpText, style)
    local padding = 20
    local w = textSize.w + padding * 2
    local h = textSize.h + padding * 2

    helpCanvas = hs.canvas.new({
        x = sf.x + sf.w - w - 20,
        y = sf.y + 20,
        w = w,
        h = h,
    })
    helpCanvas:appendElements(
        { type = 'rectangle', action = 'fill',
          fillColor = { black = 1, alpha = 0.75 },
          roundedRectRadii = { xRadius = 8, yRadius = 8 } },
        { type = 'text', text = helpText,
          textColor = { white = 1 },
          textFont = '.AppleSystemUIFont',
          textSize = 14,
          frame = { x = tostring(padding) .. 'px', y = tostring(padding) .. 'px',
                    w = tostring(textSize.w) .. 'px', h = tostring(textSize.h) .. 'px' } }
    )
    helpCanvas:level(hs.canvas.windowLevels.overlay)
    helpCanvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    helpCanvas:show()
end

hs.hotkey.bind({'cmd', 'ctrl'}, '/', function()
    if helpCanvas then
        helpCanvas:delete()
        helpCanvas = nil
    else
        showHelp()
    end
end)

-------------------------------------------------------
-- Focus Window Helper
-------------------------------------------------------
local function focusWindow(w)
    if not w then return end
    hs.mouse.absolutePosition({ x = 0, y = 0 })
    w:focus()
    local f = w:frame()
    local appName = w:application() and w:application():name() or ''
    local bundleID = w:application() and w:application():bundleID()
    local icon = bundleID and hs.image.imageFromAppBundle(bundleID)
    if icon then
        hs.alert.showWithImage(appName, icon, { fadeInDuration = 0, fadeOutDuration = 0.1 }, 0.2)
    end
    hs.mouse.absolutePosition({
        x = f.x + f.w / 2,
        y = f.y + f.h / 2,
    })
end

-------------------------------------------------------
-- Window Management
-------------------------------------------------------
-- Phoenix flippedVisibleFrame() = HS screen:frame() (both top-left, excludes dock/menubar)

local function halfLeft()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    w:setFrame({ x = f.x, y = f.y, w = f.w / 2 - 1, h = f.h })
end

local function halfRight()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    local sw = f.w / 2
    w:setFrame({ x = f.x + sw + 1, y = f.y, w = sw - 1, h = f.h })
end

local function halfTop()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    w:setFrame({ x = f.x, y = f.y, w = f.w, h = f.h / 2 - 1 })
end

local function halfBottom()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    local sh = f.h / 2
    w:setFrame({ x = f.x, y = f.y + sh + 1, w = f.w, h = sh - 1 })
end

local function maximize()
    local w = hs.window.focusedWindow()
    if w then w:maximize() end
end

local function medium()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    local wu = math.floor(f.w / 12)
    local hu = math.floor(f.h / 10)
    w:setFrame({ x = f.x + wu, y = f.y + hu, w = wu * 10, h = hu * 8 })
end

local function small()
    local w = hs.window.focusedWindow()
    if not w then return end
    local f = w:screen():frame()
    local wu = math.floor(f.w / 12)
    local hu = math.floor(f.h / 10)
    w:setFrame({ x = f.x + wu * 2, y = f.y + hu * 2, w = wu * 8, h = hu * 6 })
end

local function visibleWinsOnScreen(screen)
    return hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:screen():id() == screen:id() and w:isVisible() and w:isStandard()
    end)
end

local function adaptiveWins()
    local w = hs.window.focusedWindow()
    if not w then return end
    local screen = w:screen()
    local f = screen:frame()
    local ff = screen:fullFrame()
    local ws = visibleWinsOnScreen(screen)
    local l = #ws
    if l == 0 then return end

    if l == 1 then
        ws[1]:setFrame(f)
        return
    end

    -- first window: left half
    ws[1]:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h })

    -- rest: stacked on right
    local ox = f.x + f.w / 2 + 1
    local sh = f.h / (l - 1)
    for i = 2, l do
        ws[i]:setFrame({ x = ox, y = f.y + sh * (i - 2), w = f.w / 2, h = sh })
    end
end

local function swapTwoWins()
    local w = hs.window.focusedWindow()
    if not w then return end
    local ws = visibleWinsOnScreen(w:screen())
    if #ws ~= 2 then return end
    local f1 = ws[1]:frame()
    local f2 = ws[2]:frame()
    ws[1]:setFrame(f2)
    ws[2]:setFrame(f1)
end

local function focusNextWin()
    local screen = hs.screen.mainScreen()
    local ws = visibleWinsOnScreen(screen)
    if #ws == 0 then return end
    local w = hs.window.focusedWindow()
    if not w then focusWindow(ws[1]); return end
    for i, cw in ipairs(ws) do
        if cw:id() == w:id() then
            focusWindow(ws[i % #ws + 1])
            return
        end
    end
    focusWindow(ws[1])
end

local function focusPrevWin()
    local screen = hs.screen.mainScreen()
    local ws = visibleWinsOnScreen(screen)
    if #ws == 0 then return end
    local w = hs.window.focusedWindow()
    if not w then focusWindow(ws[1]); return end
    for i, cw in ipairs(ws) do
        if cw:id() == w:id() then
            focusWindow(ws[(i - 2) % #ws + 1])
            return
        end
    end
    focusWindow(ws[1])
end

local function nextScreen()
    if #hs.screen.allScreens() == 1 then return end
    local other = hs.screen.mainScreen():next()
    local ws = visibleWinsOnScreen(other)
    if #ws > 0 then
        focusWindow(ws[1])
    end
end

-------------------------------------------------------
-- Space Management
-------------------------------------------------------
local spaces = require('hs.spaces')

local function getSpaceList(screen)
    local all = spaces.allSpaces()
    return all[screen:getUUID()] or {}
end

local function moveToNextSpace()
    local w = hs.window.focusedWindow()
    if not w then return end
    local screen = w:screen()
    local sl = getSpaceList(screen)
    if #sl <= 1 then return end
    local cur = spaces.activeSpaceOnScreen(screen)
    for i, sid in ipairs(sl) do
        if sid == cur then
            spaces.moveWindowToSpace(w:id(), sl[i % #sl + 1])
            hs.timer.doAfter(0.1, function() w:focus() end)
            return
        end
    end
end

local function moveToPrevSpace()
    local w = hs.window.focusedWindow()
    if not w then return end
    local screen = w:screen()
    local sl = getSpaceList(screen)
    if #sl <= 1 then return end
    local cur = spaces.activeSpaceOnScreen(screen)
    for i, sid in ipairs(sl) do
        if sid == cur then
            spaces.moveWindowToSpace(w:id(), sl[(i - 2) % #sl + 1])
            hs.timer.doAfter(0.1, function() w:focus() end)
            return
        end
    end
end

local function moveToNextScreenFn()
    local w = hs.window.focusedWindow()
    if not w then return end
    if #hs.screen.allScreens() == 1 then return end
    local ns = w:screen():next()
    local nsid = spaces.activeSpaceOnScreen(ns)
    spaces.moveWindowToSpace(w:id(), nsid)
    local nf = ns:frame()
    w:setFrame(nf)
    hs.timer.doAfter(0.1, function() w:focus() end)
end

-------------------------------------------------------
-- Dropdown Terminal (Ghostty) - uncomment to enable
-------------------------------------------------------
--[[
local function toggleDropdownTerminal()
    local appName = 'Ghostty'
    local app = hs.application.get(appName)
    if not app then
        hs.application.launchOrFocus(appName)
        return
    end
    local mainWin = app:mainWindow()
    if not mainWin then app:activate(); return end

    local focusedWin = hs.window.focusedWindow()
    local curScreen = focusedWin and focusedWin:screen() or hs.screen.mainScreen()
    local sf = curScreen:frame()
    local key = 'terminal_h_' .. tostring(curScreen:id())

    local defaultH = sf.w > sf.h and math.floor(sf.h * 0.8) or math.floor(sf.h * 0.25)

    if app:isFrontmost() and mainWin:isVisible() and mainWin:screen():id() == curScreen:id() then
        hs.settings.set(key, mainWin:frame().h)
        app:hide()
    else
        if mainWin:isVisible() then
            hs.settings.set('terminal_h_' .. tostring(mainWin:screen():id()), mainWin:frame().h)
        end
        local sameScreen = mainWin:screen():id() == curScreen:id()
        local h = sameScreen and mainWin:frame().h or (hs.settings.get(key) or defaultH)
        mainWin:setFrame({ x = sf.x, y = sf.y, w = sf.w, h = h })
        app:activate()
        mainWin:focus()
    end
end
]]

-------------------------------------------------------
-- Keybindings
-------------------------------------------------------
-- Window
hs.hotkey.bind({'cmd', 'ctrl'}, 'h', halfLeft)
hs.hotkey.bind({'cmd', 'ctrl'}, 'l', halfRight)
hs.hotkey.bind({'cmd', 'ctrl'}, 'i', halfTop)
hs.hotkey.bind({'cmd', 'ctrl'}, 'n', halfBottom)
hs.hotkey.bind({'cmd', 'ctrl'}, 'f', maximize)
hs.hotkey.bind({'cmd', 'ctrl'}, 'm', medium)
hs.hotkey.bind({'cmd', 'ctrl'}, 's', small)
hs.hotkey.bind({'cmd', 'ctrl'}, '=', adaptiveWins)
hs.hotkey.bind({'cmd', 'ctrl'}, 'o', swapTwoWins)
hs.hotkey.bind({'cmd', 'ctrl', 'shift'}, 'l', focusNextWin)
hs.hotkey.bind({'cmd', 'ctrl', 'shift'}, 'h', focusPrevWin)
hs.hotkey.bind({'ctrl', 'alt'}, 'h', nextScreen)
hs.hotkey.bind({'ctrl', 'alt'}, 'l', nextScreen)

-- Space
hs.hotkey.bind({'cmd', 'ctrl'}, '.', moveToNextSpace)
hs.hotkey.bind({'cmd', 'ctrl'}, ',', moveToPrevSpace)
hs.hotkey.bind({'cmd', 'ctrl'}, '[', moveToNextScreenFn)
hs.hotkey.bind({'cmd', 'ctrl'}, ']', moveToNextScreenFn)

-- Dropdown terminal (uncomment to enable)
-- hs.hotkey.bind({'cmd', 'ctrl'}, 'space', toggleDropdownTerminal)

-------------------------------------------------------
-- App Launchers
-------------------------------------------------------
local function app(appName, key, mods)
    hs.hotkey.bind(mods, key, function()
        hs.application.launchOrFocus(appName)
        hs.timer.doAfter(0.2, function()
            local a = hs.application.get(appName)
            if a then focusWindow(a:mainWindow()) end
        end)
    end)
end

app('NetEaseMusic', ',', {'alt'})
app('Google Chrome', 'q', {'alt'})
app('Wechat', 'u', {'alt'})
app('Feishu', 'i', {'alt'})
app('Ghostty', '1', {'alt'})
app('DataGrip', '7', {'alt'})
app('Claude', '8', {'alt'})
app('Obsidian', '9', {'alt'})

-------------------------------------------------------
hs.notify.new({ title = 'Hammerspoon', informativeText = '(re)started.' }):send()
