class CMatcher {
    GLib.List<ConstructorMap> constructor_maps;

    public CMatcher (owned GLib.List<ConstructorMap> constructor_maps) {
        this.constructor_maps = (owned) constructor_maps;
    }
    
    public bool is_known_constructor (string method_call, out string? c_type) {
        c_type = null;
        foreach (var map in constructor_maps) {
            if (map.c_namespace != null) {
                if (!method_call.has_prefix (map.c_namespace)) {
                    continue;
                }
            }
            var new_keywords = map.new_keywords;
            if (new_keywords != null) {
                bool contains_keyword = false;
                foreach (string keyword in new_keywords) {
                    if (method_call.contains (keyword)) {
                        contains_keyword = true;
                        break;
                    }
                }
                if (!contains_keyword) {
                    continue;
                }
            }
            if (map.contains (method_call)) {
                c_type = map.get (method_call);
                return true;
            }
        }
        return false;
    }
}
