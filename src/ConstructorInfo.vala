using Gee;

class ConstructorInfo {
    public string? c_namespace {
        get;
        private set;
    }
    
    public string[]? new_keywords {
        get {
            return _new_keywords;
        }
    }
    private string[] _new_keywords;
    
    public GLib.List<string> c_constructors {
        owned get {
            GLib.List<string> constructors = new GLib.List<string> ();
            foreach (string constructor in constructor_set) {
                constructors.prepend (constructor);
            }
            return constructors;
        }
    }
    private HashSet<string> constructor_set;
    
    public bool is_empty {
        get {
            return constructor_set.is_empty;
        }
    }
    
    public ConstructorInfo (string? c_namespace, owned string[]? new_keywords) {
        this.c_namespace = c_namespace;
        constructor_set = new HashSet<string> ();
        
        _new_keywords = new_keywords;
    }
    
    public void add_c_constructor (string constructor) {
        constructor_set.add (constructor);
    }
    
    public bool contains (string constructor) {
        return constructor_set.contains (constructor);
    }
}
