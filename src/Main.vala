public static int main (string[] args) {
    bool gir_file = false;
    bool c_file = false;
    bool _show_help = false;
    
    GLib.List<string> gir_files = new GLib.List<string> ();
    GLib.List<string> c_files = new GLib.List<string> ();
    
    if (args.length == 1) {
        _show_help = true;
    }
    
    foreach (string arg in args[1:args.length]) {
        if (arg.get(0) == '-') {
            gir_file = false;
            c_file = false;
            switch (arg) {
                case "--gir-files":
                    gir_file = true;
                    break;
                case "--c-files":
                    c_file = true;
                    break;
                case "--help":
                case "-h":
                    _show_help = true;
                    break;
                default:
                    warning ("unknown argument: %s", arg);
                    break;
            }
        } else {
            if (gir_file) {
                gir_files.prepend (arg);
            } else if (c_file) {
                c_files.prepend (arg);
            } else {
                warning ("unknown argument: %s", arg);
            }
        }
    }
    
    if (_show_help) {
        show_help ();
        return 0;
    }
    var matcher = new CMatcher (parse_gir (gir_files));
    if (matcher.is_known_constructor ("gtk_label_new")) {
        stdout.printf ("known constructor\n");
    } else {
        stdout.printf ("not a known constructor\n");
    }

    return 0;
}

private void show_help () {
    warning ("stub");
}

private GLib.List<ConstructorInfo> parse_gir (GLib.List<string> gir_files) {
    var parser = new GirParser ();
    foreach (string path in gir_files) {
        parser.parse_file_from_path (path);
    }
    return parser.get_parsed_info ();
}
