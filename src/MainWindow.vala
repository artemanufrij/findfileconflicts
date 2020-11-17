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
        Gtk.Image sort_name;
        Gtk.Image sort_date;
        Granite.Widgets.AlertView message;
        Granite.Widgets.ModeButton sort_mode;

        string ? dir = null;

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (() => {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
            });
            settings.notify["sort-column"].connect (() => {
                update_sort_icons ();
            });
            settings.notify["sort-asc"].connect (() => {
                update_sort_icons ();
            });

            lb_manager = Services.LibraryManager.instance;

            lb_manager.scan_started.connect (() => {
                headerbar.title = "Find File Conflicts";
                message.icon_name = "search";
                message.title = _ ("Scaning for conflict files…");
                content.visible_child_name = "message";
                spinner.active = true;
                open_dir_btn.sensitive = false;
                refresh_btn.hide ();
                sort_mode.hide ();
            });
            lb_manager.files_found.connect ((count) => {
                message.description = _ ("%s (%u files found)").printf (dir, count);
            });
            lb_manager.files_checked.connect ((count, total) => {
                message.description = _("Checked %u files of %u").printf (count, total);
            });
            lb_manager.scan_finished.connect (() => {
                spinner.active = false;
                open_dir_btn.sensitive = true;
                refresh_btn.show ();
            });
            lb_manager.check_for_conflicts_begin.connect (() => {
                spinner.active = true;
                open_dir_btn.sensitive = false;
                refresh_btn.hide ();
            });
            lb_manager.check_for_conflicts_finished.connect (() => {
                Idle.add (() => {
                    spinner.active = false;
                    open_dir_btn.sensitive = true;
                    refresh_btn.show ();

                    if (content.visible_child_name == "message") {
                        message.title = _ ("No conflict files found");
                        message.icon_name = "dialog-information";
                    }
                    update_sort_icons ();
                    return false;
                });
            });
            lb_manager.conflict_found.connect (() => {
                sort_mode.show ();
                content.visible_child_name = "conflicts";
            });
        }

        public MainWindow () {
            load_settings ();
            build_ui ();
            this.delete_event.connect (() => {
                save_settings ();
                return false;
            });
        }

        private void build_ui () {
            headerbar = new Gtk.HeaderBar ();
            headerbar.title = _("Find File Conflicts");
            headerbar.show_close_button = true;
            this.set_titlebar (headerbar);

            header_build_open_button ();

            header_build_sort_buttons ();

            header_build_refresh_button ();

            header_build_app_menu ();

            header_build_style_switcher ();

            // SPINNER
            spinner = new Gtk.Spinner ();
            spinner.tooltip_text = _("Loading…");
            headerbar.pack_end (spinner);

            // WELCOME
            var welcome = new Widgets.Views.Welcome ();
            welcome.open_dir_clicked.connect (open_dir_action);

            var conflicts = new Widgets.Views.Conflicts ();
            conflicts.solved.connect (() => {
                content.visible_child_name = "message";
                message.title = _ ("All conflicts solved");
                message.icon_name = "dialog-information";
                headerbar.title = "Find File Conflicts";
                sort_mode.hide ();
            });

            conflicts.items_changed.connect ((count) => {
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
            sort_mode.hide ();
        }

        private void header_build_open_button () {
            open_dir_btn = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            open_dir_btn.tooltip_text = _ ("Open Folder");
            open_dir_btn.clicked.connect (open_dir_action);
            headerbar.pack_start (open_dir_btn);
        }

        private void header_build_refresh_button () {
            refresh_btn = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            refresh_btn.tooltip_text = _ ("Rescan");
            refresh_btn.clicked.connect (() => {
                rescan ();
            });
            headerbar.pack_start (refresh_btn);
        }

        private void header_build_sort_buttons () {
            sort_mode = new Granite.Widgets.ModeButton ();
            sort_mode.valign = Gtk.Align.CENTER;

            sort_name = new Gtk.Image.from_icon_name ("text-sort-ascending-symbolic", Gtk.IconSize.BUTTON);
            sort_name.tooltip_text = _ ("Sort by Filename");
            sort_mode.append (sort_name);

            sort_date = new Gtk.Image.from_icon_name ("time-sort-ascending-symbolic", Gtk.IconSize.BUTTON);
            sort_date.tooltip_text = _ ("Sort by Date");
            sort_mode.append (sort_date);

            sort_mode.mode_changed.connect (() => {
                switch (sort_mode.selected) {
                    case 0 :
                        if (settings.sort_column == "name") {
                            settings.sort_asc = !settings.sort_asc;
                        } else {
                            settings.sort_column = "name";
                            settings.sort_asc = true;
                        }
                        break;
                    case 1 :
                        if (settings.sort_column == "date") {
                            settings.sort_asc = !settings.sort_asc;
                        } else {
                            settings.sort_column = "date";
                            settings.sort_asc = true;
                        }
                        break;
                }
                sort_mode.selected = -1;
            });

            headerbar.pack_start (sort_mode);
        }

        private void header_build_app_menu () {
            app_menu = new Gtk.MenuButton ();
            app_menu.valign = Gtk.Align.CENTER;
            app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));

            var settings_menu = new Gtk.Menu ();

            var menu_item_preferences = new Gtk.MenuItem.with_label (_ ("Preferences"));
            menu_item_preferences.activate.connect (() => {
                    var preferences = new Dialogs.Preferences (this);
                    preferences.run ();
                });
            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);
        }

        private void header_build_style_switcher () {
            var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
            mode_switch.primary_icon_tooltip_text = _("Light background");
            mode_switch.secondary_icon_tooltip_text = _("Dark background");
            mode_switch.valign = Gtk.Align.CENTER;
            mode_switch.active = settings.use_dark_theme;
            mode_switch.notify["active"].connect (() => {
                settings.use_dark_theme = mode_switch.active;
            });
            headerbar.pack_end (mode_switch);
        }

        private void update_sort_icons () {
            switch (settings.sort_column) {
                case "name":
                    sort_date.icon_name = "preferences-system-time-symbolic";
                    if (settings.sort_asc) {
                        sort_name.icon_name = "text-sort-ascending-symbolic";
                    } else {
                        sort_name.icon_name = "text-sort-descending-symbolic";
                    }
                    break;
                case "date":
                    sort_name.icon_name = "format-text-larger-symbolic";
                    if (settings.sort_asc) {
                        sort_date.icon_name = "time-sort-ascending-symbolic";
                    } else {
                        sort_date.icon_name = "time-sort-descending-symbolic";
                    }
                    break;
            }
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
