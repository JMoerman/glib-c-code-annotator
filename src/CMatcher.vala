class CMatcher {
    GLib.List<ConstructorInfo> constructors;

    public CMatcher (owned GLib.List<ConstructorInfo> constructors) {
        this.constructors = (owned) constructors;
    }
    
    public bool is_known_constructor (string method_call) {
        foreach (var info in constructors) {
            if (info.c_namespace != null) {
                if (!method_call.has_prefix (info.c_namespace)) {
                    continue;
                }
            }
            var new_keywords = info.new_keywords;
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
            if (info.contains (method_call)) {
                return true;
            }
        }
        return false;
    }
}
