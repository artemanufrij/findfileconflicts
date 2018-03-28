/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace FindFileConflicts.Widgets {
    public class LocalFile : Gtk.Grid {
        public signal void removed ();

        Objects.LocalFile file { get; private set; }

        public LocalFile (Objects.LocalFile file) {
            this.file = file;
            build_ui ();
        }

        private void build_ui () {
            var event_box = new Gtk.EventBox ();

            var content = new Gtk.Grid ();
            content.margin = 6;
            content.column_spacing = 6;

            var trash_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.BUTTON);
            trash_button.get_style_context ().remove_class ("button");
            trash_button.opacity = 0;
            trash_button.enter_notify_event.connect (
                () => {
                    trash_button.opacity = 1;
                    return false;
                });
            trash_button.clicked.connect (
                () => {
                    try {
                        if (file.file.trash ()) {
                            removed ();
                        }
                    } catch (Error err) {
                        warning (err.message);
                    }
                });

            event_box.enter_notify_event.connect (
                () => {
                    trash_button.opacity = 1;
                    return false;
                });

            event_box.leave_notify_event.connect (
                () => {
                    trash_button.opacity = 0;
                    return false;
                });

            var label = new Gtk.Label (file.title);
            label.xalign = 0;
            label.hexpand = true;
            var date = new Gtk.Label (file.date);

            content.add (trash_button);
            content.add (label);
            content.add (date);

            event_box.add (content);

            this.add (event_box);
        }
    }
}