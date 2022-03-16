import Time "mo:base/Time";

import DIP "../../../src/DIP721";

shared({ caller = _owner }) actor class Token(
    _logo        : ?Text,
    _name        : ?Text,
    _symbol      : ?Text,
) : async DIP.BasicInterface {
    let nft = DIP.BasicNFT(
        _logo, _name, _symbol,
        [_owner], Time.now(),
        [], [], []
    );

    public query func supportedInterfaces() : async [DIP.SupportedInterface] { [] };

    public query func tokenMetadata(tId : Nat) : async DIP.Result<DIP.TokenMetadata> {
        switch (nft.tokens.get(tId)) {
            case (?m) #Ok(m);
            case (_)  #Err(#TokenNotFound);
        };
    };

    public query func totalSupply() : async Nat { nft.tokens.size() };

    public query func balanceOf(owner : Principal) : async DIP.Result<Nat> { #Ok(nft.balanceOf(owner)) };

    public query func ownerOf(tId : Nat) : async DIP.Result<Principal> {
        switch (nft.ownerOf(tId)) {
            case (? p) #Ok(p);
            case (_)   #Err(#TokenNotFound);
        };
    };

    public query func ownerTokenIds(owner : Principal) : async DIP.Result<[Nat]> {
        #Ok(nft.tokenIds(nft.owners, owner));
    };

    public query func ownerTokenMetadata(owner : Principal) : async DIP.Result<[DIP.TokenMetadata]> {
        #Ok(nft.tokenMetadata(nft.owners, owner));
    };

    public query func operatorOf(tId : Nat) : async DIP.Result<Principal> {
        switch (nft.operatorOf(tId)) {
            case (? p) #Ok(p);
            case (_)   #Err(#TokenNotFound);
        };
    };

    public query func operatorTokenIds(operator : Principal) : async DIP.Result<[Nat]> {
        #Ok(nft.tokenIds(nft.operators, operator));
    };

    public query func operatorTokenMetadata(operator : Principal) : async DIP.Result<[DIP.TokenMetadata]> {
        #Ok(nft.tokenMetadata(nft.operators, operator));
    };

    public shared({caller}) func setCustodians(custodians : [Principal]) : async () {
        assert(nft.isCustodian(caller));
        nft.metadata.custodians := custodians;
    };

    public shared({caller}) func setLogo(logo : Text) : async () {
        assert(nft.isCustodian(caller));
        nft.metadata.logo := ?logo;
    };

    public shared({caller}) func setName(name : Text) : async () {
        assert(nft.isCustodian(caller));
        nft.metadata.name := ?name;
    };

    public shared({caller}) func setSymbol(symbol : Text) : async () {
        assert(nft.isCustodian(caller));
        nft.metadata.symbol := ?symbol;
    };

    public query func custodians() : async [Principal] { nft.metadata.custodians };
    public query func logo() : async ?Text { nft.metadata.logo };
    public query func name() : async ?Text { nft.metadata.name };
    public query func symbol() : async ?Text { nft.metadata.symbol };
    public query func metadata() : async DIP.Metadata { nft.data() };
};
