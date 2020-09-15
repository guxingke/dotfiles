/**
 * Mouse Functions
 */
var mousePositions = {};
function save_mouse_position_for_window(window) {
  if (!window) return;
  var pos = Mouse.location()
  mousePositions[window.hash()] = pos;
}

function set_mouse_position_for_window_center(window) {
  Mouse.move({
    x: window.topLeft().x + window.frame().width / 2,
    y: window.topLeft().y + window.frame().height / 2
  });
  heartbeat_window(window);
}

function restore_mouse_position_for_window(window) {
  if (!mousePositions[window.hash()]) {
    set_mouse_position_for_window_center(window);
    return;
  }
  var pos = mousePositions[window.hash()];
  var rect = window.frame();
  if (pos.x < rect.x || pos.x > (rect.x + rect.width) || pos.y < rect.y || pos.y > (rect.y + rect.height)) {
    set_mouse_position_for_window_center(window);
    return;
  }
  Mouse.move(pos);
}

/**
 * Mouse Functions
 */
// Central Mouse
function central_mouse() {
   var window = getCurrentWindow();
   if (window === undefined) {
      return;
   }
   set_mouse_position_for_window_center(window);
}


