export const idlFactory = ({ IDL }) => {
  const Stats = IDL.Record({
    'bucket_sizes' : IDL.Vec(IDL.Nat),
    'start_index' : IDL.Nat,
  });
  const View = IDL.Record({
    'messages' : IDL.Vec(IDL.Text),
    'start_index' : IDL.Nat,
  });
  const SubLogger = IDL.Service({
    'append' : IDL.Func([IDL.Vec(IDL.Text)], [], ['oneway']),
    'stats' : IDL.Func([], [Stats], ['query']),
    'view' : IDL.Func([IDL.Nat, IDL.Nat], [View], ['query']),
  });
  return SubLogger;
};
export const init = ({ IDL }) => { return []; };
