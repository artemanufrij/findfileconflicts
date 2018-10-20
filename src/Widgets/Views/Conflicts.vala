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

namespace FindFileConflicts.Widgets.Views {
    public class Conflicts : Gtk.Grid {
        Services.LibraryManager lb_manager;
        Settings settings;

        public signal void solved ();
        public signal void items_changed (uint count);

        Gtk.ListBox conflicts;

        uint timer_sort = 0;

        construct {
            settings = Settings.get_default ();
            settings.notify["sort-column"].connect (() => {
                    do_sort ();
                });
            settings.notify["sort-asc"].connect (() => {
                    do_sort ();
                });

            lb_manager = Services.LibraryManager.instance;
            lb_manager.conflict_found.connect (
                (file1, file2) => {
                    Idle.add (
                        () => {
                            add_conflict (file1, file2);
                            return false;
                        });
                });
            lb_manager.scan_started.connect (reset);
        }

        public Conflicts () {
            build_ui ();
        }

        private void build_ui () {
            conflicts = new Gtk.ListBox ();

            var scroll = new Gtk.ScrolledWindow (null, null);
            scroll.expand = true;
            scroll.add (conflicts);

            this.add (scroll);
            this.show_all ();
        }

        private void add_conflict (Objects.LocalFile file1, Objects.LocalFile ? file2) {
            if (file2 != null) {
                var conflict = new Widgets.FilesConflict (file1, file2);
                conflicts.add (conflict);
                conflict.solved.connect (
                    () => {
                        conflict.destroy ();
                        var count = conflicts.get_children ().length ();
                        items_changed (count);
                        if (count == 0) {
                            solved ();
                        }
                    });
            } else {
                var conflict = new Widgets.IllegalFile (file1);
                conflicts.add (conflict);
            }
            items_changed (conflicts.get_children ().length ());
            do_sort ();
        }

        private void reset () {
            foreach (var item in conflicts.get_children ()) {
                item.destroy ();
            }
        }

        private void do_sort () {
            lock (timer_sort) {
                if (timer_sort != 0) {
                    Source.remove (timer_sort);
                    timer_sort = 0;
                }

                timer_sort = Timeout.add (100, () => {
                    conflicts.set_sort_func (sort_func);
                    conflicts.set_sort_func (null);
                    Source.remove (timer_sort);
                    timer_sort = 0;
                    return false;
                });
            }
        }

        private int sort_func (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
            var file1 = (child1 as Interfaces.IConflict).file1;
            var file2 = (child2 as Interfaces.IConflict).file1;

            switch (settings.sort_column) {
                case "name":
                    return file1.path_down.collate (file2.path_down) * (settings.sort_asc == true ? 1: -1);
                case "date":
                    return (int)(file1.modified - file2.modified) * (settings.sort_asc == true ? 1: -1);
            }

            return 0;
        }
    }
}