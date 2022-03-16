module Generic {
    public type Property = {
        key   : Text;
        value : Value;
    };

    public type Value = {
        #Nat64Content  : Nat64;
        #Nat32Content  : Nat32;
        #BoolContent   : Bool;
        #Nat8Content   : Nat8;
        #Int64Content  : Int64;
        #IntContent    : Int;
        #NatContent    : Nat;
        #Nat16Content  : Nat16;
        #Int32Content  : Int32;
        #Int8Content   : Int8;
        #Int16Content  : Int16;
        #BlobContent   : Blob;
        #NestedContent : [Value];
        #Principal     : Principal;
        #TextContent   : Text;
    };

    // All of the following are reserved by the spec to verify and display assets across all applications.
    // NOTE: data and location are mutual exclusive, only one of them is required.
    public module Reserved {
        // Blob asset data.
        public func data(data : Blob) : Property = {
            key   = "blob";
            value = #BlobContent(data);
        };

        // URL location for the fully rendered asset content.
        public func location(location : Text) : Property = {
            key   = "location";
            value =  #TextContent(location);
        };

        // SHA-256 hash fingerprint of the asset defined in location or asset.
        public func contentHash(hash : Blob) : Property = {
            key   = "contentHash";
            value =  #BlobContent(hash);
        };

        // MIME type of the asset defined in location.
        public func contentType(mime : Text) : Property = {
            key   = "contentType";
            value =  #TextContent(mime);
        };

        // URL location for the preview thumbnail for asset content.
        public func thumbnail(url : Text) : Property = {
            key   = "thumbnail";
            value =  #TextContent(url);
        };
    };
};
