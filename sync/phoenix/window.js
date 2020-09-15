function sortByMostRecent(windows) {
  var visibleAppMostRecentFirst = _.map(
    Window.recent(), function (w) { return w.hash(); }
  );
  var visibleAppMostRecentFirstWithWeight = _.zipObject(
    visibleAppMostRecentFirst, _.range(visibleAppMostRecentFirst.length)
  );
  return _.sortBy(windows, function (window) { return visibleAppMostRecentFirstWithWeight[window.hash()]; });
};

function getResizeFrame(frame, ratio) {
  var mid_pos_x = frame.x + 0.5 * frame.width;
  var mid_pos_y = frame.y + 0.5 * frame.height;
  return {
    x: Math.round(frame.x + frame.width / 2 * (1 - ratio)),
    y: Math.round(frame.y + frame.height / 2 * (1 - ratio)),
    width: Math.round(frame.width * ratio),
    height: Math.round(frame.height * ratio)
  }
}

function getSmallerFrame(frame) {
  return getResizeFrame(frame, 0.9);
}

function getLargerFrame(frame) {
  return getResizeFrame(frame, 1.1);
}

function getCurrentWindow() {
  var window = Window.focused();
  if (window === undefined) {
    window = App.focused().mainWindow();
  }
  if (window === undefined) {
    return;
  }
  return window;
}

/**
 * Screen Functions
 */
function moveToScreen(window, screen) {
  if (!window) return;
  if (!screen) return;

  var frame = window.frame();
  var oldScreenRect = window.screen().visibleFrameInRectangle();
  var newScreenRect = screen.visibleFrameInRectangle();
  var xRatio = newScreenRect.width / oldScreenRect.width;
  var yRatio = newScreenRect.height / oldScreenRect.height;

  var mid_pos_x = frame.x + Math.round(0.5 * frame.width);
  var mid_pos_y = frame.y + Math.round(0.5 * frame.height);

  window.setFrame({
    x: (mid_pos_x - oldScreenRect.x) * xRatio + newScreenRect.x - 0.5 * frame.width,
    y: (mid_pos_y - oldScreenRect.y) * yRatio + newScreenRect.y - 0.5 * frame.height,
    width: frame.width,
    height: frame.height
  });
};


/**
 * Window Functions
 */
function heartbeat_window(window) {
  ACTIVE_WINDOWS_TIMES[window.app().pid] = new Date().getTime() / 1000;
}

function getAnotherWindowsOnSameScreen(window, offset, isCycle) {
  var windows = window.others({ visible: true, screen: window.screen() });
  windows.push(window);
  var screen = window.screen();
  windows = _.chain(windows).sortBy(function (window) {
    return [(A_BIG_PIXEL + window.frame().y - screen.flippedFrame().y) +
      (A_BIG_PIXEL + window.frame().x - screen.flippedFrame().y),
      window.app().pid, window.title()].join('');
  }).value();
  if (isCycle) {
    var index = (_.indexOf(windows, window) + offset + windows.length) % windows.length;
  } else {
    var index = _.indexOf(windows, window) + offset;
  }
  if (index >= windows.length || index < 0) {
    return;
  }
  return windows[index];
}

function getPreviousWindowsOnSameScreen(window) {
  return getAnotherWindowsOnSameScreen(window, -1, true)
};

function getNextWindowsOnSameScreen(window) {
  return getAnotherWindowsOnSameScreen(window, 1, true)
};

function setWindowCentral(window) {
  window.setTopLeft({
    x: (window.screen().flippedFrame().width - window.size().width) / 2 + window.screen().flippedFrame().x,
    y: (window.screen().flippedFrame().height - window.size().height) / 2 + window.screen().flippedFrame().y
  });
};


// Next Window in One Screen
function next_window_in_one_screen() {
  var window = Window.focused();
  if (!window) {
    if (Window.recent().length == 0) return;
    Window.recent()[0].focus();
    return;
  }
  save_mouse_position_for_window(window);
  var targetWindow = getNextWindowsOnSameScreen(window);  // <- most time cost
  if (!targetWindow) {
    return;
  }
  targetWindow.focus();
  restore_mouse_position_for_window(targetWindow);
}

// Previous Window in One Screen
function previous_window_in_one_screen() {
  var window = Window.focused();
  if (!window) {
    if (Window.recent().length == 0) return;
    Window.recent()[0].focus();
    return;
  }
  save_mouse_position_for_window(window);
  var targetWindow = getPreviousWindowsOnSameScreen(window);
  if (!targetWindow) {
    return;
  }
  targetWindow.focus();
  restore_mouse_position_for_window(targetWindow);
}

// Window Central
function window_central() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  setWindowCentral(window);
}

// Window Half Buttom
function halfButtom() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }

  var fvf = window.screen().flippedVisibleFrame()
  var of = window.frame()

  // set size
  window.setSize({ width: of.width, height: fvf.height / 2 - 1 })

  // set point
  window.setTopLeft({ x: of.x, y: fvf.y + fvf.height / 2 + 1 })
}

// Window Half Top
function halfTop() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var fvf = window.screen().flippedVisibleFrame()
  var of = window.frame()

  window.setTopLeft({ x: of.x, y: fvf.y })
  window.setSize({ width: of.width, height: fvf.height / 2 - 1 })
}

// Window half right
function halfRight() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var fvf = window.screen().flippedVisibleFrame()
  var of = window.frame()

  // set size
  window.setSize({ width: fvf.width / 2 - 1, height: of.height })

  // set point
  window.setTopLeft({ x: fvf.x + fvf.width / 2 + 1, y: of.y })
}

function halfLeft() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var fvf = window.screen().flippedVisibleFrame()
  var of = window.frame()

  // set size
  window.setSize({ width: fvf.width / 2 - 1, height: of.height })

  // set point
  window.setTopLeft({ x: fvf.x, y: of.y })
}

// Window Maximize
function fullscreen() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }

  window.maximize();
}

// Window Smaller
function windowSmaller() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var oldFrame = window.frame();
  var frame = getSmallerFrame(oldFrame);
  window.setFrame(frame);
  if (window.frame().width == oldFrame.width || window.frame().height == oldFrame.height) {
    window.setFrame(oldFrame);
  }
}

// Window Larger
function windowLarger() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var frame = getLargerFrame(window.frame());
  if (frame.width > window.screen().flippedFrame().width ||
    frame.height > window.screen().flippedFrame().height) {
    window.maximize();
  } else {
    window.setFrame(frame);
  }
  //heartbeat_window(window);
}

function focusAnotherScreen(window, targetScreen) {
  if (!window) return;
  var currentScreen = window.screen();
  if (window.screen() === targetScreen) return;
  save_mouse_position_for_window(window);
  var targetScreenWindows = sortByMostRecent(targetScreen.windows());
  if (targetScreenWindows.length == 0) {
    return;
  }
  var targetWindow = targetScreenWindows[0]
  targetWindow.focus();  // bug, two window in two space, focus will focus in same space first
  restore_mouse_position_for_window(targetWindow);
}
// Previous Screen
function previous_screen() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var allScreens = Screen.all();
  var currentScreen = window.screen();
  if (currentScreen === undefined) {
    return; // TODO use mouse to find current screen
  }
  var targetScreen = currentScreen.previous();
  if (_.indexOf(_.map(allScreens, function (x) { return x.hash(); }), targetScreen.hash())
    <= _.indexOf(_.map(allScreens, function (x) { return x.hash(); }), currentScreen.hash())) {
    log("no more screen")
    return;
  }
  focusAnotherScreen(window, targetScreen);
}

// Next screen
function next_screen() {
  var window = getCurrentWindow();
  if (window === undefined) {
    return;
  }
  var allScreens = Screen.all();
  var currentScreen = window.screen();
  if (currentScreen === undefined) {
    return; // TODO use mouse to find current screen
  }
  var targetScreen = currentScreen.next();
  if (_.indexOf(_.map(allScreens, function (x) { return x.hash(); }), targetScreen.hash())
    >= _.indexOf(_.map(allScreens, function (x) { return x.hash(); }), currentScreen.hash())) {
    log("no more screen")
    return;
  }
  focusAnotherScreen(window, targetScreen);
}

// Move current window to next Space
function moveCurrentWindowToNextSpace() {
  var win = getCurrentWindow();
  if (win === undefined) return;
  var screen = win.screen()
  var cs = screen.currentSpace()
  var css = screen.spaces()

  var has = _.map(css, function(it) {return it.hash()})
  var idx = _.indexOf(has, cs.hash()) + 1
  if (idx === css.length) {
    idx = 0
  }

  var ts = css[idx]
  cs.removeWindows([win])
  ts.addWindows([win])
  win.focus()
}

function moveCurrentWindowToPrewSpace() {
  var win = getCurrentWindow();
  if (win === undefined) return;
  var screen = win.screen()
  var cs = screen.currentSpace()
  var css = screen.spaces()

  var has = _.map(css, function(it) {return it.hash()})
  var idx = _.indexOf(has, cs.hash()) - 1
  if (idx === -1) {
    idx = css.length -1
  }

  var ts = css[idx]
  cs.removeWindows([win])
  ts.addWindows([win])
  win.focus()
}

// Move Current Window to Next Screen
function move_current_window_to_next_screen() {
   var window = getCurrentWindow();
   if (window === undefined) {
      return;
   }
   if (window.screen() === window.screen().next()) return;
   if (window.screen().next().flippedFrame().x < 0) {
      return;
   }
   moveToScreen(window, window.screen().next());
   restore_mouse_position_for_window(window);
   window.focus();
}
// Move Current Window to Previous Screen
function move_current_window_to_previous_screen() {
   var window = getCurrentWindow();
   if (window === undefined) {
      return;
   }
   if (window.screen() === window.screen().next()) return;
   if (window.screen().next().flippedFrame().x == 0) {
      return;
   }
   moveToScreen(window, window.screen().previous());
   restore_mouse_position_for_window(window);
   window.focus();

}
