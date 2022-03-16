import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

module {
    public type Interface = actor {
        // Transfers value amount of tokens to user to, returns a TxReceipt which
        // contains the transaction index or an error message.
        transfer : shared (to : Principal, value : Nat) -> async TxReceipt;
        // Transfers value amount of tokens from user from to user to, this method allows canster smart contracts to transfer
        // tokens on your behalf, it returns a TxReceipt which contains the transaction index or an error message.
        transferFrom : shared (from : Principal, to : Principal, value : Nat) -> async TxReceipt;
        // Allows spender to withdraw tokens from your account, up to the value amount. If it is called again it overwrites
        // the current allowance with value. There is no upper limit for value.
        approve : (spender : Principal, value : Nat) -> async TxReceipt;
        
        // Returns the balance of user p.
        balanceOf : query (p : Principal) -> async Nat;
        // Returns the amount which spender is still allowed to withdraw from owner.
        allowance : query (owner : Principal, spender : Principal) -> async Nat;
    
        // Returns the logo of the token.
        logo : query () -> async Text;
        // Returns the name of the token.
        name : query () -> async Text;
        // Returns the symbol of the token.
        symbol : query () -> async Text;
        // Returns the decimals of the token.
        decimals : query () -> async Nat8;
        // Returns the total supply of the token.
        totalSupply : query () -> async Nat;
        // Returns the metadata of the token.
        getMetadata : query () -> async Metadata;
    };

    // Metadata: basic token information.
    public type Metadata = {
        // A base64 encoded logo or logo URL.
        logo        : Text;
        // Name of the token.
        name        : Text;
        // Symbol of the token.
        symbol      : Text; 
        // Decimals (precision) of the token.
        decimals    : Nat8;
        // Total supply of the token.
        totalSupply : Nat;
        // Owner of the token.
        owner       : Principal;
        // Fee for update calls.
        fee         : Nat;
    };

    // TxReceipt: receipt for update calls, contains the transaction index or an error message.
    public type TxReceipt = {
        #Ok: Nat;
        #Err: {
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other: Text;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    // TxRecord: history transaction record.
    public type Operation = {
        #approve;
        #mint;
        #transfer;
        #transferFrom;
    };

    public type TransactionStatus = {
        #succeeded;
        #failed;
    };

    public type TxRecord = {
        // Caller is optional and ONLY need to be non-empty for transferFrom calls.
        caller    : ?Principal;
        // Operation type.
        op        : Operation;
        // Transaction index.
        index     : Nat;
        from      : Principal;
        to        : Principal;
        amount    : Nat;
        fee       : Nat;
        timestamp : Int;
        status    : TransactionStatus;
    };

    public class Token(
        _logo        : Text,
        _name        : Text,
        _symbol      : Text,
        _decimals    : Nat8,
        _totalSupply : Nat,
        _owner       : Principal,
        _fee         : Nat,
        _balances    : [(Principal, Nat)],
        _allowances  : [(Principal, [(Principal, Nat)])]
    ) {
        public let metadata : internal.Metadata = {
            var logo        = _logo;
            var name        = _name;
            var symbol      = _symbol;
            var decimals    = _decimals;
            var totalSupply = _totalSupply;
            var owner       = _owner;
            var fee         = _fee;
        };

        public func data() : Metadata = {
            logo        = metadata.logo;
            name        = metadata.name;
            symbol      = metadata.symbol;
            decimals    = metadata.decimals;
            totalSupply = metadata.totalSupply;
            owner       = metadata.owner;
            fee         = metadata.fee;
        };

        public let balances = HashMap.fromIter<Principal, Nat>(
            _balances.vals(), _balances.size(), Principal.equal, Principal.hash,
        );

        public func chargeFee(from : Principal) {
            if (0 < metadata.fee) { transferFrom(from, metadata.owner, metadata.fee) };
        };

        // @pre: chargeFee(from)
        // @pre: enoughBalance(value)
        public func transferFrom(from : Principal, to : Principal, value : Nat) {
            let newFromBalance : Nat = balanceOf(from) - value;
            if (newFromBalance != 0) {
                balances.put(from, newFromBalance);
            } else { balances.delete(from) };

            let newToBalance : Nat = balanceOf(to) + value;
            if (newToBalance != 0) { balances.put(to, newToBalance); };
        };

        public let allowances = HashMap.fromIter<Principal, HashMap.HashMap<Principal, Nat>>(
            object {
                let a = _allowances.vals();
                public func next() : ?(Principal, HashMap.HashMap<Principal, Nat>) {
                    switch (a.next()) {
                        case (?(p, a)) {
                            ?(p, HashMap.fromIter<Principal, Nat>(
                                a.vals(), 1, Principal.equal, Principal.hash,
                            ));
                        };
                        case (_) { null };
                    };
                };
            }, _allowances.size(), Principal.equal, Principal.hash,
        );

        public func allowance(owner : Principal, spender : Principal) : Nat {
            switch(allowances.get(owner)) {
                case (? allowance) {
                    switch(allowance.get(spender)) {
                        case (?t) { t; };
                        case (_)  { 0; };
                    }
                };
                case (_) { 0; };
            };
        };

        // @pre: enoughAllowance(value + fee)
        public func useAllowance(owner : Principal, spender : Principal, value : Nat) {
            let a = allowance(owner, spender);
            approve(owner, spender, a - value - metadata.fee);
        };

        // @pre: chargeFee(owner)
        // @pre: enoughBalance(fee)
        public func approve(owner : Principal, spender : Principal, value : Nat) {
            let v = value + metadata.fee;
            switch (allowances.get(owner)) {
                case (? allowance) {
                    if (value == 0) {
                        allowance.delete(spender);
                        if (allowances.size() == 0) allowances.delete(owner);
                    } else {allowance.put(spender, v) };
                };
                case (null) {
                    if (value == 0) return;
                    allowances.put(owner, HashMap.fromIter(
                        [(spender, v)].vals(), 1, Principal.equal, Principal.hash,
                    ));
                };
            };
        };

        public func enoughBalance(p : Principal, value : Nat) : Bool {
            value + metadata.fee <= balanceOf(p);
        };

        public func enoughAllowance(from : Principal, to : Principal, value : Nat) : Bool {
            enoughBalance(from, value) and value + metadata.fee <= allowance(from, to);
        };

        public func balanceOf(p : Principal) : Nat {
            switch (balances.get(p)) {
                case (?t) { t; };
                case (_)  { 0; };
            };
        };

        public func toStable() : {
            metadata   : Metadata;
            balances   : [(Principal, Nat)];
            allowances : [(Principal, [(Principal, Nat)])];
        } = {
            metadata = data();
            balances = Iter.toArray(balances.entries());
            allowances = Iter.toArray(object {
                let a = allowances.entries();
                public func next() : ?(Principal, [(Principal, Nat)]) {
                    switch (a.next()) {
                        case (? (p, a)) { ?(p, Iter.toArray(a.entries())) };
                        case (_) { null };
                    };
                };
            })
        };
    };

    private module internal {
        public type Metadata = {
            var logo        : Text;
            var name        : Text;
            var symbol      : Text; 
            var decimals    : Nat8;
            var totalSupply : Nat;
            var owner       : Principal;
            var fee         : Nat;
        };
    };
}
