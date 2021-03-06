unit GenLayerRiverInit_u;

interface

uses GenLayer_u, generation;

type GenLayerRiverInit=class(GenLayer)
     public
       constructor Create(l:int64; gen:GenLayer);
       destructor Destroy; override;
       function getInts(i,j,k,l:integer):ar_int; override;
     end;

implementation

uses IntCache_u;

constructor GenLayerRiverInit.Create(l:int64; gen:GenLayer);
begin
  inherited Create(l);
  parent:=gen;
end;

destructor GenLayerRiverInit.Destroy;
begin
  //if parent<>nil then parent.Free;
  //parent:=nil;
  inherited;
end;

function GenLayerRiverInit.getInts(i,j,k,l:integer):ar_int;
var ai:ar_int;
ai1:par_int;
i1,j1:integer;
begin
  ai:=parent.getInts(i, j, k, l);
  ai1:=IntCache_u.getIntCache(k * l);
  for i1:=0 to l-1 do
    for j1:=0 to k-1 do
    begin
      initChunkSeed(j1 + i, i1 + j);
      if(ai[j1 + i1 * k] <= 0)then ai1^[j1 + i1 * k]:=0
      else ai1^[j1 + i1 * k]:=nextInt(2) + 2;
    end;
  result:=ai1^;
end;

end.
