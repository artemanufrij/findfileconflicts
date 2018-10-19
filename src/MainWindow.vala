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

namespace FindFileConflicts {
    public class MainWindow : Gtk.Window {
        Settings settings;
        Services.LibraryManager lb_manager;

        Gtk.HeaderBar headerbar;
        Gtk.Stack content;
        Gtk.Spinner spinner;
        Gtk.MenuButton app_menu;
        Gtk.Button open_dir_btn;
        Gtk.Button refresh_btn;
        Granite.Widgets.AlertView message;

        string ? dir = null;

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (
                () => {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
                    if (settings.use_dark_theme) {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
                    } else {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
                    }
                });

            lb_manager = Services.LibraryManager.instance;
            lb_manager.scan_started.connect (
                () => {
                    headerbar.title = "Find File Conflicts";
                    message.icon_name = "search";
                    message.title = _ ("Scaning for conflict files…");
                    content.visible_child_name = "message";
                    spinner.active = true;
                    open_dir_btn.sensitive = false;
                    refresh_btn.hide ();
                });
            lb_manager.files_found.connect (
                (count) => {
                    message.description = _ ("%s (%u files found)").printf (dir, count);
                });
            lb_manager.files_checked.connect (
                (count, total) => {
                    message.description = _("Checked %u files of %u").printf (count, total);
                });

            lb_manager.scan_finished.connect (
                () => {
                    spinner.active = false;
                    open_dir_btn.sensitive = true;
                    refresh_btn.show ();
                });
            lb_manager.check_for_conflicts_begin.connect (
                () => {
                    spinner.active = true;
                    open_dir_btn.sensitive = false;
                    refresh_btn.hide ();
                });
            lb_manager.check_for_conflicts_finished.connect (
                () => {
                    Idle.add (
                        () => {
                            spinner.active = false;
                            open_dir_btn.sensitive = true;
                            refresh_btn.show ();

                            if (content.visible_child_name == "message") {
                                message.title = _ ("No conflict files found");
                                message.icon_name = "dialog-information";
                            }

                            return false;
                        });
                });
            lb_manager.conflict_found.connect (
                () => {
                    content.visible_child_name = "conflicts";
                });
        }

        public MainWindow () {
            load_settings ();
            build_ui ();
            this.delete_event.connect (
                () => {
                    save_settings ();
                    return false;
                });
            Utils.set_custom_css_style (this.get_screen ());
        }

        private void build_ui () {
            headerbar = new Gtk.HeaderBar ();
            headerbar.title = "Find File Conflicts";
            headerbar.show_close_button = true;
            headerbar.get_style_context ().add_class ("default-decoration");
            this.set_titlebar (headerbar);

            open_dir_btn = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            open_dir_btn.tooltip_text = _ ("Open Folder");
            open_dir_btn.clicked.connect (open_dir_action);
            headerbar.pack_start (open_dir_btn);

            // SETTINGS MENU
            app_menu = new Gtk.MenuButton ();
            app_menu.valign = Gtk.Align.CENTER;
            if (settings.use_dark_theme) {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            }

            var settings_menu = new Gtk.Menu ();

            var menu_item_preferences = new Gtk.MenuItem.with_label (_ ("Preferences"));
            menu_item_preferences.activate.connect (
                () => {
                    var preferences = new Dialogs.Preferences (this);
                    preferences.run ();
                });
            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            // REFRESH
            refresh_btn = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            refresh_btn.tooltip_text = _ ("Rescan");
            refresh_btn.clicked.connect (
                () => {
                    rescan ();
                });
            headerbar.pack_end (refresh_btn);

            // SPINNER
            spinner = new Gtk.Spinner ();
            headerbar.pack_end (spinner);

            var welcome = new Widgets.Views.Welcome ();
            welcome.open_dir_clicked.connect (open_dir_action);

            var conflicts = new Widgets.Views.Conflicts ();
            conflicts.solved.connect (
                () => {
                    content.visible_child_name = "message";
                    message.title = _ ("All conflicts solved");
                    message.icon_name = "dialog-information";
                    headerbar.title = "Find File Conflicts";
                });

            conflicts.items_changed.connect (
                (count) => {
                    headerbar.title = _ ("%u conflicts found").printf (count);
                });

            message = new Granite.Widgets.AlertView ("", "", "search");

            content = new Gtk.Stack ();
            content.add_named (welcome, "welcome");
            content.add_named (conflicts, "conflicts");
            content.add_named (message, "message");
            this.add (content);
            this.show_all ();
            refresh_btn.hide ();
        }

        private void open_dir_action () {
            dir = Utils.choose_folder ();
                    rescan ();
        }

        public void rescan () {
            if (dir != null) {
                lb_manager.scan_folder.begin (dir);
            }
        }

        private void load_settings () {
            this.set_default_size (settings.window_width, settings.window_height);

            if (settings.window_x < 0 || settings.window_y < 0 ) {
                this.window_position = Gtk.WindowPosition.CENTER;
            } else {
                this.move (settings.window_x, settings.window_y);
            }

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
        }

        private void save_settings () {
            int x, y;
            this.get_position (out x, out y);
            settings.window_x = x;
            settings.window_y = y;

            int width, height;
            this.get_size (out width, out height);
            settings.window_height = height;
            settings.window_width = width;
        }
    }
}
