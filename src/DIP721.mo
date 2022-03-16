import Generic "Generic";

// NOTE: v2
module {
    type SupportedInterface = {
        #Burn;
        #Mint;
        #Approval;
        #TransactionHistory;
    };

    // Every DIP-721 compatible smart contract must implement this interface.
    // All other interfaces are optional.
    public type BasicInterface = actor {
        // Returns the interfaces supported by this NFT canister.
        supportedInterfaces : query () -> async [SupportedInterface];

        // Returns the Metadata for the given tokenId.
        // If the toikenId does not exist an error is returned.
        tokenMetadata : query (tokenId : Nat) -> async Result<TokenMetadata, NftError>;
        // Returns the count of NFTs owned by user.
        // If the user does not own any NFTs an error is returned.
        balanceOf: query (owner : Principal) -> async Result<Nat, NftError>;
        // Returns a Nat that represents the total current supply of NFT tokens.
        // NFTs that are minted and later burned explicitly or sent to the zero address should also count towards totalSupply.
        totalSupply : query () -> async (Nat);

        // Returns the Principal of the owner of the NFT associated with the given tokenId.
        // Otherwise if the given tokenId is invalid an error is returned.
        ownerOf : query (tokenId : Nat) -> async Result<Principal, NftError>;
        // Returns the list of the tokenIds associated with the given owner.
        ownerTokenIds : query (owner : Principal) -> async Result<[Nat], NftError>;
        // Returns the list of metadata of the NFTs associated with the given owner.
        ownerTokenMetadata : query (owner : Principal) -> async Result<[TokenMetadata], NftError>;

        // Returns the Principal of the operator of the NFT associated with token_identifier.
        // Otherwise if the given tokenId is invalid an error is returned.
        operatorOf : query (tokenId : Nat) -> async Result<Principal, NftError>;
        // Returns the list of the tokenIds associated with the given operator.
        operatorTokenIds : query (operator : Principal) ->  async Result<[Nat], NftError>;
        // Returns the list of metadata of the NFTs associated with the given operator.
        operatorTokenMetadata : (operator : Principal) -> async Result<[TokenMetadata], NftError>;

        // Sets the list of custodians for the NFT canister.
        // 🛑: caller must be the custodian of NFT canister.
        setCustodians : shared (custodians : [Principal]) -> async ();

        // Sets the logo of the NFT canister. Base64 encoded text is recommended.
        // 🛑: caller must be the custodian of NFT canister.
        setLogo : shared (logo : Text) -> async ();
        // Sets the name of the NFT canister.
        // 🛑: caller must be the custodian of NFT canister.
        setName : shared (name : Text) -> async ();
        // Sets the symbol for the NFT canister.
        // 🛑: caller must be the custodian of NFT canister.
        setSymbol : shared (symbol : Text) -> async ();

        // Returns a list of principals that represents the custodians (or admins) of the NFT canister.
        custodians : query () -> async [Principal];

        // Returns the logo of the NFT contract as Base64 encoded text.
        logo : query () -> async ?Text;
        // Returns the name of the NFT contract.
        name : query () -> async ?Text;
        // Returns the symbol of the NFT contract.
        symbol : query () -> async ?Text;
        // Returns the Metadata of the NFT canister which includes custodians, logo, name, symbol.
        metadata : query () -> async Metadata;
    };

    // This interface adds approve functionality to DIP-721 tokens.
    // NOTE: If the approval goes through, returns a Nat that represents the CAP History transaction ID that can be used at the transaction method.
    public type ApprovalInterface = actor {
        // Calling approve grants the operator the ability to make update calls to the specificied tokenId.
        // Approvals given by the approve function are independent from approvals given by the setApprovalForAll.
        approve : (operator : Principal, tokenId : Nat) -> async Result<Nat, NftError>;
        // Enable or disable an operator to manage all of the tokens for the caller of this function. The contract allows multiple operators per owner.
        // Approvals granted by the approve function are independent from the approvals granted by setApprovalForAll function.
        setApprovalForAll : (operator : Principal, toggle : Bool) -> async Result<Nat, NftError>;
        // Returns true if the given operator is an approved operator for all the tokens owned by the caller through the use of the setApprovalForAll method, returns false otherwise.
        isApprovedForAll : query (owner : Principal, operator : Principal) -> async Result<Nat, NftError>;
    };

    // This interface adds transfer functionality to DIP-721 tokens.
    // NOTE: If the transfer goes through, returns a Nat that represents the CAP History transaction ID that can be used at the transaction method.
    public type TransferInterface = actor {
        // Sends the callers nft tokenId to to and returns a Nat that represents a transaction id that can be 
        // used at the transaction method.
        transfer : shared (to : Principal, tokenId : Nat) -> async Result<Nat, NftError>;
        // Caller of this method is able to transfer the NFT tokenId that is in from's balance to to's balance if the 
        // caller is an approved operator to do so.
        transferFrom : shared (from : Principal, to : Principal, tokenId : Nat) -> async Result<Nat, NftError>;
    };

    // This interface adds mint functionality to DIP-721 tokens.
    public type MintInterface = actor {
        // Mint an NFT for principal to that has an ID of tokenId and metadata akin to properties.
        // Implementations are encouraged to only allow minting by the owner of the canister.
        mint : shared (to : Principal, tokenId : Nat, properties : [Generic.Property]) -> async Result<Nat, NftError>;
    };

    // This interface adds burn functionality to DIP-721 tokens.
    public type BurnInterface = actor {
        // Burn an NFT identified by tokenId. Calling burn on a token sets the owner to None and will no longer be useable.
        // Burned tokens do still count towards totalSupply.
        // Implementations are encouraged to only allow burning by the owner of the tokenId.
        burn : shared  (tokenId : Nat) -> async Result<Nat, NftError>;
    };

    // This interface adds transaction history to DIP-721 tokens.
    public type HistoryInterface = actor {
        // Returns the TxEvent that corresponds with txId.
        // If there is no TxEvent that corresponds with the txId entered, returns a NftError.TxNotFound.
        transaction : query (txId : Nat) -> async Result<TxEvent, NftError>;
        // Returns a Nat that represents the total number of transactions that have occured in the NFT canister.
        totalTransactions : query () -> async Nat;
    };

    public type Result<T, E> = {
        #Ok  : T;
        #Err : E;
    };

    public type Metadata = {
        logo        : ?Text;
        name        : ?Text;
        created_at  : Nat64;
        upgraded_at : Nat64;
        custodians  : [Principal];
        symbol      : ?Text;
    };

    public type TokenMetadata = {
        transferred_at   : ?Nat64;
        transferred_by   : ?Principal;
        owner            : ?Principal;
        operator         : ?Principal;
        properties       : [Generic.Property];
        is_burned        : Bool;
        token_identifier : Nat;
        burned_at        : ?Nat64;
        burned_by        : ?Principal;
        minted_at        : Nat64;
        minted_by        : Principal;
    };

    public type TxEvent = {
        time      : Nat64;
        operation : Text;
        details   : [Generic.Property];
        caller    : Principal;
    };

    public type NftError = {
        #SelfTransfer;
        #TokenNotFound;
        #TxNotFound;
        #BurnedNFT;
        #SelfApprove;
        #OperatorNotFound;
        #Unauthorized;
        #ExistedNFT;
        #OwnerNotFound;
        #Other : Text;
    };
};

