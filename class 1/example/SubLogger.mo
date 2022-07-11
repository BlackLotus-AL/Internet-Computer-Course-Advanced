import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Logger "mo:ic-logger/Logger";

shared actor class SubLogger() {

    stable var state : Logger.State<Text> = Logger.new<Text>(0, null);
    let logger = Logger.Logger<Text>(state);

    public shared func append(msgs: [Text]) {
        logger.append(msgs);
    };

    public query func view(from: Nat, to: Nat) : async Logger.View<Text> {
        logger.view(from, to)
    };

    public query func stats() : async Logger.Stats {
        logger.stats()
    };
};
