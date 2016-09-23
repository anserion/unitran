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

unit sym_scanner;

interface
uses token_utils;

function symbols_from_file(f: string;var token_table:t_token_table):integer;

implementation

var ch,ch2: char;
    start_of_file, end_of_file, real_end_of_file:boolean;

procedure getch(var f:t_charfile; var ch,ch2:char);
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(f) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; real_end_of_file:=true; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(f,ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(f,ch); start_of_file:=false;
     if not(eof(f)) then read(f,ch2) else ch2:=' ';
  end;
end {getch};

function getsym(var f:t_charfile):t_token;
var id: t_token; tmp,tmp2:integer;
begin {getsym}
  id.s_name:='';
  id.kind_sym:=nul;

  if (ch='#')and(ch2 in digits+['A','B','C','D','E','F']) then
  begin
    id.kind_sym:=oper;
    getch(f,ch,ch2);
    tmp:=ord(ch)-ord('0');
    if ch in ['A','B','C','D','E','F'] then tmp:=ord(ch)-ord('A')+10;
    tmp2:=-1;
    if (ch2 in digits+['A','B','C','D','E','F']) then
    begin
      tmp2:=ord(ch2)-ord('0');
      if ch2 in ['A','B','C','D','E','F'] then tmp2:=ord(ch2)-ord('A')+10;
      if not(end_of_file) then getch(f,ch,ch2);
    end;
    if tmp2<0 then id.s_name:=chr(tmp) else id.s_name:=chr(tmp*16+tmp2);
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if ch='''' then
  begin
    id.kind_sym:=ident;
    id.s_name:='';
    getch(f,ch,ch2);
    while (ch<>'''')and not(end_of_file) do
    begin
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    end;
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if ch='"' then
  begin
    id.kind_sym:=ident;
    id.s_name:='';
    getch(f,ch,ch2);
    while (ch<>'"')and not(end_of_file) do
    begin
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    end;
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if ch=':' then
  begin
    id.kind_sym:=oper;
    id.s_name:=':';
    if ch2=':' then
    begin
      id.s_name:='::';
      if not(end_of_file) then getch(f,ch,ch2);
      if ch2='=' then
      begin
        id.s_name:='::=';
        if not(end_of_file) then getch(f,ch,ch2);
      end;
    end else
    if ch2='=' then
    begin
      id.s_name:=':=';
      if not(end_of_file) then getch(f,ch,ch2);
    end;
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if (ch in ['_']+eng_letters+rus_cp1251_letters) then
  begin
    id.kind_sym:=ident;
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until not(ch in ['_']+eng_letters+digits+rus_cp1251_letters) or end_of_file;
    if (ch in ['_']+eng_letters+digits+rus_cp1251_letters) and end_of_file then
       id.s_name:=id.s_name+ch;
  end
    else
  if ch in digits then
  begin
    id.kind_sym:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until not(ch in digits) or end_of_file;
    if (ch in digits) and end_of_file then id.s_name:=id.s_name+ch;
    if (ch='.')and(ch2 in digits) then
    begin
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
      repeat
        id.s_name:=id.s_name+ch;
        getch(f,ch,ch2);
      until not(ch in digits) or end_of_file;
      if (ch in digits) and end_of_file then id.s_name:=id.s_name+ch
    end;
  end
    else
  if ch in spec_letters then
  begin
    id.kind_sym:=oper;
    id.s_name:=ch;
    if (ch='-')and(ch2='>') then begin id.s_name:='->'; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='-') then begin id.s_name:='<-'; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='>') then begin id.s_name:='<>'; getch(f,ch,ch2); end;
    if (ch='!')and(ch2='=') then begin id.s_name:='!='; getch(f,ch,ch2); end;
    if (ch='!')and(ch2=']') then begin id.s_name:='!]'; getch(f,ch,ch2); end;
    if (ch='=')and(ch2='=') then begin id.s_name:='=='; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='=') then begin id.s_name:='<='; getch(f,ch,ch2); end;
    if (ch='>')and(ch2='=') then begin id.s_name:='>='; getch(f,ch,ch2); end;
    if (ch='(')and(ch2='*') then begin id.s_name:='(*'; getch(f,ch,ch2); end;
    if (ch='*')and(ch2=')') then begin id.s_name:='*)'; getch(f,ch,ch2); end;
    if (ch='+')and(ch2='+') then begin id.s_name:='++'; getch(f,ch,ch2); end;
    if (ch='-')and(ch2='-') then begin id.s_name:='--'; getch(f,ch,ch2); end;
    if (ch='*')and(ch2='*') then begin id.s_name:='**'; getch(f,ch,ch2); end;
    if (ch='.')and(ch2='.') then begin id.s_name:='..'; getch(f,ch,ch2); end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch(f,ch,ch2); end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch(f,ch,ch2); end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch(f,ch,ch2); end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch(f,ch,ch2); end;
    if (ch='''')and(ch2='''') then begin id.s_name:=''''''; getch(f,ch,ch2); end;
//    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch(f,ch,ch2); end;
//    if (ch=':')and(ch2='=') then begin id.s_name:=':='; getch(f,ch,ch2); end;
//    if (ch='"')and(ch2='"') then begin id.s_name:='""'; getch(f,ch,ch2); end;
//    if (ch='[')and(ch2=']') then begin id.s_name:='[]'; getch(f,ch,ch2); end;

    if ch='\' then begin id.s_name:='\'+ch2; getch(f,ch,ch2); end;
    if (ch='\')and(ch2='\') then begin id.s_name:='\'; getch(f,ch,ch2); end;

    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  begin
    id.s_name:=ch;
    id.kind_sym:=nul;
    if ch=chr(01) then id.s_name:='SOH';
    if ch=chr(02) then id.s_name:='STX';
    if ch=chr(03) then id.s_name:='ETX';
    if ch=chr(04) then id.s_name:='EOT';
    if ch=chr(05) then id.s_name:='ENQ';
    if ch=chr(06) then id.s_name:='ACK';
    if ch=chr(07) then id.s_name:='BEL';
    if ch=chr(08) then id.s_name:='BS';
    if ch=chr(09) then id.s_name:='TAB';
    if ch=chr(10) then id.s_name:='LF';
    if ch=chr(11) then id.s_name:='VT';
    if ch=chr(12) then id.s_name:='FF';
    if ch=chr(13) then id.s_name:='CR';
    if ch=chr(14) then id.s_name:='SO';
    if ch=chr(15) then id.s_name:='SI';
    if ch=chr(16) then id.s_name:='DLE';
    if ch=chr(17) then id.s_name:='DC1';
    if ch=chr(18) then id.s_name:='DC2';
    if ch=chr(19) then id.s_name:='DC3';
    if ch=chr(20) then id.s_name:='DC4';
    if ch=chr(21) then id.s_name:='NAK';
    if ch=chr(22) then id.s_name:='SYN';
    if ch=chr(23) then id.s_name:='ETB';
    if ch=chr(24) then id.s_name:='CAN';
    if ch=chr(25) then id.s_name:='EM';
    if ch=chr(26) then id.s_name:='SUB';
    if ch=chr(27) then id.s_name:='ESC';
    if ch=chr(28) then id.s_name:='FS';
    if ch=chr(29) then id.s_name:='GS';
    if ch=chr(30) then id.s_name:='RS';
    if ch=chr(31) then id.s_name:='US';
    if ch=chr(32) then id.s_name:='SPACE';
    if not(end_of_file) then getch(f,ch,ch2);
  end;
//  writeln('symbol: ',id.s_name);
  getsym:=id;
end {getsym};
//==================================================================

function symbols_from_file(f: string;var token_table:t_token_table):integer;
var ff:t_charfile; sym:t_token; symbols_num:integer;
begin
  start_of_file:=true; end_of_file:=false; real_end_of_file:=false;
  ch:=' '; ch2:=' ';
  symbols_num:=0;
  assign(ff,f);
  reset(ff);
  getch(ff,ch,ch2); sym:=getsym(ff);

  while (sym.s_name<>'end_of_file') do
  begin
//    writeln(sym.s_name);
    symbols_num:=symbols_num+1;
    token_table[symbols_num]:=sym;
    sym:=getsym(ff);
  end;
  close(ff);
  symbols_from_file:=symbols_num;
end;

begin
end.
