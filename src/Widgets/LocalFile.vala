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

        Objects.LocalFile file { get; private set; }

        public LocalFile (Objects.LocalFile file, bool show_separator = true) {
            this.file = file;
            build_ui (show_separator);
        }

        private void build_ui (bool show_separator) {
            var content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            Gtk.Button command_button;
            if (file.conflict_type == Objects.ConflictType.SIMILAR) {
                this.tooltip_text = _ ("Similar Files");
                command_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.BUTTON);
                command_button.tooltip_text = _ ("Move into Trash");
                command_button.clicked.connect (
                    () => {
                        try {
                            if (file.file.trash ()) {
                                removed ();
                            }
                        } catch (Error err) {
                            warning (err.message);
                        }
                    });
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

                command_button = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
                command_button.tooltip_text = _ ("Open Location");
                command_button.clicked.connect (
                    () => {
                        try {
                            Process.spawn_command_line_async ("xdg-open '%s'".printf (file.file.get_parent ().get_path ()));
                        } catch (Error err) {
                            warning (err.message);
                        }
                    });
            }

            command_button.get_style_context ().remove_class ("button");
            command_button.opacity = 0;
            command_button.margin = 6;
            command_button.enter_notify_event.connect (
                () => {
                    command_button.opacity = 1;
                    return false;
                });

            this.enter_notify_event.connect (
                () => {
                    command_button.opacity = 1;
                    return false;
                });

            this.leave_notify_event.connect (
                () => {
                    command_button.opacity = 0;
                    return false;
                });

            Gtk.Image image;
            try {
                FileInfo info = file.file.query_info ("standard::icon", 0);
                Icon icon = info.get_icon ();
                image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.BUTTON);
            } catch (Error err) {
                            warning (err.message);
                image = new Gtk.Image.from_icon_name ("default", Gtk.IconSize.BUTTON);
            }
            image.margin_end = 6;

            var label = new Gtk.Label (file.title);
            label.xalign = 0;

            var date = new Gtk.Label (file.date);
            date.margin = 6;

            content.pack_start (command_button, false, false);
            content.pack_start (image, false, false);
            content.pack_start (label, false, false);
            if (show_separator) {
                content.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL), false, true);
            }
            content.pack_end (date, false, false);

            this.add (content);
        }
    }
}