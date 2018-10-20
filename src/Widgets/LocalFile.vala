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
    public class LocalFile : Gtk.EventBox {
        public signal void removed ();

        Gtk.Box content;
        Gtk.Grid controls;
        Objects.LocalFile file { get; private set; }

        public LocalFile (Objects.LocalFile file, bool show_separator = true) {
            this.file = file;
            build_ui (show_separator);
        }

        private void build_ui (bool show_separator) {
            content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            if (file.conflict_type == Objects.ConflictType.SIMILAR) {
                this.tooltip_text = _ ("Similar Files");

            } else {
                switch (file.conflict_type) {
                    case Objects.ConflictType.CHARS :
                        this.tooltip_text = _ ("Filename contains illegal chars");
                        break;
                    case Objects.ConflictType.LENGTH :
                        this.tooltip_text = _ ("Filename is too long");
                        break;
                    case Objects.ConflictType.DOTS :
                        this.tooltip_text = _ ("Filename contains double dots '..'");
                        break;
                }
            }

            this.enter_notify_event.connect (
                () => {
                    controls.opacity = 0.75;
                    return false;
                });

            this.leave_notify_event.connect (
                () => {
                    controls.opacity = 0;
                    return false;
                });

            Gtk.Image image;
            try {
                FileInfo info = file.file.query_info ("standard::icon", 0);
                Icon icon = info.get_icon ();
                image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.LARGE_TOOLBAR);
            } catch (Error err) {
                warning (err.message);
                image = new Gtk.Image.from_icon_name ("default", Gtk.IconSize.LARGE_TOOLBAR);
            }
            image.margin_end = 6;

            var label = new Gtk.Label (file.title);
            label.xalign = 0;

            var date = new Gtk.Label (file.date);
            date.margin = 6;

            build_controls_ui ();
            //content.pack_start (command_button, false, false);
            content.pack_start (image, false, false);
            content.pack_start (label, false, false);
            if (show_separator) {
                content.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL), false, true);
            }
            content.pack_end (date, false, false);

            this.add (content);
        }

        private void build_controls_ui () {
            controls = new Gtk.Grid ();
            controls.margin = 4;
            controls.opacity = 0;
            controls.row_spacing = 2;

            // OPEN LOCATION
            var command_open_location = new Gtk.EventBox ();
            command_open_location.enter_notify_event.connect (() => {
                controls.opacity = 0.75;
                return false;
            });
            command_open_location.button_release_event.connect (() => {
                try {
                    Process.spawn_command_line_async ("xdg-open '%s'".printf (file.file.get_parent ().get_path ()));
                } catch (Error err) {
                    warning (err.message);
                }
                return false;
            });
            var icon_open_location = new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
            icon_open_location.tooltip_text = _ ("Open Location");
            command_open_location.add (icon_open_location);

            // MOVE INTO TRASH
            var command_remove_file = new Gtk.EventBox ();
            command_remove_file.enter_notify_event.connect (() => {
                controls.opacity = 0.75;
                return false;
            });
            command_remove_file.button_release_event.connect (() => {
                try {
                    if (file.file.trash ()) {
                        removed ();
                    }
                } catch (Error err) {
                    warning (err.message);
                }
                return false;
            });

            var icon_remove_file = new Gtk.Image.from_icon_name ("user-trash-symbolic", Gtk.IconSize.BUTTON);
            icon_remove_file.tooltip_text = _ ("Move into Trash");
            command_remove_file.add (icon_remove_file);

            controls.attach (command_open_location, 0, 0);
            controls.attach (command_remove_file, 0, 1);

            content.pack_start (controls, false, false);
        }
    }
}