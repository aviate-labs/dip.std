import DIP "../../../src/DIP20";

shared({ caller = _owner }) actor class Token(
    _logo        : Text,
    _name        : Text,
    _symbol      : Text,
    _decimals    : Nat8,
    _totalSupply : Nat,
    _fee         : Nat
) : async DIP.Interface {
    private stable var txCounter = 0;
    func increaseTxCounter() : DIP.TxReceipt {
        let txId = txCounter;
        txCounter += 1;
        #Ok(txId);
    };

    let t = DIP.Token(
        _logo, _name, _symbol,
        _decimals, _totalSupply, _owner, 
        _fee, [(_owner, _totalSupply)], [],
    );

    public shared({caller}) func transfer(to : Principal, value : Nat) : async DIP.TxReceipt {
        assert(t.enoughBalance(caller, value));
        t.chargeFee(caller);
        t.transferFrom(caller, to, value);
        increaseTxCounter();
    };

    public shared({caller}) func transferFrom(from : Principal, to : Principal, value : Nat) : async DIP.TxReceipt {
        assert(t.enoughAllowance(from, to, value));
        t.chargeFee(caller);
        t.transferFrom(from, to, value);
        t.useAllowance(from, caller, value);
        increaseTxCounter();
    };

    public shared({caller}) func approve(spender : Principal, value : Nat) : async DIP.TxReceipt {
        assert(t.enoughBalance(caller, value));
        t.chargeFee(caller);
        t.approve(caller, spender, value);
        increaseTxCounter();
    };

    public query func balanceOf(p : Principal) : async Nat {
        t.balanceOf(p);
    };

    public query func allowance(owner : Principal, spender : Principal) : async Nat {
        t.allowance(owner, spender);
    };

    public query func logo() : async Text { t.metadata.logo };
    public query func name() : async Text { t.metadata.name };
    public query func symbol() : async Text { t.metadata.symbol };
    public query func decimals() : async Nat8 { t.metadata.decimals };
    public query func totalSupply() : async Nat { t.metadata.totalSupply };
    public query func getMetadata() : async DIP.Metadata { t.data() };
};
