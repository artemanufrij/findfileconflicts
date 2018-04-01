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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

namespace FindFileConflicts.Services {
    public class LibraryManager : GLib.Object {
        Settings settings;
        Services.LocalFilesManager lf_manager;

        static LibraryManager _instance = null;
        public static LibraryManager instance {
            get {
                if (_instance == null) {
                    _instance = new LibraryManager ();
                }
                return _instance;
            }
        }

        public signal void scan_started ();
        public signal void scan_finished ();
        public signal void check_for_conflicts_begin ();
        public signal void check_for_conflicts_finished ();
        public signal void conflict_found (Objects.LocalFile file1, Objects.LocalFile ? file2);

        string root = "";
        uint finish_timer = 0;
        GLib.List<Objects.LocalFile> files = null;

        construct {
            settings = Settings.get_default ();

            lf_manager = Services.LocalFilesManager.instance;
            lf_manager.found_file.connect (found_local_file);
            lf_manager.scan_started.connect (() => { scan_started (); });

            scan_finished.connect_after (
                () => {
                    check_for_conflicts.begin ();
                });
        }

        private LibraryManager () {
        }

        public async void scan_folder (string path) {
            files = new GLib.List<Objects.LocalFile> ();
            root = path;
            lf_manager.scan (path);
            call_finish_timer ();
        }

        public void found_local_file (string path) {
            call_finish_timer ();
            var file = new Objects.LocalFile (path, root);
            lock (files) {
                files.append (file);
            }
        }

        private void call_finish_timer () {
            lock (finish_timer) {
                if (finish_timer > 0) {
                    Source.remove (finish_timer);
                    finish_timer = 0;
                }

                finish_timer = Timeout.add (
                    500,
                    () => {
                        if (finish_timer > 0) {
                            Source.remove (finish_timer);
                            finish_timer = 0;
                        }
                        scan_finished ();
                        return false;
                    });
            }
        }

        private async void check_for_conflicts () {
            check_for_conflicts_begin ();
            new Thread<void*> (
                "check_for_conflicts",
                () => {
                    files.sort (
                        (a, b) => {
                            return a.path_down.collate (b.path_down);
                        });
                    for (var i = 0; i < files.length (); i++) {
                        var file1 = files.nth_data (i);
                        if (file1.has_conflict) {
                            continue;
                        }

                        // CHECK FOR TO LONG FILENAME
                        if (settings.use_rule_length) {
                            var basename = Path.get_basename (file1.path);
                            if (basename.length >= 360) {
                                file1.has_conflict = true;
                                file1.conflict_type = Objects.ConflictType.LENGTH;
                                    conflict_found (file1, null);
                                continue;
                            }
                        }

                        // CHECK FOR ILLEGAL CHARS
                        if (settings.use_rule_chars) {
                            if (file1.title.index_of (":") > -1
                                || file1.title.has_suffix (" ")) {
                                file1.has_conflict = true;
                                file1.conflict_type = Objects.ConflictType.CHARS;
                                    conflict_found (file1, null);
                                continue;
                            }
                        }

                        if (settings.use_rule_dots) {
                            if (file1.title.index_of ("..") > -1) {
                                file1.has_conflict = true;
                                file1.conflict_type = Objects.ConflictType.DOTS;
                                    conflict_found (file1, null);
                                continue;
                            }
                        }

                        // CHECK FOR SIMILAR FILE NAME
                        if (settings.use_rule_similar && files.length () > i + 1) {
                            var file2 = files.nth_data (i + 1);
                            if (file1.path_down == file2.path_down) {
                                file1.has_conflict = true;
                                file2.has_conflict = true;

                                file1.exclude_date ();
                                file2.exclude_date ();

                                file1.conflict_type = Objects.ConflictType.SIMILAR;
                                file2.conflict_type = Objects.ConflictType.SIMILAR;

                                if (file1.modified < file2.modified) {
                                    conflict_found (file1, file2);
                                } else {
                                    conflict_found (file2, file1);
                                }
                            }
                        }
                    }

                    check_for_conflicts_finished ();
                    return null;
                });
        }
    }
}
