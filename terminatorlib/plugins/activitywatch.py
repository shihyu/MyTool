#!/usr/bin/env python2
# Terminator by Chris Jones <cmsj@tenshu.net>
# GPL v2 only
"""activitywatch.py - Terminator Plugin to watch a terminal for activity"""

import time
import gi
from gi.repository import Gtk
from gi.repository import GObject

from terminatorlib.config import Config
import terminatorlib.plugin as plugin
from terminatorlib.translation import _
from terminatorlib.util import err, dbg
from terminatorlib.version import APP_NAME

try:
    gi.require_version('Notify', '0.7')
    from gi.repository import Notify
    # Every plugin you want Terminator to load *must* be listed in 'AVAILABLE'
    # This is inside this try so we only make the plugin available if pynotify
    #  is present on this computer.
    AVAILABLE = ['ActivityWatch', 'InactivityWatch']
except (ImportError, ValueError):
    err('ActivityWatch plugin unavailable as we cannot import Notify')

config = Config()
inactive_period = float(config.plugin_get('InactivityWatch', 'inactive_period',
                                        10.0))
watch_interval = int(config.plugin_get('InactivityWatch', 'watch_interval',
                                       5000))
hush_period = float(config.plugin_get('ActivityWatch', 'hush_period',
                                        10.0))

class ActivityWatch(plugin.MenuItem):
    """Add custom commands to the terminal menu"""
    capabilities = ['terminal_menu']
    watches = None
    last_notifies = None
    timers = None

    def __init__(self):
        plugin.MenuItem.__init__(self)
        if not self.watches:
            self.watches = {}
        if not self.last_notifies:
            self.last_notifies = {}
        if not self.timers:
            self.timers = {}

        Notify.init(APP_NAME.capitalize())

    def callback(self, menuitems, menu, terminal):
        """Add our menu item to the menu"""
        item = Gtk.CheckMenuItem.new_with_mnemonic(_('Watch for _activity'))
        item.set_active(terminal in self.watches)
        if item.get_active():
            item.connect("activate", self.unwatch, terminal)
        else:
            item.connect("activate", self.watch, terminal)
        menuitems.append(item)
        dbg('Menu item appended')

    def watch(self, _widget, terminal):
        """Watch a terminal"""
        vte = terminal.get_vte()
        self.watches[terminal] = vte.connect('contents-changed', 
                                             self.notify, terminal)

    def unwatch(self, _widget, terminal):
        """Stop watching a terminal"""
        vte = terminal.get_vte()
        vte.disconnect(self.watches[terminal])
        del(self.watches[terminal])

    def notify(self, _vte, terminal):
        """Notify that a terminal did something"""
        show_notify = False

        # Don't notify if the user is already looking at this terminal.
        if terminal.vte.has_focus():
            return True

        note = Notify.Notification.new(_('Terminator'), _('Activity in: %s') % 
                                  terminal.get_window_title(), 'terminator')

        this_time = time.mktime(time.gmtime())
        if terminal not in self.last_notifies:
            show_notify = True
        else:
            last_time = self.last_notifies[terminal]
            if this_time - last_time > hush_period:
                show_notify = True

        if show_notify == True:
            note.show()
            self.last_notifies[terminal] = this_time

        return True

class InactivityWatch(plugin.MenuItem):
    """Add custom commands to notify when a terminal goes inactive"""
    capabilities = ['terminal_menu']
    watches = None
    last_activities = None
    timers = None

    def __init__(self):
        plugin.MenuItem.__init__(self)
        if not self.watches:
            self.watches = {}
        if not self.last_activities:
            self.last_activities = {}
        if not self.timers:
            self.timers = {}

        Notify.init(APP_NAME.capitalize())

    def callback(self, menuitems, menu, terminal):
        """Add our menu item to the menu"""
        item = Gtk.CheckMenuItem.new_with_mnemonic(_("Watch for _silence"))
        item.set_active(terminal in self.watches)
        if item.get_active():
            item.connect("activate", self.unwatch, terminal)
        else:
            item.connect("activate", self.watch, terminal)
        menuitems.append(item)
        dbg('Menu items appended')

    def watch(self, _widget, terminal):
        """Watch a terminal"""
        vte = terminal.get_vte()
        self.watches[terminal] = vte.connect('contents-changed',
                                             self.reset_timer, terminal)
        timeout_id = GObject.timeout_add(watch_interval, self.check_times, terminal)
        self.timers[terminal] = timeout_id
        dbg('timer %s added for %s' %(timeout_id, terminal))

    def unwatch(self, _vte, terminal):
        """Unwatch a terminal"""
        vte = terminal.get_vte()
        vte.disconnect(self.watches[terminal])
        del(self.watches[terminal])
        GObject.source_remove(self.timers[terminal])
        del(self.timers[terminal])

    def reset_timer(self, _vte, terminal):
        """Reset the last-changed time for a terminal"""
        time_now = time.mktime(time.gmtime())
        self.last_activities[terminal] = time_now
        dbg('reset activity time for %s' % terminal)

    def check_times(self, terminal):
        """Check if this terminal has gone silent"""
        time_now = time.mktime(time.gmtime())
        if terminal not in self.last_activities:
            dbg('Terminal %s has no last activity' % terminal)
            return True

        dbg('seconds since last activity: %f (%s)' % (time_now - self.last_activities[terminal], terminal))
        if time_now - self.last_activities[terminal] >= inactive_period:
            del(self.last_activities[terminal])
            note = Notify.Notification.new(_('Terminator'), _('Silence in: %s') % 
                                         terminal.get_window_title(), 'terminator')
            note.show()

        return True
