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

{виртуальная среда исполнения на основе PL0}
program pl0_machine(input, output);
uses token_utils, sym_scanner, rbnf_scanner, rbnf_gen, uni_parser;

procedure pl0_external_proc(ip,bp,sp:integer; var m:t_pl0_memory);
begin
end; {pl0_external_proc}

function pl0_gen_cmd(addr:integer; cmd:t_pl0_cmd; op1,op2:integer; var m:t_pl0_memory):integer;
var tmp:integer;
begin 
  m[addr]:=get_code_by_cmd(cmd); tmp:=addr+1;
  if op1<>-1 then begin m[addr+1]:=op1; tmp:=tmp+1; end;
  if op2<>-1 then begin m[addr+2]:=op2; tmp:=tmp+1; end;
  pl0_gen_cmd:=tmp;
end; {gen_cmd}

{поиск базы n уровнями ниже}
function pl0_base_down(bp,n: integer; var m:t_pl0_memory): integer;
var tmp: integer;
begin
  tmp:=bp;
  while n > 0 do begin tmp:=m[tmp]; n:=n-1; end;
  pl0_base_down:=tmp;
end {base};


procedure pl0_interpretator(ip,bp,sp:integer; var m:t_pl0_memory);
var cur_cmd: t_pl0_cmd; dp,i:integer;
begin
  writeln('START PL/O low_level interpretator');
  dp:=0;
  repeat
    cur_cmd:=get_cmd_by_code(m[ip]);
    if cur_cmd=DUMP then
    begin
      for i:=m[ip+1] to m[ip+2] do writeln('PL0 m[',i:5,']: ',m[i]);
      ip:=ip+3;
    end;
    if cur_cmd=PRINT then
    begin
      writeln('PL0: ip=',ip,' bp=',bp,' sp=',sp,' dp=',dp,' [sp]=',m[sp]);
      ip:=ip+1;
    end;
    if cur_cmd=READSP then
    begin
      sp:=sp+1;
      write('PL0 STACK='); readln(m[sp]); writeln('OK: ',m[sp]);
      ip:=ip+1;
    end;

    if cur_cmd=NOP then ip:=ip+1;

    if cur_cmd=SETDP then begin dp:=m[sp]; sp:=sp-1; ip:=ip+1; end;
    if cur_cmd=LOADDP then begin sp:=sp+1; m[sp]:=m[dp]; ip:=ip+1; end;
    if cur_cmd=STOREDP then begin m[dp]:=m[sp]; sp:=sp-1; ip:=ip+1; end;

    if cur_cmd=NEG then begin m[sp]:=-m[sp]; ip:=ip+1; end;
    if cur_cmd=ADD then begin sp:=sp-1; m[sp]:=m[sp]+m[sp+1]; ip:=ip+1; end;
    if cur_cmd=SUB then begin sp:=sp-1; m[sp]:=m[sp]-m[sp+1]; ip:=ip+1; end;
    if cur_cmd=MUL then begin sp:=sp-1; m[sp]:=m[sp]*m[sp+1]; ip:=ip+1; end;
    if cur_cmd=IDIV then begin sp:=sp-1; m[sp]:=m[sp] div m[sp+1]; ip:=ip+1; end;
    if cur_cmd=IMOD then begin sp:=sp-1; m[sp]:=m[sp] mod m[sp+1]; ip:=ip+1; end;
    if cur_cmd=CMPE then begin sp:=sp-1; m[sp]:=ord(m[sp]=m[sp+1]); ip:=ip+1; end;
    if cur_cmd=CMPNE then begin sp:=sp-1; m[sp]:=ord(m[sp]<>m[sp+1]); ip:=ip+1; end;
    if cur_cmd=CMPL then begin sp:=sp-1; m[sp]:=ord(m[sp]<m[sp+1]); ip:=ip+1; end;
    if cur_cmd=CMPG then begin sp:=sp-1; m[sp]:=ord(m[sp]>m[sp+1]); ip:=ip+1; end;
    if cur_cmd=CMPLE then begin sp:=sp-1; m[sp]:=ord(m[sp]<=m[sp+1]); ip:=ip+1; end;
    if cur_cmd=CMPGE then begin sp:=sp-1; m[sp]:=ord(m[sp]>=m[sp+1]); ip:=ip+1; end;

    if cur_cmd=LOADNUM then begin sp:=sp+1; m[sp]:=m[ip+1]; ip:=ip+2; end;

    if cur_cmd=LOAD then
    begin
      sp:=sp+1;
      m[sp]:=m[pl0_base_down(bp,m[ip+1],m)+m[ip+2]];
      ip:=ip+3;
    end;
    if cur_cmd=STORE then
    begin
      m[pl0_base_down(bp,m[ip+1],m)+m[ip+2]]:=m[sp];
      sp:=sp-1;
      ip:=ip+3;
    end;
    if cur_cmd=CALL then
    begin {формирование отметки в новом блоке}
      m[sp+1]:=pl0_base_down(bp,m[ip+1],m);
      m[sp+2]:=bp;
      m[sp+3]:=ip;
      bp:=sp+1;
      ip:=m[ip+2];
    end;
    if cur_cmd=INCSP then begin sp:=sp+m[ip+1]; ip:=ip+2; end;
    if cur_cmd=JMP then ip:=m[ip+1];
    if cur_cmd=JPC then
    begin
      if m[sp]=0 then ip:=m[ip+1];
      sp:=sp-1;
    end;
    if cur_cmd=RET then begin sp:=bp-1; ip:=m[sp+3]; bp:=m[sp+2]; end;
//    if cur_cmd=EXT then begin pl0_external_proc(ip,bp,sp,m); ip:=ip+1; end;
  until cur_cmd = HLT;
  write('END PL/O low level interpretator');
end; {pl0_interpretator}

var
    prg_table,token_table:t_token_table;
    prg_symbols_num,tokens_num:integer;
    i,goal,address:integer;
    match:boolean;
    pl0_mem:t_pl0_memory; pl0_addr:integer;

begin {main}

  //Построение структуры языка на основе порождающих правил Бэкуса-Наура
  writeln('reading lang.rbnf');
  tokens_num:=symbols_from_file('lang.rbnf',token_table);
  writeln('OK');

  writeln('check syntax and markup RBNF tokens');
  mark_tokens(tokens_num,token_table);
  for i:=1 to tokens_num do
  begin
    token_table[i].suc:=0;
    token_table[i].alt:=0;
    token_table[i].entry:=0;
  end;
  writeln('OK');

  writeln('RBNF tokens: ',tokens_num);
  for i:=1 to tokens_num do
      writeln(i:3,
              ': ',token_table[i].kind_sym:5,
              '  ',token_table[i].kind_toc:8,
              ' "',token_table[i].s_name,'"');
  writeln('===============================');

  writeln('generate RBNF syntax tree');
  gen_tokens_links(tokens_num,token_table);
  writeln('OK');

  writeln('RBNF links');
  for i:=1 to tokens_num do
      writeln(i:3,
              ': entry=',token_table[i].entry:3,
              ', suc=',token_table[i].suc:3,
              ', alt=',token_table[i].alt:3,
              ' ',token_table[i].kind_sym:5,
              ' ',token_table[i].kind_toc:8,
              ' "',token_table[i].s_name,'"');
  writeln('===============================');

  //загрузка транслируемой программы
  writeln('reading test_program.xxx');
  prg_symbols_num:=symbols_from_file('test_program.xxx',prg_table);
  writeln('OK');

  writeln('tokens of test program: ',prg_symbols_num);
  for i:=1 to prg_symbols_num do
      writeln(i,
              ': ',prg_table[i].kind_sym:5,
              ' "',prg_table[i].s_name,'"');
  writeln('===============================');

  //поиск точки входа: первое правило РБНФ
  goal:=1; while token_table[goal].kind_toc<>head do goal:=goal+1;
  writeln('goal: ',token_table[goal].s_name,', address=',goal);

  //проверка синтаксиса программы
  writeln('parse text by RBNF syntax tree');
  address:=1; match:=true;
  parse(1,goal,address,match,prg_symbols_num,tokens_num,prg_table,token_table,false);
  if match then writeln('CORRECT') else writeln('INCORRECT');

  //PL0_machine test
  for i:=0 to max_mem_size-1 do pl0_mem[i]:=0;
  pl0_addr:=pl0_gen_cmd(250,DUMP,0,1023,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,HLT,-1,-1,pl0_mem);
  pl0_addr:=0;

  pl0_addr:=pl0_gen_cmd(pl0_addr,LOADNUM,35,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,READSP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,LOADNUM,12,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,READSP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,SUB,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);

  pl0_addr:=pl0_gen_cmd(pl0_addr,LOADNUM,900,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,SETDP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,STOREDP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);

  pl0_addr:=pl0_gen_cmd(pl0_addr,LOADNUM,5,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,SETDP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,LOADDP,-1,-1,pl0_mem);
  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);

//  pl0_addr:=pl0_gen_cmd(pl0_addr,STORE,0,100,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,REGS,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,REGS,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,LOAD,0,100,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,REGS,-1,-1,pl0_mem);

//  pl0_addr:=pl0_gen_cmd(pl0_addr,ADDRIP,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,ADDRBP,-1,-1,pl0_mem);  
//  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,ADDRSP,-1,-1,pl0_mem);
//  pl0_addr:=pl0_gen_cmd(pl0_addr,PRINT,-1,-1,pl0_mem);

//  PL0_interpretator(0,800,512,pl0_mem);//PL0_interpretator(ip,bp,sp,mem);
end.
