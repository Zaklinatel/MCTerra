unit GenLayerMushroomIsland_u;

interface

uses GenLayer_u, generation;

type GenLayerMushroomIsland=class(GenLayer)
     public
       constructor Create(l:int64; gen:GenLayer);
       destructor Destroy; override;
       function getInts(i,j,k,l:integer):ar_int; override;
     end;

implementation

uses IntCache_u, BiomeGenBase_u;

constructor GenLayerMushroomIsland.Create(l:int64; gen:GenLayer);
begin
  inherited Create(l);
  parent:=gen;
end;

destructor GenLayerMushroomIsland.Destroy;
begin
  //if parent<>nil then parent.Free;
  //parent:=nil;
  inherited;
end;

function GenLayerMushroomIsland.getInts(i,j,k,l:integer):ar_int;
var i1,j1,k1,l1,i2,j2,k2,l2,i3,j3,k3:integer;
ai:ar_int;
ai1:par_int;
begin
  i1:=i - 1;
  j1:=j - 1;
  k1:=k + 2;
  l1:=l + 2;
  ai:=parent.getInts(i1, j1, k1, l1);
  ai1:=IntCache_u.getIntCache(k * l);
  for i2:=0 to l-1 do
    for j2:=0 to k-1 do
    begin
      k2:=ai[j2 + 0 + (i2 + 0) * k1];
      l2:=ai[j2 + 2 + (i2 + 0) * k1];
      i3:=ai[j2 + 0 + (i2 + 2) * k1];
      j3:=ai[j2 + 2 + (i2 + 2) * k1];
      k3:=ai[j2 + 1 + (i2 + 1) * k1];
      initChunkSeed(j2 + i, i2 + j);
      if (k3 = 0)and(k2 = 0)and(l2 = 0)and(i3 = 0)and(j3 = 0)and(nextInt(100) = 0)then
        ai1^[j2 + i2 * k]:=BiomeGenBase_u.mushroomIsland_b.biomeID
      else
        ai1^[j2 + i2 * k]:=k3;
    end;

  result:=ai1^;
end;

end.
