export const idlFactory = ({ IDL }) => {
  const View = IDL.Record({
    'messages' : IDL.Vec(IDL.Text),
    'start_index' : IDL.Nat,
  });
  const MainLogger = IDL.Service({
    'append' : IDL.Func([IDL.Vec(IDL.Text)], [IDL.Text], []),
    'newLogger' : IDL.Func([], [], []),
    'view' : IDL.Func([IDL.Nat, IDL.Nat], [View], []),
  });
  return MainLogger;
};
export const init = ({ IDL }) => { return []; };
