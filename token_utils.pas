//Copyright 2016 Andrey S. Ionisyan (anserion@gmail.com)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

unit token_utils;

interface

const
      max_symbols=10000;
      max_mem_size=32767;

      digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];

      rus_cp1251_letters=['¿','¡','¬','√','ƒ','≈','®','∆','«','»','…',
                          ' ','À','Ã','Õ','Œ','œ','–','—','“','”','‘',
                          '’','÷','◊','ÿ','Ÿ','€','‹','⁄','›','ﬁ','ﬂ',
                          '‡','·','‚','„','‰','Â','∏','Ê','Á','Ë','È',
                          'Í','Î','Ï','Ì','Ó','Ô','','Ò','Ú','Û','Ù',
                          'ı','ˆ','˜','¯','˘','˚','¸','˙','˝','˛','ˇ'];

      rus_cp866_letters=['Ä','Å','Ç','É','Ñ','Ö','','Ü','á','à','â',
                         'ä','ã','å','ç','é','è','ê','ë','í','ì','î',
                         'ï','ñ','ó','ò','ô','õ','ú','ö','ù','û','ü',
                         '†','°','¢','£','§','•','Ò','¶','ß','®','©',
                         '™','´','¨','≠','Æ','Ø','‡','·','‚','„','‰',
                         'Â','Ê','Á','Ë','È','Î','Ï','Í','Ì','Ó','Ô'];

      rus_koi8r_letters=['·','‚','˜','Á','‰','Â','≥','ˆ','˙','È','Í',
                         'Î','Ï','Ì','Ó','Ô','','Ú','Û','Ù','ı','Ê',
                         'Ë','„','˛','˚','˝','˘','¯','ˇ','¸','‡','Ò',
                         '¡','¬','◊','«','ƒ','≈','£','÷','⁄','…',' ',
                         'À','Ã','Õ','Œ','œ','–','“','”','‘','’','∆',
                         '»','√','ﬁ','€','›','Ÿ','ÿ','ﬂ','‹','¿','—'];

type
  t_charfile=file of char;
  t_sym=(nul,oper,num,ident);
  t_toc=(empty,terminal,non_term,meta,head);
  t_pl0_cmd=(NOP,LOADNUM,LOAD,STORE,CALL,INCSP,JMP,JPC,RET,HLT,EXT,
             SETDP,LOADDP,STOREDP,
             NEG,ADD,SUB,MUL,IDIV,IMOD,
             CMPE,CMPNE,CMPL,CMPLE,CMPG,CMPGE,
             PRINT,READSP,DUMP);

  t_token=record
    suc:integer; {–Ω–æ–º–µ—Ä–∞ —Å–∏–º–≤–æ–ª–æ–≤ –≤ —Ç–∞–±–ª–∏—Ü–µ —Å–∏–º–≤–æ–ª–æ–≤ –¥–ª—è –ø–µ—Ä–µ—Ö–æ–¥–∞ "—Å–æ–≤–ø–∞–ª–æ"}
    alt:integer; {–Ω–æ–º–µ—Ä–∞ —Å–∏–º–≤–æ–ª–æ–≤ –≤ —Ç–∞–±–ª–∏—Ü–µ —Å–∏–º–≤–æ–ª–æ–≤ –¥–ª—è –ø–µ—Ä–µ—Ö–æ–¥–∞ "–Ω–µ —Å–æ–≤–ø–∞–ª–æ"}
    entry:integer; {–∞–¥—Ä–µ—Å –≤—Ö–æ–¥–∞ (—Ä–∞—Å—à–∏—Ñ—Ä–æ–≤–∫–∏) –Ω–µ—Ç–µ—Ä–º–∏–Ω–∞–ª—å–Ω–æ–≥–æ —Å–∏–º–≤–æ–ª–∞}
    kind_toc:t_toc; {—Ç–∏–ø —É–∑–ª–∞: empty, terminal, non_terminal, meta, head}
    kind_sym:t_sym; {—Ç–∏–ø —Å–∏–º–≤–æ–ª–∞: nul, oper, num, ident}
    s_name:string;
  end;

  t_token_table=array[1..max_symbols] of t_token;
  t_pl0_memory=array[0..max_mem_size-1] of integer;

function skip_nul(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_prev_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_next_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_start_of_expression(s:string;tokens_num:integer;var token_table:t_token_table):integer;
procedure find_ends_of_expression(k,tokens_num:integer;
                              var token_table:t_token_table;
                              var start_address,end_address:integer);
function get_cmd_by_code(code:integer):t_pl0_cmd;
function get_code_by_cmd(cmd:t_pl0_cmd):integer;

implementation

function skip_nul(k,tokens_num:integer;var token_table:t_token_table):integer;
begin
    while (k<tokens_num)and(token_table[k].kind_sym=nul) do k:=k+1;
    skip_nul:=k;
end; {skip_nul}

function find_prev_good_token(k,tokens_num:integer;
                              var token_table:t_token_table):integer;
begin
  while (k>0)and(token_table[k].kind_toc<>head)and
        ((token_table[k].kind_toc=meta)or(token_table[k].kind_toc=empty))
        do k:=k-1;
  find_prev_good_token:=k;
end; {find_prev_good_token}

function find_next_good_token(k,tokens_num:integer;
                              var token_table:t_token_table):integer;
begin
  while (k<tokens_num)and
        ((token_table[k].kind_toc=meta)or(token_table[k].kind_toc=empty))
        do k:=k+1;
  find_next_good_token:=k;
end; {find_next_good_token}

function find_start_of_expression(s:string;tokens_num:integer;
                              var token_table:t_token_table):integer;
var start_address,k:integer; flag:boolean;
begin
  start_address:=0; flag:=true;
  for k:=1 to tokens_num do
      if flag and (token_table[k].s_name=s)and
         (token_table[k].kind_toc=head) then
      begin
        flag:=false;
        start_address:=k;
      end;
  find_start_of_expression:=start_address;
end; {find_start_of_expression}

procedure find_ends_of_expression(k,tokens_num:integer;
                              var token_table:t_token_table;
                              var start_address,end_address:integer);
var flag:boolean;
begin
  if k>0 then
  begin
    start_address:=k;
    flag:=false;
    repeat
      if start_address=0 then flag:=true;
      if (token_table[start_address].kind_toc=head) then flag:=true
                                                    else start_address:=start_address-1;
    until flag;

    end_address:=k;
    repeat
      end_address:=end_address+1;
    until (token_table[end_address].kind_toc=head)or
          (end_address=tokens_num);

    flag:=false;
    repeat
      if end_address=0 then flag:=true;
      if (end_address>0) then
         if (token_table[end_address].s_name='.')and
            (token_table[end_address].kind_toc=meta) then flag:=true
                                                     else end_address:=end_address-1;
    until flag;
  end else
  begin
    start_address:=0;
    end_address:=0;
  end;
end; {find_end_of_expression}

function get_cmd_by_code(code:integer):t_pl0_cmd;
var tmp:t_pl0_cmd;
begin
  if code=-3 then tmp:=DUMP;
  if code=-2 then tmp:=PRINT;
  if code=-1 then tmp:=READSP;
  if code=0 then tmp:=NOP;
  if code=1 then tmp:=LOADNUM;
  if code=2 then tmp:=LOAD;
  if code=3 then tmp:=STORE;
  if code=4 then tmp:=CALL;
  if code=5 then tmp:=INCSP;
  if code=6 then tmp:=JMP;
  if code=7 then tmp:=JPC;
  if code=8 then tmp:=RET; 
  if code=9 then tmp:=HLT; 
  if code=10 then tmp:=NEG;
  if code=11 then tmp:=ADD;
  if code=12 then tmp:=SUB;
  if code=13 then tmp:=MUL;
  if code=14 then tmp:=IDIV;
  if code=15 then tmp:=IMOD;
  if code=16 then tmp:=CMPE;
  if code=17 then tmp:=CMPNE;
  if code=18 then tmp:=CMPL;
  if code=19 then tmp:=CMPG;
  if code=20 then tmp:=CMPLE;
  if code=21 then tmp:=CMPGE;
  if code=22 then tmp:=EXT;
  if code=23 then tmp:=SETDP;
  if code=24 then tmp:=LOADDP;
  if code=25 then tmp:=STOREDP;
  get_cmd_by_code:=tmp;
end;

function get_code_by_cmd(cmd:t_pl0_cmd):integer;
var tmp:integer;
begin
  if cmd=DUMP then tmp:=-3;
  if cmd=PRINT then tmp:=-2;
  if cmd=READSP then tmp:=-1;
  if cmd=NOP then tmp:=0;
  if cmd=LOADNUM then tmp:=1;
  if cmd=LOAD then tmp:=2;
  if cmd=STORE then tmp:=3;
  if cmd=CALL then tmp:=4;
  if cmd=INCSP then tmp:=5;
  if cmd=JMP then tmp:=6;
  if cmd=JPC then tmp:=7;
  if cmd=RET then tmp:=8;
  if cmd=HLT then tmp:=9;
  if cmd=NEG then tmp:=10;
  if cmd=ADD then tmp:=11;
  if cmd=SUB then tmp:=12;
  if cmd=MUL then tmp:=13;
  if cmd=IDIV then tmp:=14;
  if cmd=IMOD then tmp:=15;
  if cmd=CMPE then tmp:=16;
  if cmd=CMPNE then tmp:=17;
  if cmd=CMPL then tmp:=18;
  if cmd=CMPG then tmp:=19;
  if cmd=CMPLE then tmp:=20;
  if cmd=CMPGE then tmp:=21;
  if cmd=EXT then tmp:=22;
  if cmd=SETDP then tmp:=23;
  if cmd=LOADDP then tmp:=24;
  if cmd=STOREDP then tmp:=25;
  get_code_by_cmd:=tmp;
end;

begin
end.
