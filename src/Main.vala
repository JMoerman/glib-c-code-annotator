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

private string? extract_funtion (string code_piece, long length, out long start, out long end) {
    string? function = null;

    long pos = length;
    end = 0;
    start = 0;
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
                end = pos + 1;
            }
        } else {
            if (end_found) {
                start_found = true;
                start = pos + 1;
            } else if (byte > 32) {
                cont = false;
            }
        }
        cont = cont && !start_found;
    }
    if (!start_found && end_found) {
        start_found = cont && end > start + 1;
    }
    if (start_found) {
        function = code_piece.slice(start, end);
        foreach (string ignore in blacklist) {
            if (function == ignore) {
                return null;
            }
        }
    }
    return function;
}

class BracketTree {
    public GLib.Queue<BracketTree>? children {
        public get {
            return _children;
        }
        owned set {
            _children = (owned) value;
        }
    }
    private GLib.Queue<BracketTree>? _children;

    public string content {
        get;
        set;
    }

    public BracketTree (owned GLib.Queue<BracketTree>? children, string content) {
        this.children = (owned) children;
        this.content = content;
    }

    public BracketTree.from_stream(string content, DataInputStream stream) throws IOError {
        this.content = content;
        bool cont = true;
        string line;
        children = new GLib.Queue<BracketTree> ();
        while ((line = stream.read_upto ("()\"", 3, null)) != null) {
            uchar? delim = '\0';
            if (stream.get_available () > 0) {
                delim = stream.read_byte ();
            }
            switch (delim) {
                case '(':
                    children.push_tail (new BracketTree.from_stream(line, stream));
                    break;
                case ')':
                    children.push_tail (new BracketTree (null, line));
                    cont = false;
                    break;
                case '"':
                    line = "\"" + line + stream.read_upto ("\"", 1, null);
                    if (stream.get_available () > 0) {
                        delim = stream.read_byte ();
                        line = line + "\"";
                    }
                    children.push_tail (new BracketTree (null, line));
                    break;
                default:
                    children.push_tail (new BracketTree (null, line));
                    cont = false;
                    break;
            }

            if (!cont) {
                break;
            }
        }
    }


    public void print_filestream (GLib.FileStream stream) {
        stream.printf ("%s", content);
        if (children != null) {
            stream.printf ("(");
            foreach (var child in children.head) {
                if (child == this) {
                    foreach (var _child in children.head) {
                        warning ("%s", _child.content);
                    }
                    error ("child == this %s", content);
                }
                child.print_filestream (stream);
            }
            stream.printf (")");
        }

    }

    public void insert_node (string new_content, string child_content) {
        var _children = new GLib.Queue<BracketTree> ();
        var child_node = new BracketTree ((owned) this._children, child_content);
        _children.push_tail (child_node);
        this._children = (owned) _children;
        content = new_content;
    }
}

private void rewrite_tree (BracketTree tree, CMatcher matcher) {
    unowned GLib.Queue<BracketTree>? children = tree.children;
    if (children != null) {
        foreach (var node in children.head) {
            rewrite_tree (node, matcher);
        }
        long start, end, length;
        var content = tree.content;
        length = content.length;
        var function = extract_funtion (content, length, out start, out end);
        if (function != null) {
            if (matcher.is_known_constructor (function)) {
                content = content.splice (start, end, "test_func");
                tree.insert_node (content, function);
            }
        }
    }
}

private void rewrite_file (File in_file, File? out_file, CMatcher matcher) {
    try {
        var stream_in = new DataInputStream (in_file.read ());
        var tree = new BracketTree.from_stream ("", stream_in);
        rewrite_tree (tree, matcher);
        tree.print_filestream (stdout);
        stdout.flush ();
    } catch (Error e) {
        warning (e.message);
    }
}
