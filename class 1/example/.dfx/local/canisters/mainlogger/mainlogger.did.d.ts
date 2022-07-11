import type { Principal } from '@dfinity/principal';
export interface MainLogger {
  'append' : (arg_0: Array<string>) => Promise<string>,
  'newLogger' : () => Promise<undefined>,
  'view' : (arg_0: bigint, arg_1: bigint) => Promise<View>,
}
export interface View { 'messages' : Array<string>, 'start_index' : bigint }
export interface _SERVICE extends MainLogger {}
