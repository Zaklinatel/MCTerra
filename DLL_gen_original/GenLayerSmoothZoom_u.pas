unit GenLayerSmoothZoom_u;

interface

uses GenLayer_u, generation;

type GenLayerSmoothZoom=class(GenLayer)
     public
       constructor Create(l:int64; gen:GenLayer);
       destructor Destroy; override;
       function getInts(i,j,k,l:integer):ar_int; override;
       function func_35517_a(l:int64; gen:GenLayer; i:integer; save_layers:par_GenLayer):GenLayer;
     end;

implementation

uses IntCache_u;

constructor GenLayerSmoothZoom.Create(l:int64; gen:GenLayer);
begin
  inherited Create(l);
  parent:=gen;
end;

destructor GenLayerSmoothZoom.Destroy;
begin
  //if parent<>nil then parent.Free;
  //parent:=nil;
  inherited;
end;

function GenLayerSmoothZoom.getInts(i,j,k,l:integer):ar_int;
var i1,j1,k1,l1,i2,j2,k2,i3,j3,k3,l3,i4,j4,k4,l4,l2:integer;
ai,ait:ar_int;
ai1,ai2:par_int;
begin
  i1:=shrr(i,1);
  j1:=shrr(j,1);
  k1:=shrr(k,1) + 3;
  l1:=shrr(l,1) + 3;
  ai:=parent.getInts(i1, j1, k1, l1);
  ai1:=IntCache_u.getIntCache(k1 * 2 * (l1 * 2));
  i2:=shll(k1,1);
  for j2:=0 to l1-2 do
  begin
    k2:=shll(j2,1);
    i3:=k2 * i2;
    j3:=ai[0 + (j2 + 0) * k1];
    k3:=ai[0 + (j2 + 1) * k1];
    for l3:=0 to k1-2 do
    begin
      initChunkSeed(shll(l3 + i1,1), shll(j2 + j1,1));
      i4:=ai[l3 + 1 + (j2 + 0) * k1];
      j4:=ai[l3 + 1 + (j2 + 1) * k1];
      ai1^[i3]:=j3;
      ai1^[i3 + i2]:=j3 + ((k3 - j3) * nextInt(256)) div 256;
      inc(i3);
      ai1^[i3]:=j3 + ((i4 - j3) * nextInt(256)) div 256;
      k4:=j3 + ((i4 - j3) * nextInt(256)) div 256;
      l4:=k3 + ((j4 - k3) * nextInt(256)) div 256;
      ai1^[i3 + i2]:=k4 + ((l4 - k4) * nextInt(256)) div 256;
      inc(i3);
      j3:=i4;
      k3:=j4;
    end;
  end;

  setlength(ait,length(ai1^));
  move(ai1^[0],ait[0],length(ai1^)*sizeof(integer));

  ai2:=IntCache_u.getIntCache(k * l);
  for l2:=0 to l-1 do
    //System.arraycopy(ai1, (l2 + (j & 1)) * (k1 << 1) + (i & 1), ai2, l2 * k, k);
    //move(ai1^[(l2 + (j and 1)) * (shll(k1,1)) + (i and 1)],ai2^[l2 * k],k*sizeof(integer));
    move(ait[(l2 + (j and 1)) * (shll(k1,1)) + (i and 1)],ai2^[l2 * k],k*sizeof(integer));

  setlength(ait,0);

  result:=ai2^;
end;

function GenLayerSmoothZoom.func_35517_a(l:int64; gen:GenLayer; i:integer; save_layers:par_GenLayer):GenLayer;
var obj:GenLayer;
j,t:integer;
begin
  obj:=gen;
  for j:=0 to i-1 do
  begin
    obj:=GenLayerSmoothZoom.Create(l+j,obj);
    t:=length(save_layers^);
    setlength(save_layers^,t+1);
    save_layers^[t]:=obj;
  end;

  result:=obj;
end;

end.
