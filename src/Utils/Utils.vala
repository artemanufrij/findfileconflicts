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

namespace FindFileConflicts.Utils {
    public static string ? choose_folder () {
        string ? return_value = null;
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            _ ("Select a folder."), FindFileConflictsApp.instance.mainwindow, Gtk.FileChooserAction.SELECT_FOLDER,
            _ ("_Cancel"), Gtk.ResponseType.CANCEL,
            _ ("_Open"), Gtk.ResponseType.ACCEPT);

        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_ ("Folder"));
        filter.add_mime_type ("inode/directory");

        chooser.add_filter (filter);

        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            return_value = chooser.get_file ().get_path ();
        }

        chooser.destroy ();
        return return_value;
    }
}