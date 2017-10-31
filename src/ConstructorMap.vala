using Gee;

class ConstructorMap {
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

    private TreeMap<string, string> constructor_set;

    public bool is_empty {
        get {
            return constructor_set.is_empty;
        }
    }

    public ConstructorMap (string? c_namespace, owned string[]? new_keywords) {
        this.c_namespace = c_namespace;
        constructor_set = new TreeMap<string, string> ();

        _new_keywords = new_keywords;
    }

    public void add_c_constructor (string c_constructor, string c_class) {
        constructor_set.set (c_constructor, c_class);
    }

    public bool contains (string c_constructor) {
        return constructor_set.has_key (c_constructor);
    }

    public new string @get (string c_constructor) {
        return constructor_set.get (c_constructor);
    }
}
