unit WorldGenFlowers_u;

interface

uses WorldGenerator_u, generation, RandomMCT;

type WorldGenFlowers=class(WorldGenerator)
     private
       plantBlockId:integer;
     public
       constructor Create(i:integer);
       function generate(xreg,yreg:integer; map:region; rand:rnd; i,j,k:integer):boolean; override;
     end;

implementation

constructor WorldGenFlowers.Create(i:integer);
begin
  plantBlockId:=i;
end;

function WorldGenFlowers.generate(xreg,yreg:integer; map:region; rand:rnd; i,j,k:integer):boolean;
var l,i1,j1,k1,t:integer;
begin
  for l:=0 to 63 do
  begin
    i1:=(i + rand.nextInt(8)) - rand.nextInt(8);
    j1:=(j + rand.nextInt(4)) - rand.nextInt(4);
    k1:=(k + rand.nextInt(8)) - rand.nextInt(8);
    t:=get_block_id(map,xreg,yreg,i1, j1-1, k1);
    if (get_block_id(map,xreg,yreg,i1, j1, k1)=0)and((t=3)or(t=2)or(t=60)) then
      set_block_id(map,xreg,yreg,i1, j1, k1, plantBlockId);
  end;

  result:=true;
end;

end.
