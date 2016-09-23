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

{проверка синтаксиса программы языка на основе форм Бэкуса-Наура}
unit uni_parser;
interface
uses token_utils, sym_scanner, rbnf_scanner, rbnf_gen;
procedure parse(level,goal:integer;
                var cur_sym:integer;
                var match:boolean;
                prg_symbols_num,tokens_num:integer;
                var prg_table,token_table:t_token_table;
                parent_exclude:boolean);

implementation
//разбор соответствия входного потока символов правилам языка
procedure parse(level,goal:integer;
                var cur_sym:integer;
                var match:boolean;
                prg_symbols_num,tokens_num:integer;
                var prg_table,token_table:t_token_table;
                parent_exclude:boolean);
var s:integer; exclude,alter_exit:boolean; sem_token_idx:integer;
begin
  exclude:=false; sem_token_idx:=0;
  s:=token_table[goal].entry;
  writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,' entry ',s);
  repeat

    while copy(token_table[s].s_name,1,4)='SEM_' do
    begin
      sem_token_idx:=s;
      if token_table[s].s_name='SEM_DONE' then sem_token_idx:=0;
      writeln('SEMANTIC_TOKEN AT ',s,': ',token_table[s].s_name);
      s:=token_table[s].suc;
    end;

    alter_exit:=false;
    if token_table[s].s_name='EXCLUDE_ON' then
    begin
      writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':EXCLUDE_ON:',token_table[s].suc,':',token_table[s].alt);
      exclude:=true;
      parent_exclude:=true;
      s:=token_table[s].suc;
    end;

    if token_table[s].s_name='EXCLUDE_OFF' then
    begin
      writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':EXCLUDE_OFF:',token_table[s].suc,':',token_table[s].alt);
      exclude:=false;
      parent_exclude:=false;
      s:=token_table[s].suc;
      cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);
    end;

    if (s>0)and(cur_sym<=prg_symbols_num) then
    begin
      if (token_table[s].kind_toc=terminal) then
      begin
        write('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':"',token_table[s].s_name,'":',token_table[s].suc,':',token_table[s].alt);
        if token_table[s].s_name<>'EMPTY' then write(' = "',prg_table[cur_sym].s_name,'":',cur_sym);
        if exclude then match:=(token_table[s].s_name<>prg_table[cur_sym].s_name)
        else
        begin
          if (token_table[s].s_name='ANY')or
             ((token_table[s].s_name='NUMBER')and(prg_table[cur_sym].kind_sym=num))or
             ((token_table[s].s_name='IDENT')and(prg_table[cur_sym].kind_sym=ident))or
             ((token_table[s].s_name='OPER')and(prg_table[cur_sym].kind_sym=oper))or
             ((token_table[s].s_name='NULL')and(prg_table[cur_sym].kind_sym=nul))or
             ((token_table[s].s_name='ONE_ANY_CHAR')and(length(prg_table[cur_sym].s_name)=1))or
             (token_table[s].s_name='EMPTY')or
             (token_table[s].s_name=prg_table[cur_sym].s_name) then
          begin
            match:=true;
            if token_table[s].s_name<>'EMPTY' then
               if not(parent_exclude) then
               begin
                 if match and (sem_token_idx>0) then
                    writeln(' SEMANTIC DECODE: ',token_table[sem_token_idx].s_name,'="',prg_table[cur_sym].s_name,'"');
                 cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);
               end;
          end else
          if token_table[s].alt=-1 then
          begin
            match:=true; alter_exit:=true;
          end else match:=false;
        end;
        if not(alter_exit) then writeln(' ',match) else writeln(' ALTER_EXIT');
      end else
      begin
        writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
                ' ',s,':"',token_table[token_table[s].entry].s_name,'"-->',token_table[s].entry,' NON_TERMINAL');
        parse(level+1,token_table[s].entry,cur_sym,match,prg_symbols_num,tokens_num,prg_table,token_table,parent_exclude);
        if exclude then match:=not(match);
        if match and (sem_token_idx>0) then
           writeln(' SEMANTIC DECODE: ',token_table[sem_token_idx].s_name,'="',prg_table[cur_sym].s_name,'"');
      end;
      if match then s:=token_table[s].suc else s:=token_table[s].alt;
      if s<0 then match:=true;
      if alter_exit then s:=0;
//      if s<0 then s:=0;
    end;
  until (s<=0)or(alter_exit)or(cur_sym>prg_symbols_num);
  writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,' ',match);
end; {parse}

begin
end.
