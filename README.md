# Menu-bar Whiteboard

Click the icon in the macOS menu bar, a whiteboard drops down. Draw, then save a PNG.

- Tools: pen, fountain pen, eraser, line, rectangle, ellipse, text
- Save writes a PNG to `~/Pictures/Whiteboard/` and copies it to the clipboard
- Drag the toolbar to move it, drag the bottom-right grip to resize, Esc or X to close
- Right-click the icon for Launch at Login and Quit

## Build

Needs Xcode command line tools.

```sh
./build.sh && open Whiteboard.app
```

`main.swift` is a small WKWebView shell. The UI is `whiteboard.html`.
