class GirParser {
    private GLib.List<ConstructorMap> parsed_info;
    
    public GirParser () {
        parsed_info = new GLib.List<ConstructorMap> ();
    }
    
    private void parse_doc (Xml.Node* root) {
        foreach (Xml.Node* node in new NodeIterator (root->children, "namespace")) {
            var info = new ConstructorMap (node->get_prop("symbol-prefixes"), {"_new"});
            foreach (Xml.Node* classnode in new NodeIterator (node->children, "class")) {
                string c_type = classnode->get_prop("type");
                foreach (Xml.Node* constructnode in new NodeIterator (classnode->children, "constructor")) {
                    string c_identifier = constructnode->get_prop("identifier");
                    if (c_identifier != null) {
                        info.add_c_constructor (c_identifier, c_type);
                    } else {
                        warning ("constructor node is missing c identifier %s %s", classnode->get_prop("name"), constructnode->get_prop("name"));
                    }
                }
            }
            if (!info.is_empty) {
                parsed_info.prepend (info);
            }
        }
    }
    
    public void parse_file_from_path (string path) {
        // Parse the document from path
	    Xml.Doc* doc = Xml.Parser.parse_file (path);
	    if (doc == null) {
		    stdout.printf ("File '%s' not found or permissions missing\n", path);
		    return;
	    }

	    Xml.Node* root = doc->get_root_element ();
	    if (root == null) {
		    warning ("Root element missing in document %s\n", path);
		    delete doc;
		    return;
	    }

	    if (root->name == "api" || root->name == "repository") {
		    parse_doc (root);
	    } else {
		    warning ("Root element of %s has an unexpected name: %s\n", path, root->name);
	    }

	    delete doc;
    }
    
    public GLib.List<ConstructorMap> get_parsed_info () {
        var parsed_info_copy = new GLib.List<ConstructorMap> ();
        foreach (var info in parsed_info) {
            parsed_info_copy.prepend (info);
        }
        return parsed_info_copy;
    }
}

public class NodeIterator {
    Xml.Node* node;
    string? name;
    
    public NodeIterator (Xml.Node* node, string? name) {
        this.node = node;
        this.name = name;
    }
    
    public bool next () {
        if (node == null) {
            return false;
        }
        
        node = node->next;
        
        while (node != null) {
            if (node->type == Xml.ElementType.ELEMENT_NODE) {
                break;
            }
            node = node->next;
        }
        
        if (name == null) {
            return node != null;
        }
        
        while (node != null) {
            if (node->name == name) {
                return true;
            }
            node = node->next;
        }
        
        return false;
    }
    
    public new Xml.Node* get () {
        return node;
    }
    
    public NodeIterator iterator () {
        return this;
    }
}
