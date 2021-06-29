#!/usr/bin/env python2
# Terminator by Chris Jones <cmsj@tenshu.net>
# GPL v2 only
"""searchbar.py - classes necessary to provide a terminal search bar"""

from gi.repository import Gtk, Gdk
from gi.repository import GObject
import re

from .translation import _
from .config import Config

# pylint: disable-msg=R0904
class Searchbar(Gtk.HBox):
    """Class implementing the Searchbar widget"""

    __gsignals__ = {
        'end-search': (GObject.SignalFlags.RUN_LAST, None, ()),
    }

    entry = None
    reslabel = None
    next = None
    prev = None
    wrap = None

    vte = None
    config = None

    searchstring = None
    searchre = None
    searchrow = None

    searchits = None

    def __init__(self):
        """Class initialiser"""
        GObject.GObject.__init__(self)

        self.config = Config()

        self.get_style_context().add_class("terminator-terminal-searchbar")

        # Search text
        self.entry = Gtk.Entry()
        self.entry.set_activates_default(True)
        self.entry.show()
        self.entry.connect('activate', self.do_search)
        self.entry.connect('key-press-event', self.search_keypress)

        # Label
        label = Gtk.Label(label=_('Search:'))
        label.show()

        # Result label
        self.reslabel = Gtk.Label(label='')
        self.reslabel.show()

        # Close Button
        close = Gtk.Button()
        close.set_relief(Gtk.ReliefStyle.NONE)
        close.set_focus_on_click(False)
        icon = Gtk.Image()
        icon.set_from_stock(Gtk.STOCK_CLOSE, Gtk.IconSize.MENU)
        close.add(icon)
        close.set_name('terminator-search-close-button')
        if hasattr(close, 'set_tooltip_text'):
            close.set_tooltip_text(_('Close Search bar'))
        close.connect('clicked', self.end_search)
        close.show_all()

        # Next Button
        self.next = Gtk.Button(_('Next'))
        self.next.show()
        self.next.set_sensitive(False)
        self.next.connect('clicked', self.next_search)

        # Previous Button
        self.prev = Gtk.Button(_('Prev'))
        self.prev.show()
        self.prev.set_sensitive(False)
        self.prev.connect('clicked', self.prev_search)

        # Wrap checkbox
        self.wrap = Gtk.CheckButton(_('Wrap'))
        self.wrap.show()
        self.wrap.set_sensitive(True)
        self.wrap.connect('toggled', self.wrap_toggled)

        self.pack_start(label, False, True, 0)
        self.pack_start(self.entry, True, True, 0)
        self.pack_start(self.reslabel, False, True, 0)
        self.pack_start(self.prev, False, False, 0)
        self.pack_start(self.next, False, False, 0)
        self.pack_start(self.wrap, False, False, 0)
        self.pack_end(close, False, False, 0)

        self.hide()
        self.set_no_show_all(True)

    def wrap_toggled(self, toggled):
        if self.searchrow is None:
            self.prev.set_sensitive(False)
            self.next.set_sensitive(False)
        elif toggled:
            self.prev.set_sensitive(True)
            self.next.set_sensitive(True)

    def get_vte(self):
        """Find our parent widget"""
        parent = self.get_parent()
        if parent:
            self.vte = parent.vte

    # pylint: disable-msg=W0613
    def search_keypress(self, widget, event):
        """Handle keypress events"""
        key = Gdk.keyval_name(event.keyval)
        if key == 'Escape':
            self.end_search()
        else:
            self.prev.set_sensitive(False)
            self.next.set_sensitive(False)

    def start_search(self):
        """Show ourselves"""
        if not self.vte:
            self.get_vte()

        self.show()
        self.entry.grab_focus()

    def do_search(self, widget):
        """Trap and re-emit the clicked signal"""
        searchtext = self.entry.get_text()
        if searchtext == '':
            return

        if searchtext != self.searchstring:
            self.searchrow = self.get_vte_buffer_range()[0] - 1
            self.searchstring = searchtext
            self.searchre = re.compile(searchtext)

        self.reslabel.set_text(_("Searching scrollback"))
        self.next.set_sensitive(True)
        self.prev.set_sensitive(True)
        self.next_search(None)

    def next_search(self, widget):
        """Search forwards and jump to the next result, if any"""
        startrow,endrow = self.get_vte_buffer_range()
        found = startrow <= self.searchrow and self.searchrow < endrow
        row = self.searchrow
        while True:
            row += 1
            if row >= endrow:
                if found and self.wrap.get_active():
                    row = startrow - 1
                else:
                    self.prev.set_sensitive(found)
                    self.next.set_sensitive(False)
                    self.reslabel.set_text(_('No more results'))
                    return
            buffer = self.vte.get_text_range(row, 0, row + 1, 0, self.search_character)

            buffer = buffer[0]
            buffer = buffer[:buffer.find('\n')]
            matches = self.searchre.search(buffer)
            if matches:
                self.searchrow = row
                self.prev.set_sensitive(True)
                self.search_hit(self.searchrow)
                return

    def prev_search(self, widget):
        """Jump back to the previous search"""
        startrow,endrow = self.get_vte_buffer_range()
        found = startrow <= self.searchrow and self.searchrow < endrow
        row = self.searchrow
        while True:
            row -= 1
            if row <= startrow:
                if found and self.wrap.get_active():
                    row = endrow
                else:
                    self.next.set_sensitive(found)
                    self.prev.set_sensitive(False)
                    self.reslabel.set_text(_('No more results'))
                    return
            buffer = self.vte.get_text_range(row, 0, row + 1, 0, self.search_character)

            buffer = buffer[0]
            buffer = buffer[:buffer.find('\n')]
            matches = self.searchre.search(buffer)
            if matches:
                self.searchrow = row
                self.next.set_sensitive(True)
                self.search_hit(self.searchrow)
                return

    def search_hit(self, row):
        """Update the UI for a search hit"""
        self.reslabel.set_text("%s %d" % (_('Found at row'), row))
        self.get_parent().scrollbar_jump(row)
        self.next.show()
        self.prev.show()

    def search_character(self, widget, col, row):
        """We have to have a callback for each character"""
        return(True)

    def get_vte_buffer_range(self):
        """Get the range of a vte widget"""
        column, endrow = self.vte.get_cursor_position()
        if self.config['scrollback_infinite']:
            startrow = 0
        else:
            startrow = max(0, endrow - self.config['scrollback_lines'])
        return(startrow, endrow)

    def end_search(self, widget=None):
        """Trap and re-emit the end-search signal"""
        self.searchrow = 0
        self.searchstring = None
        self.searchre = None
        self.reslabel.set_text('')
        self.emit('end-search')

    def get_search_term(self):
        """Return the currently set search term"""
        return(self.entry.get_text())

GObject.type_register(Searchbar)
