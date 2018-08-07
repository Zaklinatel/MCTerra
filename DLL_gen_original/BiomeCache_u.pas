unit BiomeCache_u;

interface

uses WorldChunkManager_u, LongHashMap_u, BiomeCacheBlock_u, BiomeGenBase_u;

type BiomeCache=class(TObject)
     private
       chunkmanager:WorldChunkManager;
       lastCleanupTime:int64;
       cacheMap:LongHashMap;
       save_cacheblock:ar_BiomeCacheBlock;
     public
       constructor Create(man:WorldChunkManager);
       destructor Destroy; override;
       function getBiomeCacheBlock(i,j:integer):BiomeCacheBlock;
       function getBiomeGenAt(i,j:integer):BiomeGenBase;
       function getTemperature(i,j:integer):double;
       function getRainfall(i,j:integer):double;
       function getCachedBiomes(i,j:integer):ar_BiomeGenBase;
       function getWorldChunkManager(cache:BiomeCache):WorldChunkManager;
     end;

implementation

uses generation, windows;

constructor BiomeCache.Create(man:WorldChunkManager);
begin
  lastCleanupTime:=0;
  cacheMap:=LongHashMap.Create;
  chunkmanager:=man;
  setlength(save_cacheblock,0);
end;

destructor BiomeCache.Destroy;
var t:integer;
begin
  cachemap.Free;
  for t:=0 to length(save_cacheblock)-1 do
    save_cacheblock[t].Free;
  setlength(save_cacheblock,0);
  inherited;
end;

function BiomeCache.getBiomeCacheBlock(i,j:integer):BiomeCacheBlock;
var l:int64;
cacheblock:BiomeCacheBlock;
t:integer;
begin
  i:=shrr(i,4);
  j:=shrr(j,4);
  l:=(i and $ffffffff) or shll((j and $ffffffff),32);
  cacheblock:=BiomeCacheBlock(cacheMap.getValueByKey(l));
  if (cacheblock = nil)then
  begin
    cacheblock:=BiomeCacheBlock.Create(self, i, j);
    t:=length(save_cacheblock);
    setlength(save_cacheblock,t+1);
    save_cacheblock[t]:=cacheblock;
    cacheMap.add(l, cacheblock);
  end;
  cacheblock.lastAccessTime:=gettickcount;
  result:=cacheblock;
end;

function BiomeCache.getBiomeGenAt(i,j:integer):BiomeGenBase;
begin
  result:=getBiomeCacheBlock(i, j).getBiomeGenAt(i, j);
end;

function BiomeCache.getTemperature(i,j:integer):double;
begin
  result:=getBiomeCacheBlock(i, j).getTemperature(i, j);
end;

function BiomeCache.getRainfall(i,j:integer):double;
begin
  result:=getBiomeCacheBlock(i, j).getRainfall(i, j);
end;

function BiomeCache.getCachedBiomes(i,j:integer):ar_BiomeGenBase;
begin
  result:=getBiomeCacheBlock(i, j).biomes;
end;

function BiomeCache.getWorldChunkManager(cache:BiomeCache):WorldChunkManager;
begin
  result:=cache.chunkmanager;
end;

end.
