function facts() {
    const screens = Screen.all();
    const sl = screens.length
    const ms = Screen.main()
    let es = ms.next();
    if (ms.hash() === es.hash()) { // means one screen
        es = null
    }

    console.log(sl, ms.hash(), es === null);
}

Key.on('r', ['cmd', 'ctrl'], () => {
    Phoenix.reload()
})


g = {}
g.modelActive = false
g.modal = null
g.escKey = new Key('escape', [], () => {
    Phoenix.log("close by escape")
    closeModal(g.modal)
})

function closeModal(modal) {
    g.escKey.disable()
    g.modelActive = false
    if (modal != null) {
        modal.close()
    }
}

function showModal(modal) {
    g.modelActive = true
    g.modal = modal
    g.modal.show()
    g.escKey.enable()
}

Key.on(',', ['cmd', 'ctrl', 'shift'], () => {
// Show an input modal in the middle of the main screen
    const screenFrame = Screen.main().flippedVisibleFrame();
    if (g.modelActive) {
        return
    }
    const modal = new Modal();

    modal.icon = App.get('Phoenix').icon()
    modal.isInput = true;
    modal.appearance = 'light';
    modal.inputPlaceholder = 'place holder ~'
    modal.origin = {
        x: screenFrame.width / 2 - modal.frame().width / 2, y: screenFrame.height / 4 * 3 - modal.frame().height / 2,
    };
    modal.textDidChange = (value) => {
        console.log('Text did change:', value);
    };
    modal.textDidCommit = (value, action) => {
        console.log('Text did commit:', value, action);
        closeModal(modal)
    };

    showModal(modal)
})

// test space
Key.on('k', ['cmd', 'ctrl'], () => {

    for (let space of Space.all()) {
        console.log('------------')
        console.log(space.hash())

        for (let screen of space.screens()) {
            console.log('screen ', screen.hash())
        }

        for (let window of space.windows()) {
            console.log(window.app().name())
        }

        console.log('------------')
    }

    facts()
})

// end

function _halfLeft() {
    const w = Window.focused()
    console.log('cur ', w.app().name(), w.screen().frame(), w.frame())

    const fvf = w.screen().flippedVisibleFrame()
    // const of = w.frame()
    // set size
    const sw = fvf.width / 2;
    w.setFrame(
        {
            x: fvf.x, y: fvf.y,
            width: sw - 1, height: fvf.height
        }
    )
}

function _halfRight() {
    const w = Window.focused()
    console.log('cur ', w.app().name(), w.screen().frame(), w.frame())

    const fvf = w.screen().flippedVisibleFrame()
    // const of = w.frame()
    // set size
    const sw = fvf.width / 2;
    w.setFrame(
        {
            x: fvf.x + sw + 1, y: fvf.y,
            width: sw - 1, height: fvf.height
        }
    )
}



// adaptive
function _adaptive_wins() {
    const cs = Window.focused().screen()
    // tile mode
    const ws = cs.windows({visible: true})
    const l = ws.length;
    if (l === 0) {
        return
    }

    if (l === 1) {
        const w = ws[0];
        w.setTopLeft({x: 0, y: 0})
        w.setSize({width: w.screen().flippedVisibleFrame().width, height: w.screen().flippedVisibleFrame().height})
        return;
    }

    // others
    const w = ws[0];
    const vw = w.screen().frame().width
    const rh = w.screen().frame().height
    const vh = w.screen().visibleFrame().height
    const tp = rh - vh + 1;

    console.log(vw, vh)
    w.setTopLeft({x: 0, y: 0})
    w.setSize({width: vw / 2, height: vh})

    const ox = vw / 2 + 1
    let oy = tp

    let sh = vh / (ws.length - 1)
    for (let i = 1; i < ws.length; i++) {
        const cw = ws[i]

        cw.setFrame({
            x: ox, y: oy, width: vw / 2, height: sh
        })
        oy += (sh + 1)
    }

    for (let w of ws) {
        console.log(w.app().name());
    }
}



function _nextScreen() {
    if (Screen.all().length === 1) {
        return
    }

    const o = Screen.main().next();
    const fw = o.currentSpace().windows()[0]
    _focusWindow(fw)
    Mouse.move({x: fw.frame().x + fw.frame().width / 2, y: fw.frame().y + fw.frame().height / 2})
}

// activate another screen


/**
 *
 * @param {Window} [fw]
 * @private
 */
function _focusWindow(fw) {
    if (fw === undefined) {
        return
    }

    // do not activate by mouse
    Mouse.move({
        x:0,
        y:0
    })

    fw.focus();

    const icon = fw.app().icon()
    const modal = new Modal()
    modal.icon = icon
    modal.isInput = false;
    modal.appearance = 'light';
    modal.origin = {
        x: fw.frame().x + fw.frame().width / 2 - modal.frame().width / 2,
        y: fw.frame().y + fw.frame().height / 2 - modal.frame().height / 2
    }
    modal.duration = 0.2
    modal.show()

    Mouse.move({
        x: fw.frame().x + fw.frame().width / 2,
        y: fw.frame().y + fw.frame().height / 2
    })
}

function _swap_two_wins() {
    const ws = Screen.main().currentSpace().windows({visible: true})
    if (ws.length !== 2) {
        return
    }
    const w = Window.focused();
    if (w === undefined) {
        _focusWindow(ws[0])
        return;
    }

    // cur is first
    const v = w.hash() === ws[0].hash()
    if (v) {
        const fwr = w.frame();
        const lwr = ws[1].frame();
        w.setFrame(lwr);
        ws[1].setFrame(fwr);
    } else {
        const fwr = w.frame();
        const lwr = ws[0].frame();
        w.setFrame(lwr);
        ws[0].setFrame(fwr);
    }
}

// swap only on two window


// focus next win
function _focus_next_win() {
    const ws = Screen.main().currentSpace().windows({visible: true})
    if (ws.length === 0) {
        return
    }
    const w = Window.focused();
    if (w === undefined) {
        _focusWindow(ws[0])
        return;
    }

    let idx = 0;
    for (let i = 0; i < ws.length; i++) {
        const cw = ws[i]
        if (cw.hash() === w.hash()) {
            idx = i + 1
            break
        }
    }

    if (idx === ws.length) { // means last one
        _focusWindow(ws[0])
    } else {
        _focusWindow(ws[idx])
    }
}




function _focus_pre_win() {
    const ws = Screen.main().currentSpace().windows({visible: true})
    if (ws.length === 0) {
        return
    }
    const w = Window.focused();
    if (w === undefined) {
        _focusWindow(ws[0])
        return;
    }

    let idx = 0;
    for (let i = 0; i < ws.length; i++) {
        const cw = ws[i]
        if (cw.hash() === w.hash()) {
            idx = i - 1
            break
        }
    }

    if (idx < 0) { // means last one
        _focusWindow(ws[ws.length - 1])
    } else {
        _focusWindow(ws[idx])
    }
}




function _maximize() {
    const w = Window.focused()
    if (w === undefined) {
        return
    }

    w.maximize()
}


function _medium() {
    const w = Window.focused()
    if (w === undefined) {
        return
    }

    const fvf = w.screen().flippedVisibleFrame()
    // 12
    const wu = Math.floor(fvf.width / 12)
    // 10
    const hu = Math.floor(fvf.height / 10)

    const frame = {
        x: fvf.x + wu,
        y: fvf.y + hu,
        width: wu * 10,
        height: hu * 8
    };
    console.log(frame.x, frame.y, frame.width, frame.height)
    w.setFrame(frame)
}

function _small() {
    const w = Window.focused()
    if (w === undefined) {
        return
    }

    const fvf = w.screen().flippedVisibleFrame()
    // 12
    const wu = Math.floor(fvf.width / 12)
    // 10
    const hu = Math.floor(fvf.height / 10)

    const frame = {
        x: fvf.x + wu*2,
        y: fvf.y + hu*2,
        width: wu * 8,
        height: hu * 6
    };
    console.log(frame.x, frame.y, frame.width, frame.height)
    w.setFrame(frame)
}


// Space
function _move_next_space() {
    const c = Window.focused();
    if (c === undefined) {
        return;
    }
    // next space
    const sa = Space.all()
    if (sa.length === 1) {
        return
    }

    const s = Space.active()
    const n = s.next()
    n.moveWindows([c])

    const app = c.app()
    setTimeout(() => _focusWindow(app.mainWindow()), 100)
}


function _move_pre_space() {
    const c = Window.focused();
    if (c === undefined) {
        return;
    }
    // next space
    const sa = Space.all()
    if (sa.length === 1) {
        return
    }

    const s = Space.active()
    const n = s.previous()
    n.moveWindows([c])

    const app = c.app()
    setTimeout(() => _focusWindow(app.mainWindow()), 100)
}


// 移动当前宽口到上一个屏幕
function _move_cur_win_2_pre_screen() {
    const c = Window.focused();
    if (c === undefined) {
        return;
    }
    const sa = Screen.all()
    if (sa.length === 1) {
        return;
    }
    const s = c.screen();
    const n = s.previous()
    const ncs = n.currentSpace()
    ncs.moveWindows([c])
    const app = c.app()
    setTimeout(() => _focusWindow(app.mainWindow()), 100)
}

// 移动当前宽口到下一个屏幕
function _move_cur_win_2_next_screen() {
    const c = Window.focused();
    if (c === undefined) {
        return;
    }
    const sa = Screen.all()
    if (sa.length === 1) {
        return;
    }
    const s = c.screen();
    const n = s.next()
    const ncs = n.currentSpace()
    ncs.moveWindows([c])
    const app = c.app()
    setTimeout(() => _focusWindow(app.mainWindow()), 100)
}

function wins() {
// window
    Key.on('l', ['cmd', 'ctrl'], _halfRight)
    Key.on('h', ['cmd', 'ctrl'], _halfLeft)
    Key.on('=', ['cmd', 'ctrl'], _adaptive_wins)
    Key.on('h', ['alt', 'ctrl'], _nextScreen)
    Key.on('l', ['alt', 'ctrl'], _nextScreen)
    Key.on('o', ['cmd', 'ctrl'], _swap_two_wins)
    Key.on('l', ['cmd', 'ctrl', 'shift'], _focus_next_win)
    Key.on('h', ['cmd', 'ctrl', 'shift'], _focus_pre_win)
    Key.on('m', ['cmd', 'ctrl'], _medium)
    Key.on('s', ['cmd', 'ctrl'], _small)
    Key.on('.', ['cmd', 'ctrl'], _move_next_space)
    Key.on(',', ['cmd', 'ctrl'], _move_pre_space)
    Key.on('f', ['cmd', 'ctrl'], _maximize)
    Key.on('[', ['cmd', 'ctrl'], _move_cur_win_2_pre_screen)
    Key.on(']', ['cmd', 'ctrl'], _move_cur_win_2_next_screen)
}


// App

function _app(appName, key, modifiers) {
    return Key.on(key, modifiers, () => {
        a = App.launch(appName)
        a.activate()
        _focusWindow(a.mainWindow())
        // a.focus()
    })
}

function apps() {
    // _app('QQMusic', ',', ['alt'])
    _app('NetEaseMusic', ',', ['alt'])
    _app('Google Chrome', 'q', ['alt'])
    _app('Wechat', 'u', ['alt'])
    _app('Feishu', 'i', ['alt'])

    _app('IntelliJ IDEA Ultimate', '1', ['alt'])
    _app('PyCharm Professional Edition', '2', ['alt'])
    _app('Clion', '4', ['alt'])
    _app('DataGrip', '7', ['alt'])
    _app('MacVim', '8', ['alt'])
    _app('Obsidian', '9', ['alt'])

}

apps()
wins()

// end
Phoenix.notify('(re)started.')
