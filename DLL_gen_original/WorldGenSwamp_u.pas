unit WorldGenSwamp_u;

interface

uses WorldGenerator_u, generation, RandomMCT;

type WorldGenSwamp=class(WorldGenerator)
     private
       procedure func_35265_a(xreg,yreg:integer; map:region; i,j,k,l:integer);
     public
       function generate(xreg,yreg:integer; map:region; rand:rnd; i,j,k:integer):boolean; override;
     end;

implementation

function WorldGenSwamp.generate(xreg,yreg:integer; map:region; rand:rnd; i,j,k:integer):boolean;
var l,i1,byte0,j2,j3,i4,t,j1,k1,k2,k3,j4,l4,k5,j5,l1,l2,i2,l3,i3,k4,i5:integer;
flag:boolean;
begin
  l:=rand.nextInt(4) + 5;
  t:=get_block_id(map,xreg,yreg,i,j-1,k);
  while ((t=8)or(t=9))and(j>=0) do
  begin
    dec(j);
    t:=get_block_id(map,xreg,yreg,i,j-1,k);
  end;
  flag:=true;
  if (j < 1)or(j + l + 1 > 128) then
  begin
    result:=false;
    exit;
  end;
  for i1:=j to j+1+l do
  begin
    byte0:=1;
    if (i1 = j) then byte0:=0;
    if (i1 >= (j + 1 + l) - 2)then byte0:=3;
    for j2:=i-byte0 to i+byte0 do
    begin
      if flag=false then break;
      for j3:=k-byte0 to k+byte0 do
      begin
        if flag=false then break;
        if (i1 >= 0)and(i1 < 128) then
        begin
          i4:=get_block_id(map,xreg,yreg,j2, i1, j3);
          if (i4 = 0)or(i4 = 18) then continue;
          if (i4 = 8)or(i4 = 9) then
          begin
            if (i1 > j) then flag:=false;
          end
          else flag:=false;
        end
        else flag:=false;
      end;
    end;
  end;

  if flag=false then
  begin
    result:=false;
    exit;
  end;
  j1:=get_block_id(map,xreg,yreg,i, j - 1, k);
  if (j1 <> 2)and(j1 <> 3)or(j >= 128 - l - 1) then
  begin
    result:=false;
    exit;
  end;
  set_block_id(map,xreg,yreg,i, j - 1, k, 3);

  for k1:=(j - 3) + l to j+l do
  begin
    k2:=k1 - (j + l);
    k3:=2 - k2 div 2;
    for j4:=i-k3 to i+k3 do
    begin
      l4:=j4 - i;
      for j5:=k-k3 to k+k3 do
      begin
        k5:=j5 - k;
        if (((abs(l4) <> k3)or(abs(k5) <> k3)or(rand.nextInt(2) <> 0)and(k2 <> 0))and(get_block_id(map,xreg,yreg,j4, k1, j5)in trans_bl))then
          set_block_id(map,xreg,yreg,j4, k1, j5, 18);
      end;
    end;
  end;

  for l1:=0 to l-1 do
  begin
    l2:=get_block_id(map,xreg,yreg,i, j + l1, k);
    if (l2 = 0)or(l2 = 18)or(l2 = 8)or(l2 = 9) then
      set_block_id(map,xreg,yreg,i, j + l1, k, 17);
  end;

  for i2:=(j - 3) + l to j+l do
  begin
    i3:=i2 - (j + l);
    l3:=2 - i3 div 2;
    for k4:=i-l3 to i+l3 do
      for i5:=k-l3 to k+l3 do
      begin
        if (get_block_id(map,xreg,yreg,k4, i2, i5) <> 18) then continue;
        if (rand.nextInt(4) = 0)and(get_block_id(map,xreg,yreg,k4 - 1, i2, i5) = 0) then
          func_35265_a(xreg,yreg,map, k4 - 1, i2, i5, 8);
        if (rand.nextInt(4) = 0)and(get_block_id(map,xreg,yreg,k4 + 1, i2, i5) = 0) then
          func_35265_a(xreg,yreg,map, k4 + 1, i2, i5, 2);
        if (rand.nextInt(4) = 0)and(get_block_id(map,xreg,yreg,k4, i2, i5 - 1) = 0) then
          func_35265_a(xreg,yreg,map, k4, i2, i5 - 1, 1);
        if (rand.nextInt(4) = 0)and(get_block_id(map,xreg,yreg,k4, i2, i5 + 1) = 0) then
          func_35265_a(xreg,yreg,map, k4, i2, i5 + 1, 4);
      end;
  end;

  result:=true;
end;

procedure WorldGenSwamp.func_35265_a(xreg,yreg:integer; map:region; i,j,k,l:integer);
var i1:integer;
begin
  set_block_id_data(map,xreg,yreg,i, j, k, 106, l);
  for i1:=4 downto 1 do
  begin
    dec(j);
    if get_block_id(map,xreg,yreg,i, j, k) <> 0 then break;
      set_block_id_data(map,xreg,yreg,i, j, k, 106, l); 
  end;
end;

end.
