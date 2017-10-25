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

    foreach (string file in c_files) {
        stdout.printf ("%s\n", file);
        rewrite_file (File.new_for_path (file), null, matcher);
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

const string[] blacklist = {
    "if",
    "while",
    "for",
    "sizeof",
    "switch",
    "g_free"
};

private string? extract_funtion (string code_piece, long length) {
    string? function = null;

    long pos = length;
    long end_pos = 0;
    long start_pos = 0;
    bool end_found = false;
    bool start_found = false;
    bool cont = true;

    while (cont && pos-- > 0) {
        uchar byte = code_piece.get(pos);
        if (
            byte >= '0' &&
            (byte <= '9' || byte >= 'A') &&
            (byte <= 'Z' || byte >= 'a' || byte == '_') &&
            byte <= 'z'
        ) {
            if (!end_found) {
                end_found = true;
                end_pos = pos + 1;
            }
        } else {
            if (end_found) {
                start_found = true;
                start_pos = pos + 1;
            } else if (byte > 32) {
                cont = false;
            }
        }
        cont = cont && !start_found;
    }
    if (!start_found && end_found) {
        start_found = cont && end_pos > start_pos + 1;
    }
    if (start_found) {
        function = code_piece.slice(start_pos, end_pos);
        foreach (string ignore in blacklist) {
            if (function == ignore) {
                return null;
            }
        }
    }
    return function;
}

private void print_function (string code_piece, long length) {
    var function = extract_funtion (code_piece, length);
    if (function != null) {
        stdout.printf ("%s\n", function);
    }
}

private void rewrite_file (File in_file, File? out_file, CMatcher matcher) {
    try {
        var stream_in = new DataInputStream (in_file.read ());
        string line;
        size_t length;

        while ((line = stream_in.read_upto ("(", 1, out length)) != null) {
            var function = extract_funtion (line, (long)length);
            if (function != null) {
                if (matcher.is_known_constructor (function)) {
                    stdout.printf ("known constructor: %s\n", function);
                }
            }
            if (stream_in.get_available () > 0) {
                stream_in.read_byte ();
            }
        }
    } catch (Error e) {
        warning (e.message);
    }
}
