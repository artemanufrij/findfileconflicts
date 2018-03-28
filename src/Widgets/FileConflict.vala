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
    public class FileConflict : Gtk.ListBoxRow {
        public signal void solved ();

        public Objects.LocalFile file1 { get; private set; }
        public Objects.LocalFile file2 { get; private set; }

        public FileConflict (Objects.LocalFile file1, Objects.LocalFile file2) {
            this.file1 = file1;
            this.file2 = file2;

            build_ui ();
        }

        private void build_ui () {
            var content = new Gtk.Grid ();
            content.column_spacing = 6;

            var file1_widget = new Widgets.LocalFile (file1);
            file1_widget.removed.connect (
                () => {
                    solved ();
                });
            file1_widget.expand = true;
            var file2_widget = new Widgets.LocalFile (file2);
            file2_widget.removed.connect (
                () => {
                    solved ();
                });
            file2_widget.expand = true;

            content.attach (file1_widget, 0, 0);
            content.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0);
            content.attach (file2_widget, 2, 0);

            this.add (content);
            this.show_all ();
        }
    }
}