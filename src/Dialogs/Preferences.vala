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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
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

namespace FindFileConflicts.Dialogs {
    public class Preferences : Gtk.Dialog {
        Settings settings;

        construct {
            settings = Settings.get_default ();
        }

        public Preferences (Gtk.Window parent) {
            Object (transient_for: parent, deletable: false, resizable: false);
            build_ui ();
        }

        private void build_ui () {
            var content = this.get_content_area () as Gtk.Box;
            content.add (build_rules_grid ());

            var close_button = new Gtk.Button.with_label (_ ("Close"));
            close_button.clicked.connect (() => { this.destroy (); });

            Gtk.Box actions = this.get_action_area () as Gtk.Box;
            actions.add (close_button);

            this.show_all ();
        }

        private Gtk.Grid build_rules_grid () {
            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 12;
            grid.margin = 12;

            var use_rule_similar = new Gtk.Switch ();
            use_rule_similar.active = settings.use_rule_similar;
            use_rule_similar.notify["active"].connect (() => {
                settings.use_rule_similar = use_rule_similar.active;
            });

            var use_rule_length = new Gtk.Switch ();
            use_rule_length.active = settings.use_rule_length;
            use_rule_length.notify["active"].connect (() => {
                settings.use_rule_length = use_rule_length.active;
            });

            var use_rule_chars = new Gtk.Switch ();
            use_rule_chars.active = settings.use_rule_chars;
            use_rule_chars.notify["active"].connect (() => {
                settings.use_rule_chars = use_rule_chars.active;
            });

            var use_rule_dots = new Gtk.Switch ();
            use_rule_dots.active = settings.use_rule_dots;
            use_rule_dots.notify["active"].connect (() => {
                settings.use_rule_dots = use_rule_dots.active;
            });

            /*var use_rule_duplicates = new Gtk.Switch ();
            use_rule_duplicates.active = settings.use_rule_duplicates;
            use_rule_duplicates.notify["active"].connect (
                () => {
                    settings.use_rule_duplicates = use_rule_duplicates.active;
                });*/

            grid.attach (label_generator (_ ("Similar File Name")), 0, 0);
            grid.attach (use_rule_similar, 1, 0);
            grid.attach (label_generator (_ ("Too Long File Name")), 0, 1);
            grid.attach (use_rule_length, 1, 1);
            grid.attach (label_generator (_ ("Illegal Chars")), 0, 2);
            grid.attach (use_rule_chars, 1, 2);
            grid.attach (label_generator (_ ("Double Dots")), 0, 3);
            grid.attach (use_rule_dots, 1, 3);
            //grid.attach (label_generator (_ ("Check for Duplicates")), 0, 4);
            //grid.attach (use_rule_duplicates, 1, 4);

            return grid;
        }

        private Gtk.Label label_generator (string content) {
            return new Gtk.Label (content) {
                halign = Gtk.Align.START,
                hexpand = true
            };
        }
    }
}