public static int main (string[] args) {
    string path = "/usr/share/gir-1.0/Gtk-3.0.gir";
    string method = "gtk_label_new";
    
    if (args[1] != null && args[2] != null) {
        path = args[1];
        method = args[2];
    }
    
	var parser = new GirParser ();
	parser.parse_file_from_path (path);
	var matcher = new CMatcher (parser.get_parsed_info ().copy ());
	if (matcher.is_known_constructor (method)) {
	    stdout.printf ("known\n");
	} else {
	    stdout.printf ("not known\n");
	}
	
	return 0;
}
