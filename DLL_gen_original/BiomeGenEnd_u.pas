unit BiomeGenEnd_u;

interface

uses BiomeGenBase_u;

type BiomeGenEnd=class(BiomeGenBase)
     public
       constructor Create(i:integer); override;
     end;

implementation

constructor BiomeGenEnd.Create(i:integer);
begin
  inherited Create(i);
  topBlock:=3;
  fillerBlock:=3;
  //todo: dopisat' biome decorator
end;

end.
