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

unit rbnf_gen;

interface
uses token_utils,sym_scanner,rbnf_scanner;

procedure gen_tokens_links(tokens_num:integer; var token_table:t_token_table);

implementation
//k - enter token address
//p - parent ident address
//q - exit ident address
//pp - first ident exit

function term_gen(k,p:integer;var q,pp:integer;
        tokens_num:integer; var token_table:t_token_table):integer; forward;

// factor ::= <symbol> | [<term>] | [<term>!]
function factor_gen(k,p:integer;var q,pp:integer;
               tokens_num:integer; var token_table:t_token_table):integer;
begin
  k:=skip_nul(k,tokens_num,token_table);
  if (token_table[k].s_name='[')and
     (token_table[k].kind_toc=meta) then
  begin
    k:=term_gen(k+1,p,q,pp,tokens_num,token_table);
    if (token_table[k].s_name=']')and
       (token_table[k].kind_toc=meta) then
    begin
      token_table[pp].alt:=-1;
      token_table[q].suc:=pp;
    end;
    if (token_table[k].s_name='!]')and
       (token_table[k].kind_toc=meta) then token_table[pp].alt:=-1;
  end else
  begin
    if token_table[k].kind_toc=meta then k:=skip_nul(k+1,tokens_num,token_table);
    q:=k; pp:=k;
  end;
  factor_gen:=k+1;
end; {factor_gen}

// term ::= <factor> {<factor>}
function term_gen(k,p:integer;var q,pp:integer;
               tokens_num:integer; var token_table:t_token_table):integer;
var flag,flag_quad:boolean; tmp,ppp:integer;
begin
  flag:=true; flag_quad:=false;
  repeat
    k:=skip_nul(k,tokens_num,token_table);
    k:=factor_gen(k,p,q,pp,tokens_num,token_table);
    if flag_quad then begin flag_quad:=false; token_table[ppp].alt:=pp; end;
    if token_table[pp].alt=-1 then begin flag_quad:=true; ppp:=pp; end;
    if (token_table[p].suc=0)and not(flag) then token_table[p].suc:=pp;
    if flag=true then begin flag:=false; tmp:=pp; end;
    p:=q;
    k:=skip_nul(k,tokens_num,token_table);
  until ((token_table[k].s_name='.')or
         (token_table[k].s_name=',')or
         (token_table[k].s_name='|')or
         (token_table[k].s_name='!]')or
         (token_table[k].s_name=']')
        ) and (token_table[k].kind_toc=meta);
  pp:=tmp;
  term_gen:=k;
end; {term_gen}

// expression ::= <term> {,<term>}
function expression_gen(k,p:integer;var q,pp:integer;
               tokens_num:integer; var token_table:t_token_table):integer;
var flag:boolean; tmp:integer;
begin
  flag:=true;
  repeat
    if ((token_table[k].s_name=',')or(token_table[k].s_name='|'))
       and(token_table[k].kind_toc=meta) then k:=k+1;
    k:=skip_nul(k,tokens_num,token_table);
    k:=term_gen(k,p,q,pp,tokens_num,token_table);
    if not(flag) then token_table[p].alt:=pp;
    if flag=true then begin flag:=false; tmp:=pp; end;
    p:=pp;
  until ((token_table[k].s_name<>',')and(token_table[k].s_name<>'|'))
         or(token_table[k].kind_toc<>meta);
  pp:=tmp;
  k:=skip_nul(k,tokens_num,token_table);
  expression_gen:=k;
end; {expression_gen}

procedure gen_tokens_links(tokens_num:integer; var token_table:t_token_table);
var k,kk,q,pp,kk1,kk2:integer; flag:boolean;
begin
  flag:=false;
  for k:=1 to tokens_num do
  begin
    if token_table[k].kind_toc=head then begin flag:=true; kk:=k; end;
    if ((token_table[k].kind_toc=terminal)or
        (token_table[k].kind_toc=non_term)
       )and flag then
    begin
      flag:=false;
      token_table[kk].entry:=k;
    end;
    if token_table[k].kind_toc=non_term then
       token_table[k].entry:=find_start_of_expression(token_table[k].s_name,tokens_num,token_table);
  end;

  k:=1;
  while k<tokens_num do
  begin
    while (token_table[k].s_name='//')or
          (token_table[k].s_name='#') do
    begin
      repeat
        k:=k+1;
      until (token_table[k].s_name='LF')or(k=tokens_num);
    end;

    while (token_table[k].kind_toc<>head)and(k<tokens_num) do k:=k+1;

    if k<tokens_num then
    begin
       k:=skip_nul(k+1,tokens_num,token_table);
       k:=skip_nul(k+1,tokens_num,token_table);
       k:=expression_gen(k,token_table[k].entry,q,pp,tokens_num,token_table);
       k:=skip_nul(k+1,tokens_num,token_table);
    end;
  end;

  for k:=1 to tokens_num do
  begin
    if token_table[k].kind_toc=head then
    begin
      kk1:=k; kk2:=k; kk:=token_table[k].entry;
      repeat
        kk2:=kk2+1;
      until ((token_table[kk2].s_name=token_table[kk1].s_name)and
             (token_table[kk2].kind_toc=head)
            )or(kk2=tokens_num);

      repeat
        kk1:=kk1+1;
      until (token_table[kk1].kind_toc=head)or(kk1=tokens_num);
      repeat
        kk1:=kk1-1;
      until ((token_table[kk1].kind_toc=meta)and
             ((token_table[kk1].s_name=',')or(token_table[kk1].s_name='|'))
            ) or (kk1=kk);
      while (token_table[kk1].kind_toc<>terminal)and
            (token_table[kk1].kind_toc<>non_term) do kk1:=kk1+1;

      if kk2<tokens_num then token_table[kk1].alt:=token_table[kk2].entry;
    end;
  end;
end; {gen_tokens_links}

begin
end.
