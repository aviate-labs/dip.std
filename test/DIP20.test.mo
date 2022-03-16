import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import DIP20 "../src/DIP20";

let owner = Principal.fromText("aaaaa-aa");
let user0 = Principal.fromText("2ibo7-dia");
let t = DIP20.Token(
    "", "Test Token", "TT", 8, 100, owner, 1,
    [(owner, 100)], [],
);

assert(t.balanceOf(owner) == 100);

t.chargeFee(owner);
assert(t.enoughBalance(owner, 10 + t.metadata.fee));
t.transferFrom(owner, user0, 10);

// NOTE: the fee went back to the owner account.
assert(t.balanceOf(owner) == 90);
assert(t.balanceOf(user0) == 10);

assert(not t.enoughBalance(user0, 10));
assert(t.enoughBalance(user0, 9));

t.approve(owner, user0, 10);
assert(t.allowance(owner, user0) == 11);
t.approve(owner, user0, 20);
assert(t.allowance(owner, user0) == 21);
t.approve(owner, user0, 0);
assert(t.allowance(owner, user0) == 0);
