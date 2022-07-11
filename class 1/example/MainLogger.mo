import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Deque "mo:base/Deque";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import IC "ic";
import Logger "mo:ic-logger/Logger";
import SubLogger "SubLogger";


shared actor class MainLogger() = this {
    private let CYCLE_LIMIT = 2_000_000_000_000;
    private let MESSAGE_SIZE_PER_LOGGER = 100;
    private let ic : IC.Self = actor "aaaaa-aa";
    private var logger_map = TrieMap.TrieMap<Nat, Principal>(Nat.equal, Hash.hash);
    private var logger_size = 0;    // 当前生成了几个logger
    private var msg_size = 0;       // 当前储存了几条msg

    private type Sub_Logger = actor {
        append : shared (msgs : [Text]) -> async ();
        view : query (from: Nat, to: Nat) -> async Logger.View<Text>;
        stats : query () -> async Logger.Stats;
    };

    public shared func append(msgs: [Text]) : async Text {
        var remain_msgs_size : Nat = msgs.size();
        // 如果msgs为空，直接返回结果
        if (remain_msgs_size == 0) {return "Append Messages Finished."};
        // 初始化第一个sublogger
        if (logger_size == 0) {await newLogger()};
        // 记录当前写到第几条msg
        var ptr : Nat = 0;

        label l loop {
            if (remain_msgs_size == 0) {
                break l;
            } else {
                // 获得当前logger能够储存msg的空间大小
                let available_append_size : Nat = logger_size * MESSAGE_SIZE_PER_LOGGER - msg_size;
                var append_size : Nat = 0;
                if (available_append_size >= remain_msgs_size) {
                    append_size := remain_msgs_size;
                    msg_size += remain_msgs_size;
                    remain_msgs_size -= remain_msgs_size;
                } else {
                    append_size := available_append_size;
                    msg_size += available_append_size;
                    remain_msgs_size -= available_append_size;
                };
                
                // 组装写入当前logger的msgs数组
                var append_array : [var Text] = Array.init<Text>(append_size, "");
                for (i in Iter.range(0, append_size - 1)) {
                    append_array[i] := msgs[ptr];
                    ptr += 1;
                };
                
                // 将msgs数组写入logger
                switch (logger_map.get(logger_size)) {
                    case (null) {};
                    case (?principal) {
                        let sub_logger : Sub_Logger = actor(Principal.toText(principal));
                        await sub_logger.append(Array.freeze(append_array));
                    };
                };
                // 如果还有剩余的msg未写入，则生成新的logger
                if (remain_msgs_size > 0) {await newLogger()};
            }
        };
        return "Append Messages Finished."
    };

    public shared func view(from : Nat, to : Nat) : async Logger.View<Text> {
        // 判断范围是否合法
        assert(0 <= from and from<= msg_size);
        assert(0 <= to and to<= msg_size);   
        assert(from <= to);

        // 获得涉及到的sublogger区间
        let start_logger_index : Nat = (from + 1) / MESSAGE_SIZE_PER_LOGGER + 1;
        let end_logger_index : Nat = (to + 1) / MESSAGE_SIZE_PER_LOGGER + 1;
        var view_array : [var Text] = Array.init<Text>(to - from + 1, "");
        var ptr : Nat = 0;

        for (logger_index in Iter.range(start_logger_index, end_logger_index)) {
            switch (logger_map.get(logger_index)) {
                case (null) {};
                case (?principal) {
                    let sub_logger : Sub_Logger = actor(Principal.toText(principal));
                    var start_msg_index : Nat = 0;
                    var end_msg_index : Nat = 0;
                    // 判断sublogger中需要取出来的msg区间
                    if (logger_index == start_logger_index) {
                        start_msg_index := from;
                        end_msg_index := if (start_logger_index == end_logger_index) {to} else {99};
                    } else if (logger_index == end_logger_index) {
                        start_msg_index := if (start_logger_index == end_logger_index) {from} else {0};
                        end_msg_index := to;
                    } else {
                        start_msg_index := 0;
                        end_msg_index := 99;
                    };

                    //取出msg，写入view中
                    var msg_array : [var Text] = [var];
                    msg_array := Array.thaw<Text>((await sub_logger.view(start_msg_index, end_msg_index)).messages);
                    for (msg in msg_array.vals()) {
                        view_array[ptr] := msg;
                        ptr += 1;
                    }; 
                };
            }
        };
        {
            start_index = from;
            messages = Array.freeze(view_array);
        }
    };

    public func newLogger() : async () {
        Cycles.add(CYCLE_LIMIT);
        let logger = await SubLogger.SubLogger();
        let principal = Principal.fromActor(logger);

        await ic.update_settings({
            canister_id = principal;
            settings = {
                freezing_threshold = null;
                controllers = ?[Principal.fromActor(this)];
                memory_allocation = null;
                compute_allocation = null;
            }
        });

        logger_size += 1;
        logger_map.put(logger_size, principal);
    };
};
