program test_pascal(input,output);
label 10,20,30;
const a=xxx; b=45; cc=1.3e-5.2;
type t1=integer;
     t2=real;
     t2= 7..15;
     t3= (a,b,c);
     t4= ^integer;
     t5= array [1..5] of integer;
     t6= file of packed array [integer] of real;
     t7= set of 2..10;
     t8=record
           end;
     t9=record x,y,z: real;
               a,b,c: packed array[-5..12]of record x,y:integer; end;
            end;
     t10=record
              case f:boolean of
               true: (a,b,c:integer);
               false: (x,y,z: real);
            end;
var x,y,z:integer;
    m: array[1..10]of real;

procedure xxx(a,b,c:integer);
begin
end;

procedure yyy(var x,y,z:real; a,v:integer);
begin
end;

function fff(function b,f:real; var m:boolean; x:real):real;
begin
end;

begin
10: ;
20: ;
 begin end;
 goto 15;
 with a,b,c do begin end;
 with x,y,z do ;
 for v1:=1 to 5 do ;
 repeat until true;
 repeat goto 15; begin end; until false;
 while true do begin goto 10; for v2:=5 downto 2 do ; end;
 if true then begin end;
 if false then begin end else goto 20;
 p1;
  p2(a,b+2*(x-f1),c,10);
 a:=5;
 b:=5>3;
 c:=e in d;
 f:=-9+a;
 g:=+pppp or xxx;
 h:=a*9;
 k:=not(a+n*3/2+11)/7+(17 div 3)- 5 mod 10;
 y:=[a,b,c, 2..9];
 f2:=17+ not(a-3*f4(a,x,4+7*r));
 x:=v5[12];
 u:=v4^.x;
 v:=v7[11].y[6+2*a];
 t:=v1.r^;

 case v1 of
  1: p1;
  2: p2;
 end;

end.
end_of_file
