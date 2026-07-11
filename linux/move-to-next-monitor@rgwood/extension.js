import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const KEY = 'move-to-next-monitor';

export default class MoveToNextMonitor extends Extension {
    enable() {
        Main.wm.addKeybinding(
            KEY,
            this.getSettings(),
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => {
                const window = global.display.get_focus_window();
                if (!window) return;
                const nMonitors = global.display.get_n_monitors();
                if (nMonitors < 2) return;
                const current = window.get_monitor();
                const next = (current + 1) % nMonitors;
                window.move_to_monitor(next);
            }
        );
    }

    disable() {
        Main.wm.removeKeybinding(KEY);
    }
}
