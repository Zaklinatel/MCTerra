unit generation;

interface

const PROTOCOL_DLL = 5;
WM_USER = $0400;

type byte_ar = array of byte;
     int_ar = array of integer;
     
     TPlugRec = record
       size_info:integer;
       size_flux:integer;
       size_gen_settings:integer;
       size_chunk:integer;
       size_change_block:integer;
       data:pointer;
     end;

     TPlugSettings = packed record
       plugin_type:byte;
       aditional_type:byte;
       full_name:PChar;
       name:PChar;
       author:PChar;
       dll_path:PChar;
       maj_v, min_j, rel_v:byte; //version
       change_par:array[1..21] of boolean;
       has_preview:boolean;
     end;

     TFlux_set = record
       available:Boolean;
       min_max:boolean;
       default:int64;
       min:int64;
       max:int64;
     end;

     TPlayer_settings = record
       XP_level:integer;
       XP:single;
       HP:integer;
       Food_level:integer;
       Score:integer;
       Rotation:array[0..1] of single;
       Overrite_pos:Boolean;
       Pos:array[0..2] of double;
       Floating:Boolean;
     end;

     TGen_settings = record
       Border_gen:TPlugRec;
       Buildings_gen:TPlugRec;
       Landscape_gen:TPlugRec;
       Path:PChar;
       Name:PChar;
       Map_type:byte;
       Width,Length:integer;
       border_in,border_out:integer;
       Game_type:integer;
       SID:int64;
       Populate_chunks:Boolean;
       Generate_structures:Boolean;
       Game_time:integer;
       Raining, Thundering:Boolean;
       Rain_time, Thunder_time:integer;
       Player:TPlayer_settings;
       Files_size:int64;
       Spawn_pos:array[0..2] of integer;
     end;

     TEntity_type = record
       Id:string;
       Pos:array[0..2] of double;
       Motion:array[0..2] of double;
       Rotation:array[0..1] of single;
       Fall_distance:single;
       Fire:smallint;
       Air:smallint;
       On_ground:Boolean;
       Data:pointer;
     end;

     TTile_entity_type = record
       Id:string;
       x,y,z:integer;
       data:pointer;
     end;   

     TGen_chunk = record
       Biomes:byte_ar;
       Blocks:byte_ar;
       Data:byte_ar;
       Light:byte_ar;
       Skylight:byte_ar;
       Heightmap:int_ar;
       Has_additional_id:Boolean;
       sections:array[0..15] of boolean;
       Add_id:byte_ar;
       has_skylight,has_blocklight:boolean;
       raschet_skylight:boolean;
       Entities:array of TEntity_type;
       Tile_entities:array of TTile_entity_type;
     end;

     TChange_block = record
       id:integer;
       name:PChar;
       solid,transparent:Boolean;
       light_level:integer;
     end;

     //tip dla hraneniya data_value dla bloka
     TBlock_data_set = record
       data_id:byte;
       data_name:string[45];
     end;

     //tip dla sootvetstviya ID bloka, ego nazvaniya i harakteristik
     TBlock_set = record
       id:integer;
       name:string[35];
       solid,transparent,diffuse,tile:boolean;
       light_level:byte;
       diffuse_level:byte;
       data:array of TBlock_data_set;
     end;

     //tipi dla sohraneniya parametrov generacii
     layer=record
       start_alt:integer;
       width:integer;
       material:integer;
       material_data:byte;
       name:string[26];
     end;

     layers_ar = array of layer;

     //infa o versii fayla
     TFileVersionInfo = record 
       FileType,
       CompanyName,
       FileDescription,
       FileVersion,
       InternalName,
       LegalCopyRight,
       LegalTradeMarks,
       OriginalFileName,
       ProductName,
       ProductVersion,
       Comments,
       SpecialBuildStr,
       PrivateBuildStr,
       FileFunction : string;
       DebugBuild,
       PreRelease,
       SpecialBuild,
       PrivateBuild,
       Patched,
       InfoInferred : Boolean;
     end;

     line=array of TGen_Chunk;
     region=array of line;

     //tipi dla mnozhestv blokov
     for_set = 0..255;
     set_trans_blocks = set of for_set;
     
     //tip dla inventara i sundukov, furnace, dispenser
     pslot_item_data=^slot_item_data;
     slot_item_data=record
       id:smallint;
       damage:smallint;
       count,slot:byte;
     end;

  //tipi dla TileEntity
     //MobSpawner  
     pmon_spawn_tile_entity_data=^mon_spawn_tile_entity_data;
     mon_spawn_tile_entity_data=record
       entityid:string; //id moba
       delay:smallint;
     end;

     //Chest
     pchest_tile_entity_data=^chest_tile_entity_data;
     chest_tile_entity_data=record
       items:array of slot_item_data;  //ot 0 do 26 (vsego 27=3*9)
     end;


//internal types
     TKoord=record
       x,z:integer;
     end;
     TKoord_ar = array of TKoord;

     TSphere = record
       x,y,z:integer;
       sphere_type:byte;
       radius:integer;
       mat_shell,mat_fill,mat_thick:integer;
       fill_level:integer;
       parameter:byte;
       chunks:TKoord_ar;
     end;
     TSphere_ar = array of TSphere;

     TObj = record
       x,y,z,id:integer;
     end;
     TObj_ar = array of TObj;

var last_error:PChar;    //stroka s soobsheniem ob oshibke
plug_info_return:TPlugRec;   //zapis' s informaciey o razmerah tipov dannih dla viyasneniya sootvetstviya
plugin_settings:TPlugSettings;   //zapis' s informaciey o plagine
dll_path_str:string = '';  //stroka s putem do DLLki
app_hndl:cardinal;  //hendl Application menedgera
initialized:boolean = false;  //priznak inicializacii plagina
initialized_blocks:boolean = false;  //priznak peredachi massiva blokov
crc_manager:int64;    //CRC poluchennoe ot menedgera
flux:TFlux_set;  //zapis' s informaciey o izmenenii parametrov
mess_str:string;
mess_to_manager:PChar;   //stroka dla peredachi soobsheniy v menedger
stopped:boolean = false;   //priznak ostanovki generacii

blocks_ids:array of TBlock_set;
map_type:integer;
planet_type:integer;
ground_level:integer;
planet_density:integer;
size_min:integer;
size_max:integer;
spawn_min:integer;
spawn_max:integer;
distance:integer;
gen_wall:boolean;

trans_bl:set_trans_blocks;
light_bl:set_trans_blocks;
diff_bl:set_trans_blocks;
solid_bl:set_trans_blocks;

function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
function generate_chunk(i,j:integer):TGen_Chunk;
procedure clear_dynamic;
function gen_region(i,j:integer; map:region):boolean; register; 

implementation

uses RandomMCT, Windows, crc32_u, SysUtils, Math;

var chunk:TGen_Chunk;
sferi:TSphere_ar;
obj:TObj_ar;
pop_chunks:TKoord_ar;
r_obsh:rnd = nil;
obsh_sid:int64;

fromx_obsh,fromy_obsh,tox_obsh,toy_obsh:integer;
spawn_x,spawn_y,spawn_z:integer;

crc_rasch,crc_rasch_man:integer;

function set_block_id(map:region; xreg,yreg:integer; x,y,z,id:integer):boolean;
  var tempxot,tempxdo,tempyot,tempydo:integer;
  chx,chy:integer;
  xx,zz,yy:integer;
  begin
    if (y<0)or(y>255) then
    begin
      result:=false;
      exit;
    end;

    //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
    begin
      tempxot:=(xreg+1)*32-32;
      tempxdo:=(xreg+1)*32+3;
    end
    else
    begin
      tempxot:=xreg*32;
      tempxdo:=(xreg*32)+35;
    end;

    if yreg<0 then
    begin
      tempyot:=(yreg+1)*32-32;
      tempydo:=(yreg+1)*32+3;
    end
    else
    begin
      tempyot:=yreg*32;
      tempydo:=(yreg*32)+35;
    end;

    dec(tempxot,2);
    dec(tempxdo,2);
    dec(tempyot,2);
    dec(tempydo,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //uslovie
    if (chx>=tempxot)and(chx<=tempxdo)and(chy>=tempyot)and(chy<=tempydo) then
    begin
      //perevodim v koordinati chanka
      xx:=x mod 16;
      zz:=z mod 16;
      if xx<0 then inc(xx,16);
      if zz<0 then inc(zz,16);
      yy:=y;

      chx:=chx-tempxot;
      chy:=chy-tempyot;

      map[chx][chy].blocks[xx+zz*16+yy*256]:=id;
      result:=true;
    end
    else result:=false;
  end;

function set_block_id_data(map:region; xreg,yreg:integer; x,y,z,id,data:integer):boolean;
  var tempxot,tempxdo,tempyot,tempydo:integer;
  chx,chy:integer;
  xx,zz,yy:integer;
  begin
    if (y<0)or(y>255) then
    begin
      result:=false;
      exit;
    end;

    //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
    begin
      tempxot:=(xreg+1)*32-32;
      tempxdo:=(xreg+1)*32+3;
    end
    else
    begin
      tempxot:=xreg*32;
      tempxdo:=(xreg*32)+35;
    end;

    if yreg<0 then
    begin
      tempyot:=(yreg+1)*32-32;
      tempydo:=(yreg+1)*32+3;
    end
    else
    begin
      tempyot:=yreg*32;
      tempydo:=(yreg*32)+35;
    end;

    dec(tempxot,2);
    dec(tempxdo,2);
    dec(tempyot,2);
    dec(tempydo,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //uslovie
    if (chx>=tempxot)and(chx<=tempxdo)and(chy>=tempyot)and(chy<=tempydo) then
    begin
      //perevodim v koordinati chanka
      xx:=x mod 16;
      zz:=z mod 16;
      if xx<0 then inc(xx,16);
      if zz<0 then inc(zz,16);
      yy:=y;

      chx:=chx-tempxot;
      chy:=chy-tempyot;

      map[chx][chy].blocks[xx+zz*16+yy*256]:=id;
      if data<>0 then map[chx][chy].data[xx+zz*16+yy*256]:=data;
      result:=true;
    end
    else result:=false;
  end;

function get_block_id(map:region; xreg,yreg:integer; x,y,z:integer):byte;
  var tempxot,tempxdo,tempyot,tempydo:integer;
  chx,chy:integer;
  xx,zz,yy:integer;
  begin
    if (y<0)or(y>255) then
    begin
      result:=255;
      exit;
    end;

    //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
    begin
      tempxot:=(xreg+1)*32-32;
      tempxdo:=(xreg+1)*32+3;
    end
    else
    begin
      tempxot:=xreg*32;
      tempxdo:=(xreg*32)+35;
    end;

    if yreg<0 then
    begin
      tempyot:=(yreg+1)*32-32;
      tempydo:=(yreg+1)*32+3;
    end
    else
    begin
      tempyot:=yreg*32;
      tempydo:=(yreg*32)+35;
    end;

    dec(tempxot,2);
    dec(tempxdo,2);
    dec(tempyot,2);
    dec(tempydo,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //uslovie
    if (chx>=tempxot)and(chx<=tempxdo)and(chy>=tempyot)and(chy<=tempydo) then
    begin
      //perevodim v koordinati chanka
      xx:=x mod 16;
      zz:=z mod 16;
      if xx<0 then inc(xx,16);
      if zz<0 then inc(zz,16);
      yy:=y;

      chx:=chx-tempxot;
      chy:=chy-tempyot;

      result:=map[chx][chy].blocks[xx+zz*16+yy*256];
    end
    else result:=255;
  end;

procedure fill_spheres_chunks(var arobsh:TSphere_ar);
var tempx,tempy,tempz,tempk,i,j,z,k:integer;
begin
  for k:=0 to length(arobsh)-1 do
  begin
  //opredelaem kraynie koordinati po dvum osam
          tempx:=arobsh[k].x-arobsh[k].radius;
          tempk:=arobsh[k].x+arobsh[k].radius;
          tempy:=arobsh[k].z-arobsh[k].radius;
          tempz:=arobsh[k].z+arobsh[k].radius;

          //perevodim koordinati v chanki
          if tempx<0 then inc(tempx);
          if tempk<0 then inc(tempk);
          if tempy<0 then inc(tempy);
          if tempz<0 then inc(tempz);

          //zapisivaem koordinati
          tempx:=tempx div 16;
          tempk:=tempk div 16;
          tempy:=tempy div 16;
          tempz:=tempz div 16;

          //popravka na minusovie chanki
          if (tempx<=0)and((arobsh[k].x-arobsh[k].radius)<0) then tempx:=tempx-1;
          if (tempk<=0)and((arobsh[k].x+arobsh[k].radius)<0) then tempk:=tempk-1;
          if (tempy<=0)and((arobsh[k].z-arobsh[k].radius)<0) then tempy:=tempy-1;
          if (tempz<=0)and((arobsh[k].z+arobsh[k].radius)<0) then tempz:=tempz-1;

          //videlaem pamat'
          setlength(arobsh[k].chunks,(tempk-tempx+1)*(tempz-tempy+1));

          //zapisivaem
          z:=0;
          for i:=tempx to tempk do
            for j:=tempy to tempz do
            begin
              arobsh[k].chunks[z].x:=i;
              arobsh[k].chunks[z].z:=j;
              inc(z);
            end;
  end;
end;

procedure gen_vines(xreg,yreg:integer; map:region; x,y,z:integer; sid:int64);
var data,l_u,l_d,l_l,l_r,max,i:integer;
r:rnd;
begin
  r:=rnd.Create(sid);

  i:=get_block_id(map,xreg,yreg,x,y,z+1);
  //if (i=0)or(i=106) then l_u:=0
  if i<>18 then l_u:=0
  else l_u:=r.nextInt(15)+4;

  i:=get_block_id(map,xreg,yreg,x,y,z-1);
  //if (i=0)or(i=106) then l_d:=0
  if i<>18 then l_d:=0
  else l_d:=r.nextInt(15)+4;

  i:=get_block_id(map,xreg,yreg,x-1,y,z);
  //if (i=0)or(i=106) then l_l:=0
  if i<>18 then l_l:=0
  else l_l:=r.nextInt(15)+4;

  i:=get_block_id(map,xreg,yreg,x+1,y,z);
  //if (i=0)or(i=106) then l_r:=0
  if i<>18 then l_r:=0
  else l_r:=r.nextInt(15)+4;

  max:=l_u;
  if l_d>max then max:=l_d;
  if l_l>max then max:=l_l;
  if l_r>max then max:=l_r;

  l_u:=y-l_u;
  l_d:=y-l_d;
  l_l:=y-l_l;
  l_r:=y-l_r;

  max:=y-max;
  if max<0 then max:=0;

  for i:=y downto max do
  begin
    if get_block_id(map,xreg,yreg,x,i,z)<>0 then break;

    data:=0;
    if i>l_u then data:=data or 1;
    if i>l_d then data:=data or 4;
    if i>l_l then data:=data or 2;
    if i>l_r then data:=data or 8;
    set_block_id_data(map,xreg,yreg,x,i,z,106,data);
  end;

  r.Free;
end;

function gen_tree_notch(map:region; xreg,yreg,x,y,z,data:integer; sid:int64):boolean;
var len:integer;
i,j,k,t,t1,l3,j4:integer;
flag:boolean;
byte0:byte;
r:rnd;
begin
  r:=rnd.Create(sid);

  len:=r.nextInt(3)+5;
  if (y<1)or((y+len+1)>256) then
  begin
    result:=false;
    r.Free;
    exit;
  end;

  flag:=true;
  for i:=y to y+len+1 do
  begin
    if flag=false then break;

    if i=y then byte0:=0
    else if i<(y+len-1) then byte0:=2
    else byte0:=1;

    for j:=x-byte0 to x+byte0 do
    begin
      if flag=false then break;

      for k:=z-byte0 to z+byte0 do
      begin
        if flag=false then break;

        t:=get_block_id(map,xreg,yreg,j,i,k);
        if (t<>0)and(t<>18)and(t<>255) then flag:=false;
      end;
    end;
  end;

  if flag=false then
  begin
    result:=false;
    r.Free;
    exit;
  end;

  t:=get_block_id(map,xreg,yreg,x,y-1,z);
  if(t<>2)and(t<>3) then
  begin
    result:=false;
    r.Free;
    exit;
  end
  else
    set_block_id(map,xreg,yreg,x,y-1,z,3);

  for i:=(y-3+len) to y+len do
  begin
    t:=i-(y+len);
    t1:=trunc(1-t/2);
    for j:=x-t1 to x+t1 do
    begin
      l3:=j-x;
      for k:=z-t1 to z+t1 do
      begin
        j4:=k-z;
        if (abs(l3)<>t1)or(abs(j4)<>t1)or(r.nextInt(2)<>0)and(t<>0) then
          set_block_id_data(map,xreg,yreg,j,i,k,18,data);
      end;
    end;
  end;

  for i:=0 to len-1 do
  begin
    t:=get_block_id(map,xreg,yreg,x,y+i,z);
    if (t=0)or(t=18) then
      set_block_id_data(map,xreg,yreg,x,y+i,z,17,data);
  end;

  r.Free;
  result:=true;
end;

function gen_bigtree_notch(map:region; xreg,yreg,x,y,z:integer; sid:int64):boolean;
var rr:rnd;
basepos:array[0..2] of integer;
otherCoordPairs:array[0..5] of byte;
heightLimit,height,trunkSize,heightLimitLimit,leafDistanceLimit:integer;
leafNodes:array of array of integer;
field_874_i,field_873_j,field_872_k,heightAttenuation:extended;

  procedure Init;
  begin
    rr:=rnd.Create;
    heightLimit:=0;
    heightAttenuation:=0.61799999999999999;
    field_874_i:=0.38100000000000001;
    field_873_j:=1;
    field_872_k:=1;
    trunkSize:=1;
    heightLimitLimit:=12;
    leafDistanceLimit:=4;

    otherCoordPairs[0]:=2;
    otherCoordPairs[1]:=0;
    otherCoordPairs[2]:=0;
    otherCoordPairs[3]:=1;
    otherCoordPairs[4]:=2;
    otherCoordPairs[5]:=1;

    SetRoundMode(rmDown);
  end;

  procedure Destroy;
  var i:integer;
  begin
    rr.Free;

    for i:=0 to length(leafNodes)-1 do
      setlength(leafNodes[i],0);
    setlength(leafNodes,0);

    SetRoundMode(rmNearest);
  end;

  procedure func_517_a(d,d1,d2:double);
begin
  heightLimitLimit:=trunc(d*12);
  if d>0.5 then leafDistanceLimit:=5;
  field_873_j:=d1;
  field_872_k:=d2;
end;

function leafNodeNeedsBase(i:integer):boolean;
begin
  result:=(i>=(heightLimit * 0.20000000000000001));
end;

procedure placeBlockLine(map:region; xreg,yreg:integer; ai,ai1:array of integer; i:integer);
var ai2,ai3:array[0..2]of integer;
byte0,byte1,byte2:byte;
byte3,j,k:integer;
d,d1:double;
begin
  j:=0;
  for byte0:=0 to 2 do
  begin
    ai2[byte0]:=ai1[byte0]-ai[byte0];
    if abs(ai2[byte0])>abs(ai2[j]) then j:=byte0;
  end;

  if ai2[j]=0 then exit;

  byte1:=otherCoordPairs[j];
  byte2:=otherCoordPairs[j+3];
  if(ai2[j]>0) then byte3:=1
  else byte3:=-1;

  d:=ai2[byte1]/ai2[j];
  d1:=ai2[byte2]/ai2[j];

  k:=0;
  while k<>(ai2[j]+byte3) do
  begin
    ai3[j]:=round(ai[j]+k+0.5);
    ai3[byte1]:=round(ai[byte1]+k*d+0.5);
    ai3[byte2]:=round(ai[byte2]+k*d1+0.5);
    set_block_id(map,xreg,yreg,ai3[0],ai3[1],ai3[2],i);

    k:=k+byte3;
  end;
end;

procedure generateLeafNodeBases(map:region;xreg,yreg:integer);
var i:integer;
ai,ai2:array[0..2]of integer;
begin
  for i:=0 to 2 do
    ai[i]:=basepos[i];

  for i:=0 to length(leafNodes)-1 do
  begin
    ai2[0]:=leafNodes[i][0];
    ai2[1]:=leafNodes[i][1];
    ai2[2]:=leafNodes[i][2];

    ai[1]:=leafNodes[i][3];
    if leafNodeNeedsBase(ai[1]-basePos[1]) then placeBlockLine(map,xreg,yreg,ai,ai2,17);
  end;
end;

procedure generateTrunk(map:region; xreg,yreg:integer);
var ai,ai1:array[0..2]of integer;
i,j,k,l:integer;
begin
  i:=basePos[0];
  j:=basePos[1];
  k:=basePos[1]+height;
  l:=basePos[2];

  ai[0]:=i;
  ai[1]:=j;
  ai[2]:=l;

  ai1[0]:=i;
  ai1[1]:=k;
  ai1[2]:=l;

  placeBlockLine(map,xreg,yreg,ai,ai1,17);

  if trunkSize=2 then
  begin
    inc(ai[0]);
    inc(ai1[0]);
    placeBlockLine(map,xreg,yreg,ai, ai1, 17);
    inc(ai[2]);
    inc(ai1[2]);
    placeBlockLine(map,xreg,yreg,ai, ai1, 17);
    dec(ai[0]);
    dec(ai1[0]);
    placeBlockLine(map,xreg,yreg,ai, ai1, 17);
  end;
end;

function func_528_a(i:integer):double;
var f,f1,f2:double;
begin
  if i<(heightlimit*0.29999999999999999) then
  begin
    result:=-1.618;
    exit;
  end;

  f:=heightlimit/2;
  f1:=heightlimit/2-i;
  if f1=0 then f2:=f
  else if abs(f1)>=f then f2:=0
  else f2:=sqrt(sqr(f)-sqr(f1));

  f2:=f2*0.5;
  result:=f2;
end;

procedure func_523_a(map:region; xreg,yreg,i,j,k:integer; f:double; byte0:byte; l:integer);
var i1,j1,l1,i2:integer;
byte1,byte2:byte;
ai,ai1:array[0..2]of integer;
d:extended;
begin
  i1:=trunc(f+0.61799999999999999);
  byte1:=otherCoordPairs[byte0];
  byte2:=otherCoordPairs[byte0+3];

  ai[0]:=i;
  ai[1]:=j;
  ai[2]:=k;

  ai1[0]:=0;
  ai1[1]:=0;
  ai1[2]:=0;

  j1:=-i1;
  ai1[byte0]:=ai[byte0];

  while j1<=i1 do
  begin
    ai1[byte1]:=ai[byte1]+j1;

    l1:=-i1;
    while l1<=i1 do
    begin
      d:=sqrt(sqr(abs(j1)+0.5)+sqr(abs(l1)+0.5));
      if d>f then inc(l1)
      else
      begin
        ai1[byte2]:=ai[byte2]+l1;
        i2:=get_block_id(map,xreg,yreg,ai1[0],ai1[1],ai1[2]);
        if (i2<>0)and(i2<>18) then inc(l1)
        else
        begin
          set_block_id(map,xreg,yreg,ai1[0],ai1[1],ai1[2],l);
          inc(l1);
        end;
      end;
    end;

    inc(j1);
  end;
end;

function func_526_b(i:integer):double;
begin
  if (i<0)or(i>leafDistanceLimit) then
  begin
    result:=-1;
    exit;
  end;

  if (i<>0)and(i<>(leafDistanceLimit-1)) then result:=3
  else result:=2;
end;

procedure generateLeafNode(map:region; xreg,yreg,i,j,k:integer);
var l:integer;
begin
  for l:=j to j+leafDistanceLimit-1 do
    func_523_a(map,xreg,yreg,i,l,k,func_526_b(l-j),1,18);
end;

procedure generateLeaves(map:region; xreg,yreg:integer);
var i:integer;
begin
  for i:=0 to length(leafNodes)-1 do
    generateLeafNode(map,xreg,yreg,leafNodes[i][0],leafNodes[i][1],leafNodes[i][2]);
end;

function checkBlockLine(map:region; xreg,yreg:integer; ai,ai1:array of integer):integer;
var ai2,ai3:array[0..2]of integer;
i,t,j,k,l,byte3:integer;
byte1,byte2:byte;
d,d1:double;
begin
  t:=0;
  for i:=0 to 2 do
  begin
    ai2[i]:=ai1[i]-ai[i];
    if abs(ai2[i])>abs(ai2[t]) then t:=i;
  end;

  if ai2[t]=0 then
  begin
    result:=-1;
    exit;
  end;

  byte1:=otherCoordPairs[t];
  byte2:=otherCoordPairs[t+3];
  if (ai2[t]>0) then byte3:=1 else byte3:=-1;

  d:=ai2[byte1]/ai2[t];
  d1:=ai2[byte2]/ai2[t];

  j:=0;
  k:=ai2[t]+byte3;

  repeat
    if j=k then break;

    ai3[t]:=ai[t]+j;
    ai3[byte1]:=round(ai[byte1]+j*d);
    ai3[byte2]:=round(ai[byte2]+j*d1);
    l:=get_block_id(map,xreg,yreg,ai3[0],ai3[1],ai3[2]);

    if(l<>0)and(l<>18)and(l<>31) then break;
    j:=j+byte3;
  until false;

  if (j=k) then
    result:=-1
  else
    result:=abs(j);
end;

procedure generateLeafNodeList(map:region; xreg,yreg:integer);
var i,j,k,l,i1,j1,k1,l1:integer;
ai:array of array of integer;
ai1,ai2,ai3:array[0..2]of integer;
f,d1,d2,d4:double;
begin
  height:=trunc(heightlimit*heightAttenuation);
  if height>=heightlimit then height:=height-heightlimit;

  i:=trunc(1.3819999999999999+power((field_872_k*heightlimit)/13,2));
  if i<1 then i:=1;

  setlength(ai,i*heightlimit);
  for j:=0 to length(ai)-1 do
    setlength(ai[j],4);

  j:=(basepos[1]+heightlimit)-leafDistanceLimit;
  k:=1;
  l:=basepos[1]+height;
  i1:=j-basepos[1];
  ai[0][0]:=basepos[0];
  ai[0][1]:=j;
  ai[0][2]:=basepos[2];
  ai[0][3]:=l;
  dec(j);

  while i1>=0 do
  begin
    j1:=0;
    f:=func_528_a(i1);
    if f<0 then
    begin
      dec(j);
      dec(i1);
    end
    else
    begin
      while j1<i do
      begin
        d1:=field_873_j*(f*(rr.nextDouble+0.32800000000000001));
        d2:=rr.nextDouble*2*3.1415899999999999;

        k1:=round(d1*sin(d2)+basepos[0]+0.5);
        l1:=round(d1*cos(d2)+basepos[2]+0.5);

        ai1[0]:=k1;
        ai1[1]:=j;
        ai1[2]:=l1;

        ai2[0]:=k1;
        ai2[1]:=j+leafDistanceLimit;
        ai2[2]:=l1;

        if checkBlockLine(map,xreg,yreg,ai1,ai2)<>-1 then
        begin
          inc(j1);
          continue;
        end;

        ai3[0]:=basepos[0];
        ai3[1]:=basepos[1];
        ai3[2]:=basepos[2];

        d4:=sqrt(sqr(basepos[0]-ai1[0])+sqr(basepos[2]-ai1[2]))*field_874_i;

        if(ai1[1]-d4)>l then ai3[1]:=l
        else ai3[1]:=trunc(ai1[1]-d4);

        if checkBlockLine(map,xreg,yreg,ai3,ai1)=-1 then
        begin
          ai[k][0]:=k1;
          ai[k][1]:=j;
          ai[k][2]:=l1;
          ai[k][3]:=ai3[1];
          inc(k);
        end;

        inc(j1);
      end;
      dec(j);
      dec(i1);
    end;
  end;

  setlength(leafNodes,k);
  for j1:=0 to k-1 do
    setlength(leafNodes[j1],4);

  for j1:=0 to k-1 do
    for k1:=0 to 3 do
      leafNodes[j1][k1]:=ai[j1][k1];

  for j1:=0 to length(ai)-1 do
    setlength(ai[j1],0);
  setlength(ai,0);
end;

function validTreeLocation(map:region; xreg,yreg:integer):boolean;
var ai,ai1:array[0..2] of integer;
i:integer;
begin
  for i:=0 to 2 do
  begin
    ai[i]:=basepos[i];
    if i=1 then ai1[i]:=basepos[i]+heightlimit-1
    else ai1[i]:=basepos[i];
  end;
  i:=get_block_id(map,xreg,yreg,basepos[0],basepos[1]-1,basepos[2]);
  if (i<>2)and(i<>3) then
  begin
    result:=false;
    exit;
  end;
  i:=checkBlockLine(map,xreg,yreg,ai,ai1);

  if i=-1 then
  begin
    result:=true;
    exit;
  end;
  if (i<6) then
    result:=false
  else
  begin
    heightlimit:=i;
    result:=true;
  end;
end;

begin
  init;

  rr.SetSeed(sid);
  basepos[0]:=x;
  basepos[1]:=y;
  basepos[2]:=z;

  if heightlimit=0 then heightlimit:=5+rr.nextInt(heightlimitlimit);

  if validTreeLocation(map,xreg,yreg)=false then
  begin
    result:=false;
  end
  else
  begin
    generateLeafNodeList(map,xreg,yreg);
    generateLeaves(map,xreg,yreg);
    generateTrunk(map,xreg,yreg);
    generateLeafNodeBases(map,xreg,yreg);
    result:=true;
  end;
  destroy;
end;

//procedura generacii visikoy elki
function gen_tree_taiga1_notch(map:region; xreg,yreg,x,y,z:integer; sid:int64):boolean;
var len:integer;
i1,j1,k1,l1,j2,l2,k3,t,k4,i5:integer;
flag:boolean;
r:rnd;
begin
  r:=rnd.Create(sid);

  len:=r.nextInt(5)+7;
  i1:=len-r.nextInt(2)-3;
  j1:=len-i1;
  k1:=1+r.nextInt(j1+1);
  flag:=true;

  if (y<1)or((y+len+1)>256) then
  begin
    result:=false;
    r.Free;
    exit;
  end;

  for l1:=y to y+1+len do
  begin
    if flag=false then break;

    if (l1-y)<i1 then j2:=0
    else j2:=k1;

    for l2:=x-j2 to x+j2 do
      for k3:=z-j2 to z+j2 do
      begin
        if flag=false then break;

        t:=get_block_id(map,xreg,yreg,l2,l1,k3);
        if(t<>0)and(t<>18) then flag:=false;
      end;
  end;

  if flag=false then
  begin
    result:=false;
    r.Free;
    exit;
  end;

  t:=get_block_id(map,xreg,yreg,x,y-1,z);
  if(t=2)or(t=3) then
    set_block_id(map,xreg,yreg,x,y-1,z,3)
  else
  begin
    result:=false;
    r.Free;
    exit;
  end;

  j2:=0;
  for l1:=y+len downto y+i1 do
  begin
    for l2:=x-j2 to x+j2 do
    begin
      k4:=l2-x;
      for k3:=z-j2 to z+j2 do
      begin
        i5:=k3-z;
        if (abs(k4)<>j2)or(abs(i5)<>j2)or(j2<=0) then
          set_block_id_data(map,xreg,yreg,l2,l1,k3,18,1);
      end;
    end;

    if(j2>=1)and(l1=y+i1+1) then
    begin
      dec(j2);
      continue;
    end;
    if(j2<k1) then inc(j2);
  end;

  for l1:=0 to len-2 do
  begin
    t:=get_block_id(map,xreg,yreg,x,y+l1,z);
    if(t=0)or(t=18) then set_block_id_data(map,xreg,yreg,x,y+l1,z,17,1);
  end;

  r.Free;
  result:=true;
end;

//procedura generacii shirokoy elki
function gen_tree_taiga2_notch(map:region; xreg,yreg,x,y,z:integer; sid:int64):boolean;
var l,i1,j1,k1,i,j,k,j2,t,k2,i3,j4,j5,l5:integer;
flag,flag1:boolean;
r:rnd;
begin
  r:=rnd.Create(sid);

  l:=r.nextInt(4)+6;
  if(y<1)or((y+l+1)>256) then
  begin
    result:=false;
    exit;
  end;
  i1:=1+r.nextInt(2);
  j1:=l-i1;
  k1:=2+r.nextInt(2);
  flag:=true;

  for i:=y to y+1+l do
  begin
    if flag=false then break;

    if(i-y)<i1 then j2:=0
    else j2:=k1;
    for j:=x-j2 to x+j2 do
      for k:=z-j2 to z+j2 do
      begin
        if flag=false then break;

        t:=get_block_id(map,xreg,yreg,j,i,k);
        if (t<>0)and(t<>18) then flag:=false;
      end;
  end;

  if flag=false then
  begin
    result:=false;
    r.Free;
    exit;
  end;

  t:=get_block_id(map,xreg,yreg,x,y-1,z);
  if(t=2)or(t=3) then
    set_block_id(map,xreg,yreg,x,y-1,z,3)
  else
  begin
    result:=false;
    r.Free;
    exit;
  end;

  k2:=r.nextInt(2);
  i3:=1;
  flag1:=false;
  for i:=0 to j1 do
  begin
    j4:=(y+l)-i;
    for j:=x-k2 to x+k2 do
    begin
      j5:=j-x;
      for k:=z-k2 to z+k2 do
      begin
        l5:=k-z;
        if (abs(j5)<>k2)or(abs(l5)<>k2)or(k2<=0) then
          set_block_id_data(map,xreg,yreg,j,j4,k,18,1);
      end;
    end;

    if(k2>=i3) then
    begin
      if flag1 then k2:=1 else k2:=0;
      flag1:=true;
      inc(i3);
      if(i3>k1) then i3:=k1;
    end
    else inc(k2);
  end;

  i3:=r.nextInt(3);
  for i:=0 to l-i3-1 do
  begin
    t:=get_block_id(map,xreg,yreg,x,y+i,z);
    if(t=0)or(t=18) then set_block_id_data(map,xreg,yreg,x,y+i,z,17,1);
  end;

  r.Free;
  result:=true;
end;

procedure gen_pumpkins_patch(map:region; xreg,yreg,x,y,z,id:integer; sid:int64);
var r:rnd;
i,j,k,l,t:integer;
begin
  r:=rnd.Create(sid);
  for i:=0 to 63 do
  begin
    j:=x+r.nextInt(8)-r.nextInt(8);
    k:=y+r.nextInt(6)-r.nextInt(6);
    l:=z+r.nextInt(8)-r.nextInt(8);
    t:=get_block_id(map,xreg,yreg,j,k-1,l);
    if (get_block_id(map,xreg,yreg,j,k,l)=0)and((t=2)or(t=3)) then
      set_block_id_data(map,xreg,yreg,j,k,l,id,r.nextInt(4));
  end;
  r.Free;
end;

procedure gen_kaktus(map:region; xreg,yreg,x,y,z:integer; sid:int64);
var r:rnd;
l,i,l1:integer;
begin
  r:=rnd.Create(sid);

  l:=r.nextInt(3)+1;
  r.Free;

  l1:=0;
  //proverka
  for i:=0 to l-1 do
    if (get_block_id(map,xreg,yreg,x-1,y+i,z)<>0)or
    (get_block_id(map,xreg,yreg,x+1,y+i,z)<>0)or
    (get_block_id(map,xreg,yreg,x,y+i,z-1)<>0)or
    (get_block_id(map,xreg,yreg,x,y+i,z+1)<>0)then
      break
    else inc(l1);

  for i:=0 to l1-1 do
    set_block_id(map,xreg,yreg,x,y+i,z,81);

  //set_block_id(map,xreg,yreg,x,y+i,z,89);
end;

function gen_big_mushroom_notch(map:region; xreg,yreg,x,y,z,typ:integer; sid:int64):boolean;
var r:rnd;
l,i,j,k,t,l1,i3:integer;
byte0:byte;
flag:boolean;
data:integer;
begin
  r:=rnd.Create(sid);

  l:=r.nextInt(3)+4;
  r.Free;
  flag:=true;
  if (y<1)or((y+l+1)>256) then
  begin
    result:=false;
    exit;
  end;

  for i:=y to y+l+1 do
  begin
    byte0:=3;
    if i=y then byte0:=0;
    for j:=x-byte0 to x+byte0 do
      for k:=z-byte0 to z+byte0 do
      begin
        t:=get_block_id(map,xreg,yreg,j,i,k);
        if (t<>0)and(t<>18) then flag:=false;
      end;
  end;

  t:=get_block_id(map,xreg,yreg,x,y-1,z);
  if (t<>2)and(t<>3)and(t<>110) then flag:=false;

  if flag=false then
  begin
    result:=false;
    exit;
  end;

  set_block_id(map,xreg,yreg,x,y-1,z,3);
  l1:=y+l;
  if typ=1 then l1:=y+l-3;

  for j:=l1 to y+l do
  begin
    i3:=1;
    if j<(y+l) then inc(i3);
    if typ=0 then i3:=3;
    for i:=x-i3 to x+i3 do
      for k:=z-i3 to z+i3 do
      begin
        data:=5;
        if i=x-i3 then dec(data);
        if i=x+i3 then inc(data);
        if k=z-i3 then dec(data,3);
        if k=z+i3 then inc(data,3);
        if (typ=0)or(j<y+l) then
        begin
          if ((i=x-i3)or(i=x+i3))and((k=z-i3)or(k=z+i3)) then continue;
          if (i=x-(i3-1))and(k=z-i3) then data:=1;
          if (i=x-i3)and(k=z-(i3-1)) then data:=1;
          if (i=x+(i3-1))and(k=z-i3) then data:=3;
          if (i=x+i3)and(k=z-(i3-1)) then data:=3;
          if (i=x-(i3-1))and(k=z+i3) then data:=7;
          if (i=x-i3)and(k=z+(i3-1)) then data:=7;
          if (i=x+(i3-1))and(k=z+i3) then data:=9;
          if (i=x+i3)and(k=z+(i3-1)) then data:=9;   
        end;
        if (data=5)and(j<y+l) then data:=0;

        if ((data<>0)or(y>=y+l-1))and(get_block_id(map,xreg,yreg,i,j,k)in trans_bl) then
          set_block_id_data(map,xreg,yreg,i,j,k,99+typ,data);
      end;
  end;

  for i:=0 to l-1 do
  begin
    if (get_block_id(map,xreg,yreg,x,y+i,z)in trans_bl) then
      set_block_id_data(map,xreg,yreg,x,y+i,z,99+typ,10);
  end;

  result:=true;
end;

procedure gen_nether_wart(map:region; xreg,yreg,x,y,z:integer; sid:int64);
var r:rnd;
t:integer;
begin
  r:=rnd.Create(sid);
  t:=get_block_id(map,xreg,yreg,x,y-1,z);
  if (t=87)or(t=88)or(t=2)or(t=3)or(t=110)or(t=112) then
    set_block_id_data(map,xreg,yreg,x,y,z,115,r.nextInt(4));
  r.Free;
end;

function gen_torch(map:region; xreg,yreg,x,y,z:integer; sid:int64):boolean;
var r:rnd;
l_b,r_b,f_b,b_b:boolean;
t,i,j:integer;
begin
  for i:=x-2 to x+2 do
    for j:=z-2 to z+2 do
      for t:=y-2 to y+2 do
        if get_block_id(map,xreg,yreg,i,t,j)=50 then
        begin
          result:=false;
          exit;
        end;

  if (get_block_id(map,xreg,yreg,x,y-1,z) in solid_bl)and(get_block_id(map,xreg,yreg,x,y,z)=0) then
  begin
    set_block_id_data(map,xreg,yreg,x,y,z,50,5);
    result:=true;
    exit;
  end;

  if (get_block_id(map,xreg,yreg,x-1,y,z) in solid_bl) then l_b:=true
  else l_b:=false;
  if (get_block_id(map,xreg,yreg,x+1,y,z) in solid_bl) then r_b:=true
  else r_b:=false;
  if (get_block_id(map,xreg,yreg,x,y,z-1) in solid_bl) then b_b:=true
  else b_b:=false;
  if (get_block_id(map,xreg,yreg,x,y,z+1) in solid_bl) then f_b:=true
  else f_b:=false;

  if (l_b=false)and(r_b=false)and(f_b=false)and(b_b=false) then
  begin
    result:=false;
    exit;
  end;

  r:=rnd.Create(sid);
  t:=r.nextInt(4)+1;
  repeat
    case t of
    1:if l_b=true then break;
    2:if r_b=true then break;
    3:if b_b=true then break;
    4:if f_b=true then break;
    end;
    t:=r.nextInt(4)+1;
  until false;
  r.Free;

  if (get_block_id(map,xreg,yreg,x,y,z) in trans_bl) then
  begin
    set_block_id_data(map,xreg,yreg,x,y,z,50,t);
    result:=true;
  end
  else
    result:=false;
end;

function gen_reed(map:region; xreg,yreg,x,y,z:integer; sid:int64):boolean;
var r:rnd;
t,i:integer;
b:boolean;
begin
  b:=false;
  t:=get_block_id(map,xreg,yreg,x-1,y-1,z);
  if (t=9)or(t=8) then b:=true;
  t:=get_block_id(map,xreg,yreg,x+1,y-1,z);
  if (t=9)or(t=8) then b:=true;
  t:=get_block_id(map,xreg,yreg,x,y-1,z-1);
  if (t=9)or(t=8) then b:=true;
  t:=get_block_id(map,xreg,yreg,x,y-1,z+1);
  if (t=9)or(t=8) then b:=true;

  if b=false then
  begin
    result:=false;
    exit;
  end;

  r:=rnd.Create(sid);
  t:=r.nextInt(2)+1;
  r.Free;

  for i:=0 to t do
    set_block_id(map,xreg,yreg,x,y+i,z,83);

  result:=true;
end;

function gen_mushroom_biosphere(map:region; xreg,yreg,x,y,z,id:integer):boolean;
var i,j,k:integer;
begin
  for i:=x-2 to x+2 do
    for j:=z-2 to z+2 do
      for k:=y-2 to y+2 do
        if get_block_id(map,xreg,yreg,i,k,j)=50 then
          if (abs(i-x)+abs(j-z)+abs(k-y))<3 then
          begin
            result:=false;
            exit;
          end;

  set_block_id(map,xreg,yreg,x,y,z,39+id);
  result:=true;
end;

procedure gen_snow_region(xreg,yreg:integer; map:region);
var chx,chy,x,y,z,t:integer;
begin
  for chx:=0 to 35 do
    for chy:=0 to 35 do
      for x:=0 to 15 do
        for z:=0 to 15 do
          if (map[chx][chy].Biomes[x+z*16]=5)and(map[chx][chy].Blocks[x+z*16+255*256]=0) then
          begin
            y:=255;
            while (map[chx][chy].Blocks[x+z*16+y*256]=0)and(y>=0) do
              dec(y);
            if y=0 then continue;

            t:=map[chx][chy].Blocks[x+z*16+y*256];
            if (t in solid_bl)and(t<>20)and(t<>89)and(t<>79)and(t<>52) then
              map[chx][chy].Blocks[x+z*16+(y+1)*256]:=78;
          end;
end;

procedure gen_rnd_spawner(map:region; xreg,yreg:integer; x,y,z:integer; sid:int64);
var tempxot,tempyot,chx,chy,xx,zz,t:integer;
r:rnd;
begin
  //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
      tempxot:=(xreg+1)*32-32
    else
      tempxot:=xreg*32;

    if yreg<0 then
      tempyot:=(yreg+1)*32-32
    else
      tempyot:=yreg*32;

    dec(tempxot,2);
    dec(tempyot,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //perevodim v koordinati chanka
    xx:=x mod 16;
    zz:=z mod 16;
    if xx<0 then inc(xx,16);
    if zz<0 then inc(zz,16);

    chx:=chx-tempxot;
    chy:=chy-tempyot;

    r:=rnd.Create(sid);

    //delaem spawner
    map[chx][chy].blocks[xx+zz*16+y*256]:=52;

    t:=length(map[chx][chy].Tile_entities);
    setlength(map[chx][chy].Tile_entities,t+1);
    map[chx][chy].Tile_entities[t].Id:='MobSpawner';
    map[chx][chy].Tile_entities[t].x:=x;
    map[chx][chy].Tile_entities[t].y:=y;
    map[chx][chy].Tile_entities[t].z:=z;
    new(pmon_spawn_tile_entity_data(map[chx][chy].Tile_entities[t].data));
    case r.nextInt(100) of
      0..32:pmon_spawn_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.entityid:='Skeleton';
      33..65:pmon_spawn_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.entityid:='Spider';
      66..99:pmon_spawn_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.entityid:='Zombie';
    end;
    pmon_spawn_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.delay:=r.nextInt(100)+50;

    r.Free;
end;

procedure gen_rnd_dungeon_chest(map:region; xreg,yreg:integer; x,y,z:integer; sid:int64);
var tempxot,tempyot,chx,chy,xx,zz,t,t1,i,j,k:integer;
rot_ar:array[0..3] of boolean;
b:boolean;
r:rnd;
begin
  //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
      tempxot:=(xreg+1)*32-32
    else
      tempxot:=xreg*32;

    if yreg<0 then
      tempyot:=(yreg+1)*32-32
    else
      tempyot:=yreg*32;

    dec(tempxot,2);
    dec(tempyot,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //perevodim v koordinati chanka
    xx:=x mod 16;
    zz:=z mod 16;
    if xx<0 then inc(xx,16);
    if zz<0 then inc(zz,16);

    chx:=chx-tempxot;
    chy:=chy-tempyot;

    r:=rnd.Create(sid);

    //delaem sunduk
    map[chx][chy].blocks[xx+zz*16+y*256]:=54;
    //opredelaem povorot sunduka
    if (get_block_id(map,xreg,yreg,x,y,z+1) in solid_bl) then rot_ar[0]:=true
    else rot_ar[0]:=false;
    if (get_block_id(map,xreg,yreg,x,y,z-1) in solid_bl) then rot_ar[1]:=true
    else rot_ar[1]:=false;
    if (get_block_id(map,xreg,yreg,x+1,y,z) in solid_bl) then rot_ar[2]:=true
    else rot_ar[2]:=false;
    if (get_block_id(map,xreg,yreg,x-1,y,z) in solid_bl) then rot_ar[3]:=true
    else rot_ar[3]:=false;

    t1:=0;
    for t:=0 to 3 do
      if rot_ar[t]=true then inc(t1);

    case t1 of
      0,4:map[chx][chy].data[xx+zz*16+y*256]:=r.nextInt(4)+2;
      1:begin
          for t:=0 to 3 do
            if rot_ar[t]=true then
              map[chx][chy].data[xx+zz*16+y*256]:=t+2;
        end;
      2:begin
          t:=r.nextInt(4);
          while rot_ar[t]=false do
            t:=r.nextInt(4);
          map[chx][chy].data[xx+zz*16+y*256]:=t+2;
        end;
      3:begin
          for t:=0 to 3 do
            if rot_ar[t]=false then
              if ((t and 1)=1) then map[chx][chy].data[xx+zz*16+y*256]:=(t-1)+2
              else map[chx][chy].data[xx+zz*16+y*256]:=(t+1)+2;
        end;
    end;

    //telaem tile_entity
    t:=length(map[chx][chy].Tile_entities);
    setlength(map[chx][chy].Tile_entities,t+1);
    map[chx][chy].Tile_entities[t].Id:='Chest';
    map[chx][chy].Tile_entities[t].x:=x;
    map[chx][chy].Tile_entities[t].y:=y;
    map[chx][chy].Tile_entities[t].z:=z;
    new(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data));
    //opredelaem kol-vo zanimaemih slotov
    t1:=r.nextInt(6)+4;
    //zapolnaem sloti
    setlength(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items,t1);
    for i:=0 to t1-1 do
    begin
      repeat
      //opredelaem nomer slota
      k:=r.nextInt(27);
      //opredelaem, ne zanat li on uzhe
      b:=false;
      for j:=0 to i-1 do
        if pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[j].slot=k then
        begin
          b:=true;
          break;
        end;
      until b=false;
      //zapolnaem pola
      j:=r.nextInt(127)+256;
      if (j=342)or(j=343) then j:=260;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=j;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=0;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(3)+1;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].slot:=k;
    end;

    r.Free;
end;

procedure gen_rnd_treasure_chest(map:region; xreg,yreg:integer; x,y,z:integer; sid:int64);
var tempxot,tempyot,chx,chy,xx,zz,t,t1,i,j,k:integer;
rot_ar:array[0..3] of boolean;
b:boolean;
r:rnd;
begin
  //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
      tempxot:=(xreg+1)*32-32
    else
      tempxot:=xreg*32;

    if yreg<0 then
      tempyot:=(yreg+1)*32-32
    else
      tempyot:=yreg*32;

    dec(tempxot,2);
    dec(tempyot,2);

    //opredelaem, k kakomu chanku otnositsa
    chx:=x;
    chy:=z;

    if chx<0 then inc(chx);
    if chy<0 then inc(chy);

    chx:=chx div 16;
    chy:=chy div 16;

    if (chx<=0)and(x<0) then dec(chx);
    if (chy<=0)and(z<0) then dec(chy);

    //perevodim v koordinati chanka
    xx:=x mod 16;
    zz:=z mod 16;
    if xx<0 then inc(xx,16);
    if zz<0 then inc(zz,16);

    chx:=chx-tempxot;
    chy:=chy-tempyot;

    r:=rnd.Create(sid);

    //delaem sunduk
    map[chx][chy].blocks[xx+zz*16+y*256]:=54;
    //opredelaem povorot sunduka
    if (get_block_id(map,xreg,yreg,x,y,z+1) in solid_bl) then rot_ar[0]:=true
    else rot_ar[0]:=false;
    if (get_block_id(map,xreg,yreg,x,y,z-1) in solid_bl) then rot_ar[1]:=true
    else rot_ar[1]:=false;
    if (get_block_id(map,xreg,yreg,x+1,y,z) in solid_bl) then rot_ar[2]:=true
    else rot_ar[2]:=false;
    if (get_block_id(map,xreg,yreg,x-1,y,z) in solid_bl) then rot_ar[3]:=true
    else rot_ar[3]:=false;

    t1:=0;
    for t:=0 to 3 do
      if rot_ar[t]=true then inc(t1);

    case t1 of
      0,4:map[chx][chy].data[xx+zz*16+y*256]:=r.nextInt(4)+2;
      1:begin
          for t:=0 to 3 do
            if rot_ar[t]=true then
              map[chx][chy].data[xx+zz*16+y*256]:=t+2;
        end;
      2:begin
          t:=r.nextInt(4);
          while rot_ar[t]=false do
            t:=r.nextInt(4);
          map[chx][chy].data[xx+zz*16+y*256]:=t+2;
        end;
      3:begin
          for t:=0 to 3 do
            if rot_ar[t]=false then
              if ((t and 1)=1) then map[chx][chy].data[xx+zz*16+y*256]:=(t-1)+2
              else map[chx][chy].data[xx+zz*16+y*256]:=(t+1)+2;
        end;
    end;

    //telaem tile_entity
    t:=length(map[chx][chy].Tile_entities);
    setlength(map[chx][chy].Tile_entities,t+1);
    map[chx][chy].Tile_entities[t].Id:='Chest';
    map[chx][chy].Tile_entities[t].x:=x;
    map[chx][chy].Tile_entities[t].y:=y;
    map[chx][chy].Tile_entities[t].z:=z;
    new(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data));
    //opredelaem kol-vo zanimaemih slotov
    t1:=r.nextInt(6)+4;
    //zapolnaem sloti
    setlength(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items,t1);
    for i:=0 to t1-1 do
    begin
      repeat
      //opredelaem nomer slota
      k:=r.nextInt(27);
      //opredelaem, ne zanat li on uzhe
      b:=false;
      for j:=0 to i-1 do
        if pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[j].slot=k then
        begin
          b:=true;
          break;
        end;
      until b=false;
      //zapolnaem pola
      j:=r.nextInt(127)+256;
      if (j=342)or(j=343) then j:=260;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=j;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=0;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(3)+1;
      pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].slot:=k;
    end;

    //dopolnaem sunduk s rarnim lutom
    i:=length(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items);
    setlength(pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items,i+1);
    //opredelaem svobodniy slot
    repeat
      //opredelaem nomer slota
      k:=r.nextInt(27);
      //opredelaem, ne zanat li on uzhe
      b:=false;
      for j:=0 to i-1 do
        if pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[j].slot=k then
        begin
          b:=true;
          break;
        end;
    until b=false;
    //zapolnaem slot
    pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=1;
    pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].slot:=k;
    pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=0;
    pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=1;
    case r.nextInt(1500) of
      0..99:begin  //grass
              pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=2;
              pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(4)+2;
            end;
      100..199:begin  //bedrock
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=7;
               end;
      200..299:begin  //lava
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=10;
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(3)+1;
               end;
      300..399:begin  //sponge
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=19;
               end;
      400..499:begin  //cobweb
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=30;
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(3)+1;
               end;
      500..599:begin  //tnt
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=46;
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(21)+10;
               end;
      600..699:begin  //mobspawner
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=52;
               end;
      700..799:begin  //block of diamond
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=57;
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(5)+1;
               end;
      800..899:begin  //ice
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=79;
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(4)+2;
               end;
      900..999:begin  //portal
                 pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=90;
               end;
      1000..1099:begin  //mycelium
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=110;
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(4)+2;
                 end;
      1100..1199:begin  //end portal frame
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=384;
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(6)+5;
                 end;
      1200..1299:begin
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=385;
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].count:=r.nextInt(5)+1;
                 end;
      1300..1399:begin  //spawn egg
                  pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=383;
                  case r.nextInt(12) of
                  0:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=61;
                  1:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=120;
                  2:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=98;
                  3:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=50;
                  4:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=55;
                  5:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=59;
                  6:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=58;
                  7:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=95;
                  8:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=94;
                  9:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=56;
                  10:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=62;
                  11:pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].damage:=91;
                  end;
                end;
      1400..1499:begin
                   t1:=1256;
                   case r.nextInt(11) of
                     0:;
                     1:inc(t1,1);
                     2:inc(t1,2);
                     3:inc(t1,3);
                     4:inc(t1,4);
                     5:inc(t1,5);
                     6:inc(t1,6);
                     7:inc(t1,7);
                     8:inc(t1,8);
                     9:inc(t1,9);
                     10:inc(t1,10);
                   end;
                   pchest_tile_entity_data(map[chx][chy].Tile_entities[t].data)^.items[i].id:=t1;
                 end;
    end;

    r.Free;
end;

procedure gen_objects(xreg,yreg:integer; map:region);
var i,t:integer;
begin
  for i:=0 to length(obj)-1 do
  begin
    if get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)<>255 then
    case obj[i].id of
      1:begin  //pautina
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (t in trans_bl)and(t<>50) then
            set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,30);
        end;
      2:begin  //visohshaya trava
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)or(t=12)) then
            set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,31,0);
        end;
      3:begin  //obichnaya zelenaya trava
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)) then
            set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,31,1);
        end;
      4:begin  //trava v vide elki
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)) then
            set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,31,2);
        end;
      5:begin  //visohshiy kust (iz pustini)
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)or(t=12)) then
            set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,32,0);
        end;
      6:begin  //oduvanchik
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)) then
            set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,37);
        end;
      7:begin  //roza
          t:=get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z);
          if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and((t=2)or(t=3)or(t=60)) then
            set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,38);
        end;
      8:begin  //korichneviy grib
          //gen_mushroom_biosphere(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,0);
        end;
      9:begin  //krasniy grib
          //gen_mushroom_biosphere(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,1);
        end;
      10:begin  //ogon'
           if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and
           (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z)=87) then
             set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,51,0);
         end;
      11:begin  //wheat
         end;
      12:begin  //sneg
         end;
      13:begin  //kaktus
           gen_kaktus(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      14:begin  //trostnik
           //set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,89);
           gen_reed(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      15:begin  //tikvennaya pachka
           gen_pumpkins_patch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,86,obsh_sid+i);
         end;
      16:begin  //bol'shoy korichneviy grib
           gen_big_mushroom_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,0,obsh_sid+i);
           //set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,89,0);
         end;
      17:begin  //bol'shoy krasniy grib
           gen_big_mushroom_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,1,obsh_sid+i); 
           //set_block_id_data(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,92,0);
         end;
      18:begin  //arbuznaya pachka
           gen_pumpkins_patch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,103,obsh_sid+i);
         end;
      19:begin  //liani
           if get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0 then
             gen_vines(xreg,yreg,map,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      20:begin  //liliya
           if (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0)and
           (get_block_id(map,xreg,yreg,obj[i].x,obj[i].y-1,obj[i].z)=9) then
             set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,111)
         end;
      21:begin  //nether wart
           if get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)=0 then
             gen_nether_wart(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      22:begin  //obichnoe derevo
           //set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,89);
           gen_tree_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,0,obsh_sid+i);
         end;
      23:begin  //bol'shoe derevo
           //set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,89);
           gen_bigtree_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      24:begin  //bereza
           //set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,76);
           gen_tree_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,2,obsh_sid+i);
         end;
      25:begin  //visokaya elka
           gen_tree_taiga1_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      26:begin  //shirokaya elka
           gen_tree_taiga2_notch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      27:begin  //randomniy spawner dla dungeon
           gen_rnd_spawner(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
           //gen_rnd_dungeon_chest(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      28:begin  //sunduk s randomnim lutom dla dungeon
           gen_rnd_dungeon_chest(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      29:begin  //glowstone block
           if get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)in trans_bl then
             set_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,89);
         end;
      30:begin  //torch
           gen_torch(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
      31:begin  //sunduk s randomnim lutom dla sokrovisha
           gen_rnd_treasure_chest(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,obsh_sid+i);
         end;
    end;
  end;

  //delaem post processing osobih ob'ektov
  for i:=0 to length(obj)-1 do
  begin
    if get_block_id(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z)<>255 then
    case obj[i].id of
      8:begin  //korichneviy grib
          gen_mushroom_biosphere(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,0);
        end;
      9:begin  //krasniy grib
          gen_mushroom_biosphere(map,xreg,yreg,obj[i].x,obj[i].y,obj[i].z,1);
        end;
    end;
  end;
end;

procedure draw_spheres(xkoord,zkoord:integer; populated:boolean);
var x,y,z,k,l,l1,l2:integer;
temp:integer;
x1,y1,z1,r,r1:integer;
mat_shell,mat_fill,mat_data:integer;
b:boolean;
priznak:integer;
rand_sf:rnd;
begin
  for k:=0 to length(sferi)-1 do
  begin
    b:=true;
    for y:=0 to length(sferi[k].chunks)-1 do
      if (sferi[k].chunks[y].x=xkoord)and(sferi[k].chunks[y].z=zkoord) then
      begin
        b:=false;
        break;
      end;

    if b=true then continue;

    //random1:=rnd.Create(xkoord * $4f9939f508 + zkoord * $1ef1565bd5);

    //vichisaem otnositelnie koordinati sferi
    x1:=xkoord*16;
    z1:=zkoord*16;
    x1:=sferi[k].x-x1;
    z1:=sferi[k].z-z1;
    y1:=sferi[k].y;
    r:=sferi[k].radius;
    r1:=round((r/3)*2);
    mat_shell:=sferi[k].mat_shell;
    mat_fill:=sferi[k].mat_fill;

    //vistavlaem priznak
    priznak:=0;
    if (mat_shell=18)and((sferi[k].parameter and $3)<>3) then priznak:=1  //sfera iz obichnogo dereva/berezi/elki
    else if (mat_shell=18)and((sferi[k].parameter and $3)=3) then priznak:=2  //sfera iz Jungle wood
    else if (mat_shell=3)and((sferi[k].parameter and $80)=0)and((sferi[k].parameter and $F)=0) then priznak:=3 //sfera iz zemli s biomom Plains
    else if (mat_shell=3)and((sferi[k].parameter and $80)=0)and((sferi[k].parameter and $F)=1) then priznak:=4 //sfera iz zemli s biomom Forest
    else if (mat_shell=3)and((sferi[k].parameter and $80)=0)and((sferi[k].parameter and $F)=2) then priznak:=5 //sfera iz zemli s biomom Rainforest
    else if (mat_shell=3)and((sferi[k].parameter and $80)=0)and((sferi[k].parameter and $F)=3) then priznak:=6 //sfera iz zemli s biomom Tundra
    else if (mat_shell=20) then priznak:=7  //sfera iz stekla
    else if (mat_shell=1)and(sferi[k].parameter=0) then priznak:=8  //sfera iz kamna s normal'nim napolneniem
    else if (mat_shell=1)and(sferi[k].parameter=1) then priznak:=22  //sfera iz kamna s miksom
    else if (mat_shell=1)and(sferi[k].parameter=2) then priznak:=9  //sfera iz kamna s podzemel'em
    else if (mat_shell=1)and(sferi[k].parameter=3) then priznak:=24  //sfera iz kamna s biosferoy so spaunom fakelov na stenah
    else if (mat_shell=12)and(mat_fill=12)and(sferi[k].parameter=3) then priznak:=10  //obichnya sfera iz peska  bez podderzhki
    else if (mat_shell=12)and(mat_fill=12)and((sferi[k].parameter and $60)=0)and((sferi[k].parameter and $3)<>3)and((sferi[k].parameter and $80)=0) then priznak:=11  //pesochnaya sfera iz peska s podderzhkoy glini ili kamna
    else if (mat_shell=12)and(mat_fill=24)and((sferi[k].parameter and $3)=3) then priznak:=12  //obichnya sfera iz pesochnogo kamna bez podderzhki
    else if (mat_shell=12)and(mat_fill=24)and((sferi[k].parameter and $3)<>3) then priznak:=13  //pesochnaya sfera iz pesochnogo kamna s podderzhkoy glini ili kamna
    else if (mat_shell=12)and(mat_fill=12)and((sferi[k].parameter and $3)=3)and((sferi[k].parameter and $80)<>0) then priznak:=14  //obichnya sfera iz miksa peska bez podderzhki
    else if (mat_shell=12)and(mat_fill=12)and((sferi[k].parameter and $3)<>3)and((sferi[k].parameter and $80)<>0) then priznak:=15  //pesochnaya sfera iz miksa peska s podderzhkoy glini ili kamna
    else if (mat_shell=89)and(sferi[k].parameter=0)then priznak:=8  //sfera iz glowstone s obichnim napolneniem. Sovpadaet so sferoy iz kamna
    else if (mat_shell=89)and(sferi[k].parameter=1)then priznak:=23  //sfera iz glowstone so steklom i vozduhom
    else if (mat_shell=89)and(sferi[k].parameter=2)then priznak:=27  //sfera iz glowstone napolnenoy biosferoy bez spauna glowstone na stenah
    else if (mat_shell=7) then priznak:=16  //sfera iz bedroka s lubim napolneniem
    else if (mat_shell=49)and(sferi[k].parameter=0) then priznak:=8  //sfera iz obsidiana s normal'nim napolneniem. Sovpadaet so sferoy iz kamna
    else if (mat_shell=49)and(sferi[k].parameter=1) then priznak:=9  //sfera iz obsidiana s podzemel'em. SOvpadaet so sferoy iz kamna
    else if (mat_shell=49)and(sferi[k].parameter=2) then priznak:=25  //sfera is obsidiana s lovushkoy+sokrovisha
    else if (mat_shell=79)and(sferi[k].parameter=0) then priznak:=17  //sfera iz l'da s obichnim napolneniem
    else if (mat_shell=79)and(sferi[k].parameter<>0) then priznak:=18  //sfera iz l'da s napolneniem polnimi snezhnimi sloyami
    else if (mat_shell=87) then priznak:=19  //sfera iz netherrack s lubim napolneniem
    else if (mat_shell=3)and((sferi[k].parameter and $80)<>0) then priznak:=20  //gribnaya sfera
    else if (mat_shell=121) then priznak:=21;  //konechnaya sfera s napolneniem v vide mini podzemel'ya s End portal

    //delaem tikvi i arbuzi na zemlanih sferah
    if (priznak=3)or(priznak=4)or(priznak=5)or(priznak=6) then
    begin
      rand_sf:=rnd.Create(sferi[k].x*$1654 + sferi[k].y*$7614 + sferi[k].z*$3674 + sferi[k].radius);
      if rand_sf.nextDouble<0.05 then
      begin
        x:=sferi[k].x+rand_sf.nextInt(r)-rand_sf.nextInt(r);
        z:=sferi[k].z+rand_sf.nextInt(r)-rand_sf.nextInt(r);
        temp:=r*r-sqr(sferi[k].x-x)-sqr(sferi[k].z-z);
        while temp<0 do
        begin
          x:=sferi[k].x+rand_sf.nextInt(r)-rand_sf.nextInt(r);
          z:=sferi[k].z+rand_sf.nextInt(r)-rand_sf.nextInt(r);
          temp:=r*r-sqr(sferi[k].x-x)-sqr(sferi[k].z-z);
        end;
        y:=sferi[k].y+round(sqrt(temp))+1;

        l2:=length(obj);
        setlength(obj,l2+1);
        obj[l2].z:=z;
        obj[l2].x:=x;
        obj[l2].y:=y;
        if (priznak=3)and(rand_sf.nextDouble<0.3) then obj[l2].id:=18  //arbuz
        else obj[l2].id:=15;   //tikva
        
        rand_sf.Free;
      end
      else
        rand_sf.Free;
    end;


    if (priznak=1)or(priznak=2) then mat_data:=sferi[k].parameter and $7;

    for z:=0 to 15 do     //Z                   //levo pravo
      for y:=y1-r1 to y1+r1 do   //Y
      begin
        temp:=r*r-sqr(z-z1)-sqr(y-y1);
        if temp<0 then continue;
        for l:=0 to sferi[k].mat_thick-1 do
        begin
          x:=x1-round(sqrt(temp))+l;
          //uslovie protiv obsidianovoy sferi
          if x>x1 then break;

          if (x>=0)and(x<=15) then
          begin
            chunk.Blocks[x+z*16+y*256]:=mat_shell;
            if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;
          end;

          x:=x1+round(sqrt(temp))-l;
          if (x>=0)and(x<=15) then
          begin
            chunk.Blocks[x+z*16+y*256]:=mat_shell;
            if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;
          end;
        end;


        if (priznak=2)and(r_obsh.nextDouble<0.02)
        and(populated=false)and(y<y1) then //sozdaem liani
        begin
          l1:=length(obj);
          setlength(obj,l1+1);
          if r_obsh.nextDouble<0.5 then obj[l1].x:=xkoord*16+x1-round(sqrt(temp))-1
          else obj[l1].x:=xkoord*16+x1+round(sqrt(temp))+1;
          obj[l1].z:=zkoord*16+z;
          obj[l1].y:=y;
          obj[l1].id:=19;
        end;
      end;

    for x:=0 to 15 do     //X                   //pered zad
      for y:=y1-r1 to y1+r1 do   //Y
      begin
        temp:=r*r-sqr(x-x1)-sqr(y-y1);
        if temp<0 then continue;
        for l:=0 to sferi[k].mat_thick-1 do
        begin
          z:=z1-round(sqrt(temp))+l;
          //uslovie protiv obsidianovoy sferi
          if z>z1 then break;

          if (z>=0)and(z<=15) then
          begin
            chunk.Blocks[x+z*16+y*256]:=mat_shell;
            if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;
          end;

          z:=z1+round(sqrt(temp))-l;
          if (z>=0)and(z<=15) then
          begin
            chunk.Blocks[x+z*16+y*256]:=mat_shell;
            if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;
          end;
        end;

        if (priznak=2)and(r_obsh.nextDouble<0.02)
        and(populated=false)and(y<y1) then //sozdaem liani
        begin
          l1:=length(obj);
          setlength(obj,l1+1);
          if r_obsh.nextDouble<0.5 then obj[l1].z:=zkoord*16+z1-round(sqrt(temp))-1
          else obj[l1].z:=zkoord*16+z1+round(sqrt(temp))+1;
          obj[l1].x:=xkoord*16+x;
          obj[l1].y:=y;
          obj[l1].id:=19;
        end;
      end;

    for x:=0 to 15 do    //X                     //verh niz
      for z:=0 to 15 do    //Z
      begin
        temp:=r*r-sqr(x-x1)-sqr(z-z1);

        //delaem travu sverhu zemlanoy sferi i menaem biome
        if (priznak=3)or(priznak=4)or(priznak=5)or(priznak=6) then
        if (chunk.Blocks[x+z*16+y1*256]=3)and((temp+4*r+4)>=0) then
        begin
          l:=y1+1;
          while (chunk.Blocks[x+z*16+l*256]<>0) do
            inc(l);
          chunk.Blocks[x+z*16+(l-1)*256]:=2;

          case priznak of
            3:case chunk.Biomes[x+z*16] of
                0,2,14:chunk.Biomes[x+z*16]:=1;
              end;
            4,5:case chunk.Biomes[x+z*16] of
                  0,2,14,1:chunk.Biomes[x+z*16]:=4;
                end;
            6:case chunk.Biomes[x+z*16] of
                0,2,14,1,4:chunk.Biomes[x+z*16]:=5;
              end;
          end;
        end;

        //delaem glinu ili sandstone vnizu peschanih sfer
        if (priznak=11)or(priznak=13)or(priznak=15) then
        if (chunk.Blocks[x+z*16+y1*256]=12)and((temp+4*r+4)>=0) then
        begin   
          l:=y1-1;
          while (chunk.Blocks[x+z*16+l*256]<>0) do
            dec(l);
          case (sferi[k].parameter and $3) of
            1:chunk.Blocks[x+z*16+(l+1)*256]:=82;
            2:chunk.Blocks[x+z*16+(l+1)*256]:=24
            else chunk.Blocks[x+z*16+(l+1)*256]:=12;
          end;

          if chunk.Biomes[x+z*16]=0 then chunk.Biomes[x+z*16]:=2;
        end;

        //delaem mycelium naverhu gribnoy sferi
        if priznak=20 then
        if (chunk.Blocks[x+z*16+y1*256]=3)and((temp+4*r+4)>=0) then
        begin
          l:=y1+1;
          while (chunk.Blocks[x+z*16+l*256]<>0) do
            inc(l);
          chunk.Blocks[x+z*16+(l-1)*256]:=110;

          //delaem biome
          //if chunk.Biomes[x+z*16]=0 then chunk.Biomes[x+z*16]:=14;
          case chunk.Biomes[x+z*16] of
            0,2:chunk.Biomes[x+z*16]:=14;
          end;
        end;

        if temp<0 then continue;

        {if (x=x1)and(z=z1)and(priznak=9) then
        begin
          l2:=length(obj);
          setlength(obj,l2+1);
          obj[l2].z:=zkoord*16+z;
          obj[l2].x:=xkoord*16+x;
          obj[l2].y:=y1+round(sqrt(temp))+1;
          obj[l2].id:=16;
          chunk.Blocks[x+z*16+y1*256]:=41;
        end;    }

        //zapolnaem obolochku
        for l:=0 to sferi[k].mat_thick-1 do
        begin
          y:=y1-round(sqrt(temp))+l;
          //uslovie protiv obsidianovoy sferi
          if y>y1 then break;

          chunk.Blocks[x+z*16+y*256]:=mat_shell;
          if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;
          y:=y1+round(sqrt(temp))-l;
          chunk.Blocks[x+z*16+y*256]:=mat_shell;
          if (priznak=1)or(priznak=2) then chunk.Data[x+z*16+y*256]:=mat_data;

          //delaem vse s gribnoy sferoy
          if (priznak=20)and(l=0) then
          begin
            //delaem biome
            //if chunk.Biomes[x+z*16]=0 then chunk.Biomes[x+z*16]:=14;
            case chunk.Biomes[x+z*16] of
              0,2:chunk.Biomes[x+z*16]:=14;
            end;

            //opredelaem verhniy blok
            l1:=y1+round(sqrt(temp));
            while chunk.Blocks[x+z*16+(l1+1)*256]<>0 do
              inc(l1);
            chunk.Blocks[x+z*16+l1*256]:=110;

            //delaem ob'ekti
            //grib
            if (r_obsh.nextDouble<0.02)and(populated=false) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.5 then obj[l2].id:=16  //korichneviy bol'shoy grib
              else obj[l2].id:=17;  //krasniy bol'shoy grib
            end;
          end;

          //delaem vse so sferoy iz netherrack
          if (priznak=19)and(l=0) then
          begin
            //delaem biome
            chunk.Biomes[x+z*16]:=8;

            //opredelaem verhniy blok
            l1:=y1+round(sqrt(temp));
            while chunk.Blocks[x+z*16+(l1+1)*256]<>0 do
              inc(l1);

            //delaem ob'ekti
            //ogon'
            if (r_obsh.nextDouble<0.025)and(populated=false) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=10;   //ogon'
            end;
            //nether wart
            if (r_obsh.nextDouble<0.01)and(populated=false) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=21;   //nether wart
            end;
            //todo: sdelat' spauneri Blaze i Ghast
          end;

          //delaem vse so sferoy iz peska
          if (priznak>=10)and(priznak<=15)and(l=0) then
          begin
            //delaem biome
            if chunk.Biomes[x+z*16]=0 then chunk.Biomes[x+z*16]:=2;

            //delaem podderzhku esli est'
            if (priznak=11)or(priznak=13)or(priznak=15) then
            begin
              l1:=y1-round(sqrt(temp));
              while chunk.Blocks[x+z*16+(l1-1)*256]<>0 do
                dec(l1);
              case (sferi[k].parameter and $3) of
                1:chunk.Blocks[x+z*16+l1*256]:=82;
                2:chunk.Blocks[x+z*16+l1*256]:=24
                else chunk.Blocks[x+z*16+l1*256]:=12;
              end;
            end;

            //opredelaem verhniy blok
            l1:=y1+round(sqrt(temp));
            while chunk.Blocks[x+z*16+(l1+1)*256]<>0 do
              inc(l1);

            //delaem ob'ekti
            //kaktus
            if (r_obsh.nextDouble<0.05)and(populated=false) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=13;  //kaktus
            end;
            //mertviy kust ili trava v vide mertvogo kusta
            if (r_obsh.nextDouble<0.025)and(populated=false) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.1 then obj[l2].id:=2  //visohshaya trava
              else obj[l2].id:=5;  //visohshiy kust
            end;
          end;

          //delaem vse na sfere zemli
          if (l=0)and((priznak=3)or(priznak=4)or(priznak=5)or(priznak=6)) then
          begin
            l1:=y1+round(sqrt(temp));
            while chunk.Blocks[x+z*16+(l1+1)*256]<>0 do
              inc(l1);
            chunk.Blocks[x+z*16+l1*256]:=2;

            //prioritet u tundri
            case priznak of
              3:case chunk.Biomes[x+z*16] of
                  0,2,14:chunk.Biomes[x+z*16]:=1;
                end;
              4,5:case chunk.Biomes[x+z*16] of
                    0,2,14,1:chunk.Biomes[x+z*16]:=4;
                  end;
              6:case chunk.Biomes[x+z*16] of
                  0,2,14,1,4:chunk.Biomes[x+z*16]:=5;
                end;
            end;

            //TREESE---------------------------------------------
            //delaem derev'ya dla zemlanoy sferi s lesom
            if (r_obsh.nextDouble<0.02)and(populated=false)and(priznak=4)and(l1>(y1+r-r1)) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.3 then obj[l2].id:=24  //bereza
              else obj[l2].id:=22;  //obichnoe
            end;

            //delaem derev'ya dla zemlanoy sferi s Rainforest
            if (r_obsh.nextDouble<0.015)and(populated=false)and(priznak=5) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=23;  //bol'shoe derevo
            end;

            //delaem derev'ya dla zemlanoy sferi s tundroy
            if (r_obsh.nextDouble<0.015)and(populated=false)and(priznak=6) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.5 then obj[l2].id:=25
              else obj[l2].id:=26;
            end;

            //GRASS----------------------------------------------
            //delaem travu dla zemlanoy sferi s ravninoy
            if (r_obsh.nextDouble<0.3)and(populated=false)and(priznak=3) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=3;
            end;

            //delaem travu dla zemlanoy sferi s lesom
            if (r_obsh.nextDouble<0.1)and(populated=false)and(priznak=4) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=3;
            end;

            //delaem travu dla zemlanoy sferi s Rainforest
            if (r_obsh.nextDouble<0.035)and(populated=false)and(priznak=5) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=3;
            end;

            //delaem travu dla zemlanoy sferi s tundroy
            if (r_obsh.nextDouble<0.01)and(populated=false)and(priznak=6) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              obj[l2].id:=3;
            end;

            //FLOWERS--------------------------------------------
            //delaem cveti dla zemlanoy sferi s ravninoy
            if (r_obsh.nextDouble<0.0666)and(populated=false)and(priznak=3) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.2 then obj[l2].id:=7
              else obj[l2].id:=6;
            end;

            //delaem cveti dla zemlanoy sferi s lesom
            if (r_obsh.nextDouble<0.0222)and(populated=false)and(priznak=4) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.2 then obj[l2].id:=7
              else obj[l2].id:=6;
            end;

            //delaem cveti dla zemlanoy sferi s Rainforest
            if (r_obsh.nextDouble<0.00777)and(populated=false)and(priznak=5) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.2 then obj[l2].id:=7
              else obj[l2].id:=6;
            end;

            //delaem cveti dla zemlanoy sferi s tundroy
            if (r_obsh.nextDouble<0.00222)and(populated=false)and(priznak=6) then
            begin
              l2:=length(obj);
              setlength(obj,l2+1);
              obj[l2].z:=zkoord*16+z;
              obj[l2].x:=xkoord*16+x;
              obj[l2].y:=l1+1;
              if r_obsh.nextDouble<0.2 then obj[l2].id:=7
              else obj[l2].id:=6;
            end;
          end;
        end;

        //delaem zalivku sferi iz bedroka
        if (priznak=16) then
        begin
          case sferi[k].parameter of
          0:begin  //bez vsego, prosto zalivka bedrokom
              for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
                if chunk.Blocks[x+z*16+l*256]=0 then
                  chunk.Blocks[x+z*16+l*256]:=7;
            end;
          1:begin  //dungeon
              //vibiraem zalivku sverhu
              rand_sf:=rnd.Create(sferi[k].x*$1654 + sferi[k].y*$7614 + sferi[k].z*$3674 + sferi[k].radius);
              case rand_sf.nextInt(100) of
              0..32:begin    //2 sloya
                      for l:=y1 to y1+round(sferi[k].radius/3)+2 do
                      begin
                        if chunk.Blocks[x+z*16+l*256]<>0 then break;
                        if l=y1 then chunk.Blocks[x+z*16+l*256]:=48
                        else if l=y1+1 then chunk.Blocks[x+z*16+l*256]:=44
                        else chunk.Blocks[x+z*16+l*256]:=11;
                      end;
                    end;
              33..65:begin   //1/3 sferi
                       for l:=y1 to y1+round(sferi[k].radius/1.5) do
                       begin
                         if chunk.Blocks[x+z*16+l*256]<>0 then break;
                         if l=y1 then chunk.Blocks[x+z*16+l*256]:=48
                         else if l=y1+1 then chunk.Blocks[x+z*16+l*256]:=44
                         else chunk.Blocks[x+z*16+l*256]:=11;
                       end;
                     end;
              66..99:begin   //do potolka
                       for l:=y1 to y1+round(sqrt(temp)) do
                       begin
                         if chunk.Blocks[x+z*16+l*256]<>0 then break;
                         if l=y1 then chunk.Blocks[x+z*16+l*256]:=48
                         else if l=y1+1 then chunk.Blocks[x+z*16+l*256]:=44
                         else chunk.Blocks[x+z*16+l*256]:=11;
                       end;
                     end;
              end;
              rand_sf.Free;

              //delaem pol snizu
              for l:=y1-round(sqrt(temp)) to y1-sferi[k].radius+round(sferi[k].radius/3) do
                if chunk.Blocks[x+z*16+l*256]=0 then chunk.Blocks[x+z*16+l*256]:=1;

              //delaem peregorodku mezhdu nizom i oblast'yu spauna
              l2:=y1-round(sferi[k].radius/3);
              if ((y1-round(sqrt(temp)))<(l2))and(chunk.Blocks[x+z*16+l2*256]=0) then
                chunk.Blocks[x+z*16+l2*256]:=48;

              //delaem bedrok pod nizhney peregorodkoy
              l2:=y1-round(sferi[k].radius/3)-1;
              if ((y1-round(sqrt(temp)))<(l2))and(chunk.Blocks[x+z*16+l2*256]=0) then
                chunk.Blocks[x+z*16+l2*256]:=7;

              //delaem spawneri i dirki pod spaunerami
              l1:=round(sqrt(sqr(sferi[k].radius)/2)/2);  //sredniy otstup ot centra sferi
              //delaem dirki pod spawnerami
              if ((x=x1-l1)and(z=z1-l1))or((x=x1+l1)and(z=z1-l1))or
              ((x=x1-l1)and(z=z1+l1))or((x=x1+l1)and(z=z1+l1))and
              ((y1-round(sqrt(temp)))<(l2)) then chunk.Blocks[x+z*16+l2*256]:=0;
              //delaem spawneri
              if ((x=x1-l1)and(z=z1-l1))or((x=x1+l1)and(z=z1-l1))or
              ((x=x1-l1)and(z=z1+l1))or((x=x1+l1)and(z=z1+l1)) then
              begin
                //delaem sokrovisha
                {if r_obsh.nextDouble<0.2 then
                chunk.Blocks[x+z*16+(y1-round(sferi[k].radius/1.5)+1)*256]:=56
                else chunk.Blocks[x+z*16+(y1-round(sferi[k].radius/1.5)+1)*256]:=57;}
                l2:=length(obj);
                setlength(obj,l2+1);
                obj[l2].z:=zkoord*16+z;
                obj[l2].x:=xkoord*16+x;
                obj[l2].y:=y1-round(sferi[k].radius/1.5)+1;
                obj[l2].id:=31;

                //delaem spawneri
                l2:=length(obj);
                setlength(obj,l2+1);
                obj[l2].z:=zkoord*16+z;
                obj[l2].x:=xkoord*16+x;
                obj[l2].y:=y1-round(sferi[k].radius/3)+1;
                obj[l2].id:=27;
              end;
            end;
          2,3:begin  //trap  /  trap+treasure
                rand_sf:=rnd.Create(sferi[k].x*$1654 + sferi[k].y*$7614 + sferi[k].z*$3674 + sferi[k].radius);
                l2:=-1;
                case rand_sf.nextInt(75) of
                0..24:begin  //2 sloya sverhu, 1/3 radiusa snizu, ostalnoe steklo
                        for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
                        begin
                          if chunk.Blocks[x+z*16+l*256]<>0 then continue;
                          if (l>=y1)and(l<=(y1+round(sferi[k].radius/3)+2)) then
                            if l=y1 then chunk.Blocks[x+z*16+l*256]:=1
                            else if l=y1+1 then chunk.Blocks[x+z*16+l*256]:=44
                            else chunk.Blocks[x+z*16+l*256]:=11
                          else if (l<y1)and(l>y1-round(sferi[k].radius/1.5)) then
                            chunk.Blocks[x+z*16+l*256]:=20;
                        end;
                        l2:=1;
                      end;
                25..49:begin  //1/3 radiusa sferi sverhu, 1/3 radiusa sferi snizu
                         for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
                         begin
                           if chunk.Blocks[x+z*16+l*256]<>0 then continue;
                           if (l>=y1)and(l<=(y1+round(sferi[k].radius/1.5))) then
                             if l=y1 then chunk.Blocks[x+z*16+l*256]:=20
                             else if l=y1+1 then chunk.Blocks[x+z*16+l*256]:=44
                             else chunk.Blocks[x+z*16+l*256]:=11;
                         end;
                       end;
                50..74:begin   //2/3 radiusa sferi sverhu, 2/3 radiusa sferi snizu
                         for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
                         begin
                           if chunk.Blocks[x+z*16+l*256]<>0 then continue;
                           if (l>=(y1-round(sferi[k].radius/3))) then
                             if l=(y1-round(sferi[k].radius/3)) then chunk.Blocks[x+z*16+l*256]:=20
                             else if l=(y1-round(sferi[k].radius/3)+1) then chunk.Blocks[x+z*16+l*256]:=44
                             else chunk.Blocks[x+z*16+l*256]:=11;
                         end;
                       end;
                end;

                //delaem pol snizu
                for l:=y1-round(sqrt(temp)) to y1-sferi[k].radius+round(sferi[k].radius/3) do
                  if chunk.Blocks[x+z*16+l*256]=0 then chunk.Blocks[x+z*16+l*256]:=1;

                //delaem sokrovisha
                l:=y1-sferi[k].radius+round(sferi[k].radius/3);
                l1:=round(sqrt(sqr(sferi[k].radius)/2)/2);  //sredniy otstup ot centra sferi
                if (((x=x1-l1)and(z=z1-l1))or((x=x1+l1)and(z=z1-l1))or
                ((x=x1-l1)and(z=z1+l1))or((x=x1+l1)and(z=z1+l1)))and
                (sferi[k].parameter=3) then
                begin
                  //chunk.Blocks[x+z*16+(l+1)*256]:=46;
                  //chunk.Blocks[x+z*16+(l+2)*256]:=57;
                  l2:=length(obj);
                  setlength(obj,l2+1);
                  obj[l2].z:=zkoord*16+z;
                  obj[l2].x:=xkoord*16+x;
                  obj[l2].y:=l+1;
                  obj[l2].id:=31;
                end;
                //delaem lovushki k sokrovisham
                {if ((((x=x1-l1-2)or(x=x1-l1+2))and(z=z1-l1))or
                (((x=x1+l1-2)or(x=x1+l1+2))and(z=z1-l1))or
                ((x=x1-l1)and((z=z1-l1-2)or(z=z1-l1+2)))or
                ((x=x1+l1)and((z=z1-l1-2)or(z=z1-l1+2)))or
                (((x=x1-l1-2)or(x=x1-l1+2))and(z=z1+l1))or
                (((x=x1+l1-2)or(x=x1+l1+2))and(z=z1+l1))or
                ((x=x1-l1)and((z=z1+l1+2)or(z=z1+l1-2)))or
                ((x=x1+l1)and((z=z1+l1+2)or(z=z1+l1-2))))and
                (sferi[k].parameter=3) then
                begin
                  chunk.Blocks[x+z*16+(l+1)*256]:=75;
                  chunk.Data[x+z*16+(l+1)*256]:=5;
                end;  }
              end;
          end;

          //delaem vhod
          for l:=0 downto -2 do
          if (x>=x1-(l+4))and(x<=x1+(l+4))and(z>=z1-(l+4))and(z<=z1+(l+4)) then
          begin
            chunk.Blocks[x+z*16+(y1+round(sferi[k].radius/3)+l)*256]:=7;
            if l=-2 then chunk.Blocks[x+z*16+(y1+round(sferi[k].radius/3)+l-1)*256]:=7;
          end;

          for l:=y1+round(sferi[k].radius/3) downto y1-round(sqrt(temp)) do
          if (x=x1)and(z=z1) then
            if l=y1+round(sferi[k].radius/3) then chunk.Blocks[x+z*16+l*256]:=1
            else chunk.Blocks[x+z*16+l*256]:=0
          else if (((x=x1-1)or(x=x1+1))and(z=z1))or
          (((z=z1-1)or(z=z1+1))and(x=x1)) then chunk.Blocks[x+z*16+l*256]:=7;

          if (((x=x1-1)or(x=x1+1))and(z<=z1+1)and(z>=z1-1))or
          (((z=z1-1)or(z=z1+1))and(x<=x1+1)and(x>=x1-1)) then
          begin
            l:=y1+round(sferi[k].radius/3)-1;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-2;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-3;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-4;
            chunk.Blocks[x+z*16+l*256]:=7;
          end;
        end;

        //delaem zalivku s biosferoy
        if (priznak=24)or(priznak=27) then
        begin
          //delaem sloi zemli i zalivki
          for l:=y1-round(sqrt(temp)) to y1-1 do
          if chunk.Blocks[x+z*16+l*256]=0 then
          if (l<y1-3) then
          begin
            case r_obsh.nextInt(7000) of
            0..19:chunk.Blocks[x+z*16+l*256]:=56;
            20..69:chunk.Blocks[x+z*16+l*256]:=15;
            70..99:chunk.Blocks[x+z*16+l*256]:=14
            else chunk.Blocks[x+z*16+l*256]:=mat_fill;
            end;
          end
          else if (l<y1-1) then chunk.Blocks[x+z*16+l*256]:=3
          else chunk.Blocks[x+z*16+l*256]:=2;

          //delaem prud v centre
          l1:=(sferi[k].radius shr 2);  //radius pruda
          for l:=y1-2-l1 to y1-1 do
          begin
            //po y
            l2:=sqr(l1)-sqr(x-x1)-sqr(z-z1);
            if (l2>=0){and(x>round(x1-(l1/3)))and((x<round(x1+(l1/3))))} then
            begin
              temp:=sqr(l1+2)-sqr(x-x1)-sqr(z-z1);
              temp:=round(sqrt(temp));
              l2:=round(sqrt(l2));

              if (l>=y1-1-temp)and(l<=y1-1+temp)and(chunk.Blocks[x+z*16+l*256]=mat_fill) then chunk.Blocks[x+z*16+l*256]:=3;
              if (l>=y1-1-l2)and(l<=y1-1+l2) then chunk.Blocks[x+z*16+l*256]:=9;
            end;
            //po x
            l2:=sqr(l1)-sqr(z-z1)-sqr(l-y1+1);
            if (l2>=0)and(l>round(y1-1-l2/3))and(l<round(y1-1+l2/3)) then
            begin
              temp:=sqr(l1+2)-sqr(z-z1)-sqr(l-y1+1);
              temp:=round(sqrt(temp));
              l2:=round(sqrt(l2));

              if (x>=x1-temp)and(x<=x1+temp)and(chunk.Blocks[x+z*16+l*256]=mat_fill) then chunk.Blocks[x+z*16+l*256]:=3;
              if (x>=x1-l2)and(x<=x1+l2) then chunk.Blocks[x+z*16+l*256]:=9;

              //delaem trostnik
              if l=y1-1 then
              if ((x>=x1-temp)and(x<=x1+temp))and(populated=false)and(chunk.Blocks[x+z*16+l*256]=2)and(r_obsh.nextDouble<0.4) then
              begin
                l2:=length(obj);
                setlength(obj,l2+1);
                obj[l2].z:=zkoord*16+z;
                obj[l2].x:=xkoord*16+x;
                obj[l2].y:=y1;
                obj[l2].id:=14;
              end;
            end;
            //po z
            l2:=sqr(l1)-sqr(x-x1)-sqr(l-y1+1);
            if (l2>=0)and(l>round(y1-1-l2/3))and(l<round(y1-1+l2/3)) then
            begin
              temp:=sqr(l1+2)-sqr(x-x1)-sqr(l-y1+1);
              temp:=round(sqrt(temp));
              l2:=round(sqrt(l2));

              if (z>=z1-temp)and(z<=z1+temp)and(chunk.Blocks[x+z*16+l*256]=mat_fill) then chunk.Blocks[x+z*16+l*256]:=3;
              if (z>=z1-l2)and(z<=z1+l2) then chunk.Blocks[x+z*16+l*256]:=9;

              //delaem trostnik
              if l=y1-1 then
              if ((z>=z1-temp)and(z<=z1+temp))and(populated=false)and(chunk.Blocks[x+z*16+l*256]=2)and(r_obsh.nextDouble<0.4) then
              begin
                l2:=length(obj);
                setlength(obj,l2+1);
                obj[l2].z:=zkoord*16+z;
                obj[l2].x:=xkoord*16+x;
                obj[l2].y:=y1;
                obj[l2].id:=14;
              end;
            end;
          end;


          //delaem ob'ekti osvesheniya
          //fakel na zemle
          if (r_obsh.nextDouble<0.04)and(populated=false)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            obj[l2].id:=30;
          end;
          //visashiy fakel
          if (r_obsh.nextDouble<0.045)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0)and(priznak=24) then
          begin
            l1:=y1;
            while (chunk.Blocks[x+z*16+(l1+1)*256]=0) do
              inc(l1);

            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            //obj[l2].y:=y1+round(sqrt(temp))-sferi[k].mat_thick;
            obj[l2].y:=l1;
            obj[l2].id:=30;
          end;
          //pautina
          if (r_obsh.nextDouble<0.03)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l1:=y1;
            while (chunk.Blocks[x+z*16+(l1+1)*256]=0) do
              inc(l1);

            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            //obj[l2].y:=y1+round(sqrt(temp))-sferi[k].mat_thick;
            obj[l2].y:=l1;
            obj[l2].id:=1;
          end;
          //liliya
          if (r_obsh.nextDouble<0.04)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=9)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            obj[l2].id:=20;
          end;
          //derevo
          if (r_obsh.nextDouble<0.025)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            if r_obsh.nextDouble<0.4 then obj[l2].id:=24
            else obj[l2].id:=22;
          end;
          //trava
          if (r_obsh.nextDouble<0.1)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            obj[l2].id:=3;
          end;
          //cveti
          if (r_obsh.nextDouble<0.028)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            if r_obsh.nextDouble<0.2 then obj[l2].id:=7
            else obj[l2].id:=6;
          end;
          //gribi
          if (r_obsh.nextDouble<0.017)and(populated=false)and(chunk.Blocks[x+z*16+(y1-1)*256]=2)and(chunk.Blocks[x+z*16+y1*256]=0) then
          begin
            l2:=length(obj);
            setlength(obj,l2+1);
            obj[l2].z:=zkoord*16+z;
            obj[l2].x:=xkoord*16+x;
            obj[l2].y:=y1;
            if r_obsh.nextDouble<0.5 then obj[l2].id:=8
            else obj[l2].id:=9;
          end;
        end;

        //delaem zalivku sferi s dungeon
        if (priznak=9) then
        begin
          rand_sf:=rnd.Create(sferi[k].x*$1654 + sferi[k].y*$7614 + sferi[k].z*$3674 + sferi[k].radius);
          l1:=rand_sf.nextInt(2)+6;  //visota 6-7 blokov
          if l1=7 then l2:=4
          else if l1=6 then l2:=3;    

          for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
          if chunk.Blocks[x+z*16+l*256]=0 then
          if (x<x1-l2)or(x>x1+l2)or(z<z1-l2)or(z>z1+l2)or
          (l>y1+(l1 shr 1))or((l<y1-(l1 shr 1))and((l1 and 1)=1))or
          ((l<y1-(l1 shr 1)+1)and((l1 and 1)=0)) then chunk.Blocks[x+z*16+l*256]:=mat_fill
          else if (x=x1-l2)or(x=x1+l2)or(z=z1-l2)or(z=z1+l2)or
          (l=y1+(l1 shr 1))or((l=y1-(l1 shr 1))and((l1 and 1)=1))or
          ((l=y1-(l1 shr 1)+1)and((l1 and 1)=0))
          then chunk.Blocks[x+z*16+l*256]:=48;

          //delaem ob'ekti
          //spawner
          if (x=x1)and(z=z1)and(populated=false) then
          begin
            temp:=length(obj);
            setlength(obj,temp+1);
            obj[temp].z:=zkoord*16+z;
            obj[temp].x:=xkoord*16+x;
            if (l1 and 1)=0 then obj[temp].y:=y1-(l1 shr 1)+2
            else obj[temp].y:=y1-(l1 shr 1)+1;
            obj[temp].id:=27;
          end;
          //sunduk
          if (x=x1)and(z=z1)and(populated=false) then
          begin
            temp:=length(obj);
            setlength(obj,temp+1);
            case rand_sf.nextInt(4) of
              3:begin
                  obj[temp].z:=zkoord*16+z-(l2-1);
                  obj[temp].x:=xkoord*16+x;
                end;
              1:begin
                  obj[temp].z:=zkoord*16+z+(l2-1);
                  obj[temp].x:=xkoord*16+x;
                end;
              2:begin
                  obj[temp].z:=zkoord*16+z;
                  obj[temp].x:=xkoord*16+x-(l2-1);
                end;
              0:begin
                  obj[temp].z:=zkoord*16+z;
                  obj[temp].x:=xkoord*16+x+(l2-1);
                end;
            end;
            if (l1 and 1)=0 then obj[temp].y:=y1-(l1 shr 1)+2
            else obj[temp].y:=y1-(l1 shr 1)+1;
            obj[temp].id:=28;
          end;
          rand_sf.Free;
        end;

        //delaem zalivku s data_value dla derevannoy sferi, peschanoy sferi i ledanoy sferi
        if (priznak=1)or(priznak=2) then
        begin
          mat_data:=sferi[k].parameter and $3;
          for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
          begin
            if (chunk.Blocks[x+z*16+l*256]=0) then
            begin
              chunk.Blocks[x+z*16+l*256]:=mat_fill;
              chunk.Data[x+z*16+l*256]:=mat_data;
            end;
          end;
        end;

        //delaem zalivku peschanoy sferi s kamnem ili miksom
        if (priznak=12)or(priznak=13)or(priznak=14)or(priznak=15) then
        begin
          if (priznak=12)or(priznak=13) then  //kamen'
          begin
            mat_data:=(sferi[k].parameter and $60)shr 5;
            for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
            begin
              if (chunk.Blocks[x+z*16+l*256]=0) then
              begin
                chunk.Blocks[x+z*16+l*256]:=mat_fill;
                chunk.Data[x+z*16+l*256]:=mat_data;
              end;
            end;
          end
          else  //miks
          begin
            for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
              if (chunk.Blocks[x+z*16+l*256]=0) then
                if r_obsh.nextDouble<0.5 then chunk.Blocks[x+z*16+l*256]:=12
                else chunk.Blocks[x+z*16+l*256]:=24;
          end;
        end;

        //delaem zalivku pustoy sferi glowstone s odnim sloem stekla
        if priznak=23 then
        for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
        begin
          if ((chunk.Blocks[x+z*16+(l-1)*256]=mat_shell)or
          (chunk.Blocks[x+z*16+(l+1)*256]=mat_shell))and
          (chunk.Blocks[x+z*16+l*256]=0) then chunk.Blocks[x+z*16+l*256]:=mat_fill;

          l1:=r*r-sqr(z-z1)-sqr(l-y1);
          if l1>=0 then
          begin
            l2:=x1-round(sqrt(l1))+sferi[k].mat_thick;
            if (l2>=0)and(l2<=15) then
              if chunk.Blocks[l2+z*16+l*256]=0 then chunk.Blocks[l2+z*16+l*256]:=mat_fill;
            l2:=x1+round(sqrt(l1))-sferi[k].mat_thick;
            if (l2>=0)and(l2<=15) then
              if chunk.Blocks[l2+z*16+l*256]=0 then chunk.Blocks[l2+z*16+l*256]:=mat_fill;
          end;

          l1:=r*r-sqr(x-x1)-sqr(l-y1);
          if l1>=0 then
          begin
            l2:=z1-round(sqrt(l1))+sferi[k].mat_thick;
            if (l2>=0)and(l2<=15) then
              if chunk.Blocks[x+l2*16+l*256]=0 then chunk.Blocks[x+l2*16+l*256]:=mat_fill;
            l2:=z1+round(sqrt(l1))-sferi[k].mat_thick;
            if (l2>=0)and(l2<=15) then
              if chunk.Blocks[x+l2*16+l*256]=0 then chunk.Blocks[x+l2*16+l*256]:=mat_fill;
          end;
        end;

        //delaem zalivku sferi iz kamna s miksom
        if priznak=22 then
        for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
          if (chunk.Blocks[x+z*16+l*256]=0) then
          begin
            l2:=1;
            case r_obsh.nextInt(74283) of
              0..7856:l2:=1;  //stone
              7857..20713:l2:=16;  //coal
              20714..32141:l2:=15;  //iron
              32142..41426:l2:=14;  //gold
              41427..45715:l2:=56;  //diamond
              45716..50000:l2:=21;  //lapis lazuli
              50001..56428:l2:=73;  //redstone
              56429..68568:l2:=13;  //gravel
              68569..71425:l2:=9;  //water
              71426..74282:l2:=11;  //lava
            end;
            chunk.Blocks[x+z*16+l*256]:=l2;
          end;

        //delaem zalivku obichnoy sferi do kraev bez data_value
        if (priznak=3)or(priznak=4)or(priznak=5)or(priznak=6)or(priznak=10)or(priznak=11)or(priznak=19)or(priznak=20)or(priznak=8) then
        for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
          if (chunk.Blocks[x+z*16+l*256]=0) then chunk.Blocks[x+z*16+l*256]:=mat_fill;

        //delaem zalivku steklannoy i ledanoy sferi s reguliruemim urovnem
        if (priznak=7)or(priznak=17) then
          for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
            if (chunk.Blocks[x+z*16+l*256]=0)and(l<(y1-r+sferi[k].fill_level)) then chunk.Blocks[x+z*16+l*256]:=mat_fill;

        //delaem zalivku ledanoy sferi s osoboy zalivkoy
        if priznak=18 then
        begin
          for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
            if (chunk.Blocks[x+z*16+l*256]=0)and(l<(y1-r+sferi[k].fill_level)) then
              if l=(y1-r+sferi[k].fill_level-1) then chunk.Blocks[x+z*16+l*256]:=mat_fill
              else chunk.Blocks[x+z*16+l*256]:=9;
        end;

        //delaem dirku vnizu steklannoy sferi
        if (priznak=7)and(x=x1)and(z=z1) then
        begin
          l:=y1-round(sqrt(temp))+sferi[k].mat_thick;
          l2:=chunk.Blocks[x+z*16+l*256];
          if l2<>0 then
            dec(l2)
          else
            l2:=0;

          for l:=y1-round(sqrt(temp))+sferi[k].mat_thick downto y1-round(sqrt(temp))-1 do
          begin
            chunk.Blocks[x+z*16+l*256]:=l2;
            if l2=10 then chunk.Data[x+z*16+l*256]:=8;
          end;
        end;

        //delaem vhod v sferu iz bedroka
        if (priznak=16) then
        begin
          for l:=0 downto -2 do
          if (x>=x1-(l+4))and(x<=x1+(l+4))and(z>=z1-(l+4))and(z<=z1+(l+4)) then
          begin
            chunk.Blocks[x+z*16+(y1+round(sferi[k].radius/3)+l)*256]:=7;
            if l=-2 then chunk.Blocks[x+z*16+(y1+round(sferi[k].radius/3)+l-1)*256]:=7;
          end;

          for l:=y1+round(sferi[k].radius/3) downto y1-round(sqrt(temp)) do
          if (x=x1)and(z=z1) then
            if l=y1+round(sferi[k].radius/3) then chunk.Blocks[x+z*16+l*256]:=1
            else chunk.Blocks[x+z*16+l*256]:=0
          else if (((x=x1-1)or(x=x1+1))and(z=z1))or
          (((z=z1-1)or(z=z1+1))and(x=x1)) then chunk.Blocks[x+z*16+l*256]:=7;

          if (((x=x1-1)or(x=x1+1))and(z<=z1+1)and(z>=z1-1))or
          (((z=z1-1)or(z=z1+1))and(x<=x1+1)and(x>=x1-1)) then
          begin
            l:=y1+round(sferi[k].radius/3)-1;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-2;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-3;
            chunk.Blocks[x+z*16+l*256]:=0;
            l:=y1+round(sferi[k].radius/3)-4;
            if chunk.Blocks[x+z*16+l*256]=11 then
              chunk.Blocks[x+z*16+l*256]:=7;
          end;
        end;

        {//delaem travu sverhu zemlanoy sferi tam, gde uzhe est' material, t.k. on mozhet i ne proyti po usloviyu temp<0
        if chunk.Blocks[x+z*16+y1*256]=3 then
        begin
          l:=y1+1;
          while (chunk.Blocks[x+z*16+l*256]<>0) do
            inc(l);
          chunk.Blocks[x+z*16+(l-1)*256]:=2;
        end;

        //delaem glinu vnizu peschanih sfer
        if (chunk.Blocks[x+z*16+y1*256]=12)and(sferi[k].parameter=1) then
        begin
          l:=y1-1;
          while (chunk.Blocks[x+z*16+l*256]<>0) do
            dec(l);
          chunk.Blocks[x+z*16+(l+1)*256]:=82;
        end;

        if temp<0 then continue;
        for l:=0 to sferi[k].mat_thick-1 do
        begin
          y:=y1-round(sqrt(temp))+l;
          chunk.Blocks[x+z*16+y*256]:=mat_shell;
          y:=y1+round(sqrt(temp))-l;
          chunk.Blocks[x+z*16+y*256]:=mat_shell;

          if l=0 then
          begin
            if mat_shell=3 then
            begin
              l1:=y;
              while chunk.Blocks[x+z*16+(l1+1)*256]<>0 do
                inc(l1);
              chunk.Blocks[x+z*16+l1*256]:=2;
            end;
            if mat_shell=12 then
            begin
              if sferi[k].parameter=1 then
              begin
                l1:=y1-round(sqrt(temp));
                while chunk.Blocks[x+z*16+(l1-1)*256]<>0 do
                  dec(l1);
                chunk.Blocks[x+z*16+l1*256]:=82;
              end;
              
            end;
          end;
        end;

        //delaem zalivku sfer
        for l:=y1-round(sqrt(temp)) to y1+round(sqrt(temp)) do
        begin
          if l>(y1-sferi[k].radius+sferi[k].fill_level) then break;
          if (chunk.Blocks[x+z*16+l*256]=0) then chunk.Blocks[x+z*16+l*256]:=mat_fill;
        end;

        //delaem dirku v sfere s vodoy
        if (mat_shell=20)and(sferi[k].fill_level>sferi[k].mat_thick)and
        (x=x1)and(z=z1) then
          for l:=y1-round(sqrt(temp))-1 to y1-round(sqrt(temp))+sferi[k].mat_thick do
            chunk.Blocks[x+z*16+l*256]:=8;   }
      end;

    //random1.Free;
  end;

  //delaem nizhniy bedrock dla testa
  {for x:=0 to 15 do
    for z:=0 to 15 do
      for y:=0 to 5 do
        chunk.Blocks[x+z*16+y*256]:=7;

  //delaem verhniy bedrok dla testa rascheta sveta
  for x:=0 to 15 do
    for z:=0 to 15 do
      chunk.Blocks[x+z*16+254*256]:=7;

  if (xkoord=0)and(zkoord=0) then
  begin
    chunk.Blocks[3+16+254*256]:=0;
    chunk.Blocks[3+16+242*256]:=1;
  end;    }
end;

procedure clear_dynamic;
var i:integer;
begin
  //ochishaem pamat' ot chanka
  //ne ochishaem t.k. vozmozhno iz za etogo voznikaet oshibka
  setlength(chunk.Biomes,0);
  setlength(chunk.Blocks,0);
  setlength(chunk.Data,0);
  setlength(chunk.Add_id,0);
  setlength(chunk.Skylight,0);
  setlength(chunk.Light,0);
  setlength(chunk.Entities,0);
  setlength(chunk.Tile_entities,0);

  for i:=0 to length(sferi)-1 do
    setlength(sferi[i].chunks,0);
  setlength(sferi,0);

  setlength(obj,0);

  if r_obsh<>nil then
  begin
    r_obsh.Free;
    r_obsh:=nil;
  end;
end;

function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
var x,y,z,t,i,j,kol,t1:integer;
mat:integer;
b:boolean;
//r:rnd;
regx_nach,regx,regy_nach,regy:integer;
fromx,fromy,tox,toy:integer;
otx,dox,oty,doy:integer;
shag,shag_16:cardinal;
time:integer;

x_reg_min,x_reg_max,y_reg_min,y_reg_max:integer;

temp_sfera:TSphere;
intersect_sferi:TSphere_ar;
region_sferi:TSphere_ar;
stopping:boolean;

  procedure check_stop;
  begin
    if stopped=true then
    begin
      setlength(intersect_sferi,0);
      setlength(region_sferi,0);
      stopping:=true;
    end;
  end;

begin
  //nachalnie prisvoeniya
  r_obsh:=rnd.Create;
  obsh_sid:=gen_set.SID;
  stopped:=false;
  stopping:=false;
  crc_rasch:=1;
  crc_rasch_man:=-1;
  setlength(sferi,0);
  setlength(intersect_sferi,0);
  setlength(obj,0);
  shag:=$3FFF;
  shag_16:=(shag shl 4) or $F;
  //shag:=1023;
  time:=getcurrenttime;
  //vichislaem izmenennuyu distanciyu
  //t1:=round(distance+(distance/100*((95-planet_density)/1.5)));
  t1:=round(distance/100*((100-planet_density)*5));

  //soobshenie ob ochishenii paneli
  postmessage(app_hndl,WM_USER+300,plugin_settings.plugin_type and 7,0);

  //peredaem soobshenie o smene leybla
  mess_str:='Initializing planetoids generator';
  mess_to_manager:=pchar(mess_str);
  postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),4);

  //videlaem pamat' pod chank
  setlength(chunk.Biomes,256);
  setlength(chunk.Blocks,65536);
  setlength(chunk.Data,65536);
  setlength(chunk.Add_id,0);
  setlength(chunk.Skylight,0);
  setlength(chunk.Light,0);
  setlength(chunk.Entities,0);
  setlength(chunk.Tile_entities,0);
  chunk.Has_additional_id:=false;
  chunk.has_skylight:=false;
  chunk.has_blocklight:=false;

  //messagebox(app_hndl,pchar('CRC reseived='+inttohex(crc_manager,16)),'Message',mb_ok);
  //proveraem avtorizaciyu
  t:=crc_manager and $FFFFFFFF;  //opredelayushee chislo
  x:=crc_manager shr 32;     //izmenennoe CRC
  //vichislaem CRC ot infi
  calcCRC32(@plugin_settings,sizeof(plugin_settings),y);
  //messagebox(app_hndl,pchar('CRC nachalnoe='+inttohex(y,8)),'Message',mb_ok);
  //sozdaem random s sidom iz CRC
  //r:=rnd.Create(y);
  r_obsh.SetSeed(y);
  //vichislaem kol-vo vizovov randoma
  mat:=((t shr 4)and 1)+((t shr 13) and 2)+((t shr 18)and 4)+((t shr 26) and 8);
  //delaem opredelennoe kol-vo vizivov randoma
  for z:=1 to mat do
    r_obsh.nextInt;
  t:=r_obsh.nextInt;
  //messagebox(app_hndl,pchar('CRC izmenennoe='+inttohex(t,8)+#13+#10+'CRC izmenennoe iz menedgera='+inttohex(x,8)),'Message',mb_ok);
  //r.Free;

  //sohranaem 2 znacheniya do buduyushih ispolzovaniy
  crc_rasch:=t;
  crc_rasch_man:=x;

  //zapolnaem v sootvetstvii so sloyami
  zeromemory(chunk.Biomes,length(chunk.Biomes));
  zeromemory(chunk.Blocks,length(chunk.Blocks));
  zeromemory(chunk.Data,length(chunk.Data));

  //generaciya planet
  begin  
    //delaem random
    //r:=rnd.Create(gen_set.SID);
    r_obsh.SetSeed(gen_set.SID);

    //opredelaem kol-vo region faylov, kotoroe sozdavat
    x:=gen_set.Width;      //kol-vo chankov po osam
    y:=gen_set.Length;

    fromx:=-(x shr 1);
    tox:=(x shr 1)-1;
    fromy:=-(y shr 1);
    toy:=(y shr 1)-1;

    //zapisivaem kraynie chanki dla generacii steni
    fromx_obsh:=fromx;
    fromy_obsh:=fromy;
    tox_obsh:=tox;
    toy_obsh:=toy;

    regx:=(x shr 6);    //(x div 2) div 32
    if ((x shr 1) and $1F)<>0 then inc(regx);  //((x div 2) mod 32)
    regx_nach:=-regx;
    regx:=regx shl 1; //regx*2

    regy:=(y shr 6);   //(tempy div 2) div 32
    if ((y shr 1) and $1F)<>0 then inc(regy);  //((tempy div 2) mod 32)
    regy_nach:=-regy;
    regy:=regy shl 1;  //regy*2

    x:=(tox-fromx+1)*(toy-fromy+1);  //kol-vo chankov v regione
    y:=(size_max+size_min) div 2;  //sredniy radius sfer
    z:=(spawn_max+y)-(spawn_min-y);  //kol-vo blokov po vertikali, v kotorih mogut spaunitsa sferi (uchitivaya sredniy radius)

    y:=size_min+distance;  //minimalniy radius sferi + minimalnoe rasstoyanie mezhdu sferami
    y:=y*y*y;  //minimal'niy ob'em sferi

    z:=round((x/y*256/100*z)*planet_density*1.5);   //maksimal'noe kol-vo sfer s uchetom plotnosti
     
    //ustanavluvaem progress bar
    postmessage(app_hndl,WM_USER+301,0,0);  //sbros
    postmessage(app_hndl,WM_USER+302,z,0);  //ustanovka maksimuma
    //ustanovka skvoznogo schetchika sfer
    kol:=0;
    //ustanovka leyblov na paneli
    mess_str:='Generating sphere';
    mess_to_manager:=pchar(mess_str);
    postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),1);
    mess_str:='out of '+inttostr(z);
    mess_to_manager:=pchar(mess_str);
    postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),3);
    postmessage(app_hndl,WM_USER+304,0,0);  //chislo

    //idem po regionam
    for i:=regx_nach to regx_nach+regx-1 do
      for j:=regy_nach to regy_nach+regy-1 do
      begin
        //izmenaem leybl o tom, dla kakogo regiona mi generim sferi
        mess_str:='Generating spheres for region '+inttostr(i)+','+inttostr(j);
        mess_to_manager:=pchar(mess_str);
        postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),4);

        t:=1;
        if (i<0)and(j>=0) then t:=2
        else if (i<0)and(j<0) then t:=3
        else if (i>=0)and(j<0) then t:=4;

        case t of
        1:begin
            //po osi X
            if i=regx_nach+regx-1 then
            begin
              otx:=0;
              dox:=tox mod 32;
            end
            else
            begin
              otx:=0;
              dox:=31;
            end;
            //po osi Y
            if j=regy_nach+regy-1 then
            begin
              oty:=0;
              doy:=toy mod 32;
            end
            else
            begin
              oty:=0;
              doy:=31;
            end;
          end;
        2:begin
            //po osi X
            if (i=regx_nach)and((fromx mod 32)<>0) then
            begin
              otx:=32+(fromx mod 32);
              dox:=31;
            end
            else
            begin
              otx:=0;
              dox:=31;
            end;
            //po osi Y
            if j=regy_nach+regy-1 then
            begin
              oty:=0;
              doy:=toy mod 32;
            end
            else
            begin
              oty:=0;
              doy:=31;
            end;
          end;
        3:begin
            //po osi X
            if (i=regx_nach)and((fromx mod 32)<>0) then
            begin
              otx:=32+(fromx mod 32);
              dox:=31;
            end
            else
            begin
              otx:=0;
              dox:=31;
            end;
            //po osi Y
            if (j=regy_nach)and((fromy mod 32)<>0) then
            begin
              oty:=32+(fromy mod 32);
              doy:=31;
            end
            else
            begin
              oty:=0;
              doy:=31;
            end;
          end;
        4:begin
            //po osi X
            if i=regx_nach+regx-1 then
            begin
              otx:=0;
              dox:=tox mod 32;
            end
            else
            begin
              otx:=0;
              dox:=31;
            end;
            //po osi Y
            if (j=regy_nach)and((fromy mod 32)<>0) then
            begin
              oty:=32+(fromy mod 32);
              doy:=31;
            end
            else
            begin
              oty:=0;
              doy:=31;
            end;
          end;
        end;

        //opredelenie granic obshih koordinat regiona dla peresecheniya
        x_reg_min:=i*512;
        x_reg_max:=x_reg_min+511;
        y_reg_min:=j*512;
        y_reg_max:=y_reg_min+511;
        inc(x_reg_min,32);
        dec(x_reg_max,32);
        inc(y_reg_min,32);
        dec(y_reg_max,32);

        x:=(dox-otx+1)*(doy-oty+1);  //kol-vo chankov v regione
        y:=(size_max+size_min) div 2;  //sredniy radius sfer
        z:=(spawn_max+y)-(spawn_min-y);  //kol-vo blokov po vertikali, v kotorih mogut spaunitsa sferi (uchitivaya sredniy radius)
        x:=x*256*z;  //primerniy ob'em blokov v regione, v kotorih mogut spaunitsa sferi

        y:=size_min+distance;  //minimalniy radius sferi + minimalnoe rasstoyanie mezhdu sferami
        y:=y*y*y;  //minimal'niy ob'em sferi

        z:=round(x/y);  //maksimalnoe kol-vo sfer, kotoroe mozhno sozdat' v regione (100%)
        z:=round((z/100)*planet_density*1.5);   //maksimal'noe kol-vo sfer s uchetom plotnosti
        //postmessage(app_hndl,WM_USER+307,999,z);

        //ochishaem chanki vremennoy sferi
        setlength(temp_sfera.chunks,0);
        //ochishaem massiv sfer tekushego regiona
        setlength(region_sferi,0);
        //sozdaem sferi i zaodno proveraem, peresekayutsa oni ili net
        //y:=length(sferi);
        for x:=0 to z-1 do
        begin
          //izmenaem progress bar menedgera
          inc(kol);
          if (kol and shag)=0 then
          begin
            //time:=getcurrenttime-time;
            {if time>200 then
            begin
              if shag>70 then shag:=shag shr 1;
              postmessage(app_hndl,WM_USER+307,123456,shag);
            end;    }

            postmessage(app_hndl,WM_USER+303,kol,0);  //position
            postmessage(app_hndl,WM_USER+304,kol,0);  //chislo   

            //proverka na ostanovku
            check_stop;
            if stopping=true then
            begin
              //r.Free;
              //result:=true;
              result:=false;
              postmessage(app_hndl,WM_USER+310,0,0);  //soobshenie ob uspeshnoy ostanovke
              exit;
            end;
          end;

          if (kol and shag_16)=0 then
          begin
            time:=getcurrenttime-time;
            if time>400*16 then
            begin
              if shag>70 then
              begin
                shag:=shag shr 1;
                shag_16:=(shag shl 4) or $F;
              end;
              postmessage(app_hndl,WM_USER+307,123456,shag);
            end;
            time:=getcurrenttime;
          end;

          temp_sfera.x:=r_obsh.nextInt((dox-otx+1)*16)+(otx*16);
          temp_sfera.z:=r_obsh.nextInt((doy-oty+1)*16)+(oty*16);
          temp_sfera.y:=r_obsh.nextInt(spawn_max-spawn_min)+spawn_min;
          temp_sfera.radius:=r_obsh.nextInt(size_max-size_min)+size_min;

          //perevod koordinat v obshie
          if i<0 then temp_sfera.x:=((i+1)*512-(512-temp_sfera.x))
          else temp_sfera.x:=(i*512)+temp_sfera.x;
          if j<0 then temp_sfera.z:=((j+1)*512-(512-temp_sfera.z))
          else temp_sfera.z:=(j*512)+temp_sfera.z;

          //proverka na peresechenie so sferami v tekushem regione
          b:=false;
          for t:=0 to length(region_sferi)-1 do
            if ((region_sferi[t].x-region_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.x)and
            ((region_sferi[t].x+region_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.x)and
            ((region_sferi[t].z-region_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.z)and
            ((region_sferi[t].z+region_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.z)and
            ((region_sferi[t].y-region_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.y)and
            ((region_sferi[t].y+region_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.y) then
            begin
              b:=true;
              break;
            end;
          if b=true then continue;

          //proverka na peresechenie so sferami, kotorie nahodatsa na granicah regionov
          b:=false;
          for t:=0 to length(intersect_sferi)-1 do
            if ((intersect_sferi[t].x-intersect_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.x)and
            ((intersect_sferi[t].x+intersect_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.x)and
            ((intersect_sferi[t].z-intersect_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.z)and
            ((intersect_sferi[t].z+intersect_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.z)and
            ((intersect_sferi[t].y-intersect_sferi[t].radius-temp_sfera.radius-t1)<temp_sfera.y)and
            ((intersect_sferi[t].y+intersect_sferi[t].radius+temp_sfera.radius+t1)>temp_sfera.y) then
            begin
              b:=true;
              break;
            end;
          if b=true then continue;

          //proverka na vihod za granici karti
          if ((temp_sfera.x-temp_sfera.radius-distance)<(fromx shl 4))or
          ((temp_sfera.x+temp_sfera.radius+distance)>(((tox+1) shl 4)-1))or
          ((temp_sfera.z-temp_sfera.radius-distance)<(fromy shl 4))or
          ((temp_sfera.z+temp_sfera.radius+distance)>(((toy+1) shl 4)-1)) then continue;

          //proverka na vihod za granici visot
          if ((temp_sfera.y-temp_sfera.radius)<(ground_level+5))or((temp_sfera.y+temp_sfera.radius)>250) then continue;

          //vibor tipa sferi (materiala i zalivki)
          t:=r_obsh.nextInt(10000);
          temp_sfera.parameter:=0;  //obnulaem parametr, chtobi tam sluchayno ne okazalos' randomnoe znachenie
          case t of
          0..1545:begin  //wood-leaves
                    temp_sfera.mat_shell:=18;
                    temp_sfera.mat_fill:=17;
                    temp_sfera.mat_thick:=2;
                    temp_sfera.fill_level:=temp_sfera.radius*2;
                    temp_sfera.parameter:=r_obsh.nextInt(4);  //opredelaet data_value dereva i list'ev
                    temp_sfera.parameter:=temp_sfera.parameter or 4;  //stavim bit, chtobi list'ya ne propadali
                  end;
          1546..3181:begin  //dirt
                       temp_sfera.mat_shell:=3;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(1000) of
                         0..899:temp_sfera.mat_fill:=3; //dirt
                         900..939:temp_sfera.mat_fill:=9;  //water
                         940..979:temp_sfera.mat_fill:=11;  //lava
                         980..999:temp_sfera.mat_fill:=13;  //gravel
                       end;
                       temp_sfera.parameter:=r_obsh.nextInt(4);  //tip bioma na sfere
                     end;
          3182..4271:begin  //glass
                       temp_sfera.mat_shell:=20;
                       temp_sfera.mat_thick:=r_obsh.nextInt(2)+2; //2-3 bloka tolshina
                       temp_sfera.fill_level:=r_obsh.nextInt(temp_sfera.radius*2); //randomniy uroven' zapolneniya
                       if r_obsh.nextInt(1000)<900 then temp_sfera.mat_fill:=9
                       else temp_sfera.mat_fill:=11;
                     end;
          4272..6090:begin  //stone
                       temp_sfera.mat_shell:=1;
                       temp_sfera.mat_thick:=r_obsh.nextInt(2)+2; //2-3 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(100000) of
                         0..7856:temp_sfera.mat_fill:=1;  //stone
                         7857..20713:temp_sfera.mat_fill:=16;  //coal
                         20714..32141:temp_sfera.mat_fill:=15;  //iron
                         32142..41426:temp_sfera.mat_fill:=14;  //gold
                         41427..45715:temp_sfera.mat_fill:=56;  //diamond
                         45716..50000:temp_sfera.mat_fill:=21;  //lapis lazuli
                         50001..56428:temp_sfera.mat_fill:=73;  //redstone
                         56429..68568:temp_sfera.mat_fill:=13;  //gravel
                         68569..71425:temp_sfera.mat_fill:=9;  //water
                         71426..74282:temp_sfera.mat_fill:=11;  //lava
                         74283..90001:begin
                                        temp_sfera.mat_fill:=1;   //mixed ores
                                        temp_sfera.parameter:=1;
                                      end;
                         90002..95001:begin
                                        temp_sfera.mat_fill:=1;
                                        if sqrt(2*sqr(temp_sfera.radius-temp_sfera.mat_thick))>=9 then
                                        temp_sfera.parameter:=2  //dungeon
                                        else temp_sfera.parameter:=1;  //mix
                                      end;
                         95002..98571:begin
                                        temp_sfera.mat_fill:=1;
                                        if temp_sfera.radius>=13 then
                                        temp_sfera.parameter:=3  //biosphere
                                        else temp_sfera.parameter:=1;  //mix
                                      end;
                         98572..99999:temp_sfera.mat_fill:=0;  //air (hollow sphere)
                       end;
                     end;
          6091..7362:begin  //sand
                       temp_sfera.mat_shell:=12;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       temp_sfera.parameter:=0;  //obnulaem, t.k. butut uchastvovat' biti
                       case r_obsh.nextInt(100) of
                         0..39:temp_sfera.mat_fill:=12;  //sand
                         40..49:begin
                                  temp_sfera.mat_fill:=24;  //sandstone
                                  temp_sfera.parameter:=temp_sfera.parameter or (r_obsh.nextInt(3)shl 5);  //biti 6-5 butut otvechat' za data-value
                                end;
                         50..99:begin
                                  temp_sfera.mat_fill:=12;  //mix
                                  temp_sfera.parameter:=temp_sfera.parameter or $80;  //bit 7 otvechaet za miks
                                end;
                       end;
                       case r_obsh.nextInt(100) of
                         0..69:temp_sfera.parameter:=temp_sfera.parameter or 1;  //glina vnizu
                         70..89:temp_sfera.parameter:=temp_sfera.parameter or 2;  //peschaniy kamen' vnizu (data_value beretsa iz zapolnitela)
                         90..99:temp_sfera.parameter:=temp_sfera.parameter or 3;  //nichego ne podderzhivaet sferi vnizu
                       end;
                     end;
          7363..8181:begin  //glowstone
                       temp_sfera.mat_shell:=89;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(100) of
                         0..59:temp_sfera.mat_fill:=89;  //glowstone
                         60..64:begin
                                  temp_sfera.mat_fill:=20;  //hollow glass
                                  temp_sfera.parameter:=1;
                                end;
                         65..69:temp_sfera.mat_fill:=9;  //water
                         70..74:temp_sfera.mat_fill:=11;  //lava
                         75..84:begin
                                  temp_sfera.mat_fill:=20;
                                  if temp_sfera.radius>=13 then
                                  temp_sfera.parameter:=2   //biosphere
                                  else temp_sfera.parameter:=1;  //hollow glass
                                end;
                         85..99:temp_sfera.mat_fill:=20;  //glass
                       end;
                     end;
          8182..8362:begin  //bedrock
                       temp_sfera.mat_shell:=7;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       temp_sfera.mat_fill:=7;
                       case r_obsh.nextInt(100) of
                         0..49:temp_sfera.parameter:=1;  //dungeon
                         50..89:temp_sfera.parameter:=2;  //trap
                         90..99:temp_sfera.parameter:=3;  //trap+treasure
                       end;
                       if temp_sfera.radius<15 then temp_sfera.parameter:=0;
                     end;
          8363..8817:begin  //obsidian
                       temp_sfera.mat_shell:=49;
                       //opredelaem tolshinu obolochki
                       temp_sfera.mat_thick:=r_obsh.nextInt(8)+3;  //3-10 blokov
                       if (temp_sfera.mat_thick+3)>=temp_sfera.radius then
                         temp_sfera.mat_thick:=temp_sfera.radius-3;
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(96) of
                         0..19:temp_sfera.mat_fill:=49;  //obsidian
                         20..29:temp_sfera.mat_fill:=15;  //iron
                         30..39:temp_sfera.mat_fill:=56;  //diamond
                         40..89:temp_sfera.mat_fill:=11;  //lava
                         90..94:begin
                                  temp_sfera.mat_fill:=1;
                                  if sqrt(2*sqr(temp_sfera.radius-temp_sfera.mat_thick))>=9 then
                                  temp_sfera.parameter:=1  //dungeon
                                  else temp_sfera.mat_fill:=49;  //obsidian fill
                                end;
                       end;
                     end;
          8818..9362:begin  //ice
                       temp_sfera.mat_shell:=79;
                       temp_sfera.mat_thick:=r_obsh.nextInt(3)+2; //2-4 bloka tolshina
                       case r_obsh.nextInt(100) of
                         0..39:temp_sfera.mat_fill:=79;  //ice
                         40..59:temp_sfera.mat_fill:=9;  //water
                         60..69:temp_sfera.mat_fill:=0;  //air (hollow sphere)
                         70..89:temp_sfera.mat_fill:=80;  //snow blocks
                         90..99:begin
                                  temp_sfera.mat_fill:=78;  //snow layer
                                  temp_sfera.parameter:=7;  //full block size
                                end;
                       end;
                       if (temp_sfera.mat_fill=79)or(temp_sfera.mat_fill=9)or
                       (temp_sfera.mat_fill=80) then temp_sfera.fill_level:=r_obsh.nextInt(temp_sfera.radius*2)
                       else temp_sfera.fill_level:=temp_sfera.radius*2;
                     end;
          9363..9726:begin  //nether
                       temp_sfera.mat_shell:=87;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(100) of
                         0..49:temp_sfera.mat_fill:=87;  //netherrack
                         50..79:temp_sfera.mat_fill:=11;  //lava
                         80..94:temp_sfera.mat_fill:=88;  //soul sand
                         95..99:temp_sfera.mat_fill:=112;  //nether brick
                       end;
                     end;
          9727..9999:begin  //mushroom
                       temp_sfera.mat_shell:=3;
                       temp_sfera.mat_thick:=2; //2 bloka tolshina
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       temp_sfera.mat_fill:=3; //dirt
                       temp_sfera.parameter:=$80;  //oboznachaem, chto eto gribnaya sfera
                     end;
          end;

          //opredelenie tipa sferi dla bolee bistroy otrisovki sferi
          temp_sfera.sphere_type:=0;
          //bit 0 - change of top block     $1
          //bit 1 - change of bottom block   $2
          //bit 2 - change of biome         $4
          //bit 3 - spawn objects on top    $8
          //bit 4 - spawn objects inside    $10
          //bit 5 - change of data_value   $20
          case temp_sfera.mat_shell of
            18:begin
                 if (temp_sfera.parameter and $3)<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $20;
                 if (temp_sfera.parameter and $3)=3 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $8;
               end;
            3:temp_sfera.sphere_type:=temp_sfera.sphere_type or $1 or $4 or $8;
            20:temp_sfera.sphere_type:=temp_sfera.sphere_type or $10;
            1:if temp_sfera.parameter<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $10;
            12:begin
                 if (temp_sfera.parameter and $80)<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $10;
                 if (temp_sfera.parameter and $60)<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $20;
                 if (temp_sfera.parameter and $F)<>3 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $2;
                 temp_sfera.sphere_type:=temp_sfera.sphere_type or $8;
               end;
            89:if temp_sfera.parameter<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $10;
            7:temp_sfera.sphere_type:=temp_sfera.sphere_type or $10 or $8;
            49:if temp_sfera.parameter<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $10;
            79:begin
                 if temp_sfera.parameter<>0 then temp_sfera.sphere_type:=temp_sfera.sphere_type or $20;
                 temp_sfera.sphere_type:=temp_sfera.sphere_type or $8;
               end;
            87:temp_sfera.sphere_type:=temp_sfera.sphere_type or $8;
          end;


          {t:=r.nextInt(100);
          case t of
          0..13:begin    //Sand
                  temp_sfera.mat_shell:=12;
                  temp_sfera.mat_fill:=12;
                  temp_sfera.mat_thick:=1;
                  temp_sfera.fill_level:=temp_sfera.radius*2-1;
                  if r.nextDouble>0.9 then temp_sfera.parameter:=0
                  else temp_sfera.parameter:=1;
                end;
          14..42:begin    //Stone
                   temp_sfera.mat_shell:=1;
                   temp_sfera.mat_thick:=2;
                   temp_sfera.fill_level:=temp_sfera.radius*2-2;
                   temp_sfera.mat_fill:=r.nextInt(100);
                   case temp_sfera.mat_fill of
                   0..4:temp_sfera.mat_fill:=56;  //Dimond
                   5..9:temp_sfera.mat_fill:=21;  //Lapis lazuli
                   10..16:temp_sfera.mat_fill:=48;//Moss cobblestone
                   17..24:temp_sfera.mat_fill:=14;//Gold ore
                   25..33:temp_sfera.mat_fill:=13;//Gravel
                   34..42:temp_sfera.mat_fill:=73;//Redstone;
                   43..52:temp_sfera.mat_fill:=9; //Water
                   53..64:temp_sfera.mat_fill:=11;//Lava
                   65..78:temp_sfera.mat_fill:=15;//Iron
                   79..99:temp_sfera.mat_fill:=16; //Coal
                   end;
                 end;
          43..54:begin    //Leaves
                   temp_sfera.mat_shell:=18;
                   temp_sfera.mat_fill:=17;
                   temp_sfera.mat_thick:=2;
                   temp_sfera.fill_level:=temp_sfera.radius*2-2;
                 end;
          55..65:begin    //Glass
                   temp_sfera.mat_shell:=20;
                   temp_sfera.mat_fill:=9;
                   temp_sfera.mat_thick:=3;
                   temp_sfera.fill_level:=r.nextInt(temp_sfera.radius*2);
                 end;
          66..77:begin    //Glowstone
                   temp_sfera.mat_shell:=89;
                   temp_sfera.mat_fill:=89;
                   temp_sfera.mat_thick:=1;
                   temp_sfera.fill_level:=temp_sfera.radius*2-1;
                 end;
          78..99:begin    //Dirt
                   temp_sfera.mat_shell:=3;
                   temp_sfera.mat_thick:=1;
                   temp_sfera.mat_fill:=3;
                   temp_sfera.fill_level:=temp_sfera.radius*2-1;
                 end;
          end;    }

          //zapis' sferi v obshiy massiv
          temp_sfera.chunks:=nil;
          y:=length(sferi);
          setlength(sferi,y+1);
          move(temp_sfera,sferi[y],sizeof(TSphere));

          //zapis' sferi v massiv tekushego regiona
          t:=length(region_sferi);
          setlength(region_sferi,t+1);
          move(temp_sfera,region_sferi[t],sizeof(TSphere));

          //zapis' sferi v massiv peresecheniy esli ona blizko k krayu regiona
          if (temp_sfera.x<x_reg_min)or
          (temp_sfera.x>x_reg_max)or
          (temp_sfera.z<y_reg_min)or
          (temp_sfera.z>y_reg_max)then
          begin
            t:=length(intersect_sferi);
            setlength(intersect_sferi,t+1);
            move(temp_sfera,intersect_sferi[t],sizeof(TSphere));
          end;
        end;
      end;

      //rad testovih sfer
      {i:=14;  //radius
      j:=0;  //z
      setlength(sferi,20);

      for t:=0 to length(sferi)-1 do
      begin
        sferi[t].x:=0;
        sferi[t].y:=130;
        sferi[t].z:=j;
        sferi[t].radius:=i;
        inc(j,i+3);
        if i<15 then inc(i,1)
        else inc(i,4);   //prirashenie radiusa
        inc(j,i);
        //inc(i,7);
        //inc(j,i-5+i);

        sferi[t].mat_shell:=3;
        sferi[t].mat_thick:=2; //2 bloka tolshina
        sferi[t].fill_level:=temp_sfera.radius*2;
        sferi[t].mat_fill:=3; //dirt
        sferi[t].parameter:=0;  //tip bioma na sfere
      end;

      sferi[1].mat_shell:=7;
      sferi[1].mat_fill:=7;
      sferi[1].parameter:=2;

      sferi[2].mat_shell:=7;
      sferi[2].mat_fill:=7;
      sferi[2].parameter:=3;

      //sferi[0].parameter:=0;

      //sferi[3].parameter:=3;

      {//temp_sfera.parameter or (r_obsh.nextInt(3)shl 5)
      //pervaya sfera - 
      sferi[0].mat_shell:=49;
      sferi[0].mat_fill:=1;

      //vtoraya sfera -
      sferi[1].mat_shell:=89;
      sferi[1].mat_fill:=20;
      sferi[1].mat_thick:=2;
      sferi[1].parameter:=2;

      //tret'ya sfera -
      sferi[2].mat_shell:=1;
      sferi[2].mat_fill:=1;
      sferi[2].mat_thick:=2;  //3-10 blokov
      sferi[2].parameter:=3;


      {temp_sfera.mat_shell:=49;
                       //opredelaem tolshinu obolochki
                       temp_sfera.mat_thick:=r_obsh.nextInt(8)+3;  //3-10 blokov
                       if (temp_sfera.mat_thick+3)>=temp_sfera.radius then
                         temp_sfera.mat_thick:=temp_sfera.radius-3;
                       temp_sfera.fill_level:=temp_sfera.radius*2;
                       case r_obsh.nextInt(100) of
                         0..19:temp_sfera.mat_fill:=49;  //obsidian
                         20..29:temp_sfera.mat_fill:=15;  //iron
                         30..39:temp_sfera.mat_fill:=56;  //diamond
                         40..89:temp_sfera.mat_fill:=11;  //lava
                         90..94:begin
                                  temp_sfera.mat_fill:=1;  //dungeon
                                  temp_sfera.parameter:=1;
                                end;
                         95..99:begin
                                  temp_sfera.mat_fill:=1;  //trap+treasure
                                  temp_sfera.parameter:=2
                                end;
                       end;
      }

      //testovie sferi
      {setlength(sferi,5);
      sferi[0].x:=1;
      sferi[0].y:=150;
      sferi[0].z:=1;
      sferi[0].radius:=5;
      sferi[0].mat_fill:=1;
      sferi[0].mat_shell:=1;
      sferi[0].mat_thick:=2;
      sferi[0].fill_level:=sferi[0].radius*2;

      sferi[1].x:=6;
      sferi[1].y:=100;
      sferi[1].z:=8;
      sferi[1].radius:=6;
      sferi[1].mat_fill:=1;
      sferi[1].mat_shell:=1;
      sferi[1].mat_thick:=2;
      sferi[1].fill_level:=sferi[0].radius*2;

      sferi[2].x:=7;
      sferi[2].y:=60;
      sferi[2].z:=1;
      sferi[2].radius:=12;
      sferi[2].mat_fill:=1;
      sferi[2].mat_shell:=1;
      sferi[2].mat_thick:=1;
      sferi[2].fill_level:=sferi[0].radius*2;


      sferi[3].x:=13;
      sferi[3].y:=150;
      sferi[3].z:=1;
      sferi[3].radius:=5;
      sferi[3].mat_fill:=1;
      sferi[3].mat_shell:=3;
      sferi[3].mat_thick:=1;
      sferi[3].fill_level:=sferi[0].radius*2;

      sferi[4].x:=20;
      sferi[4].y:=100;
      sferi[4].z:=8;
      sferi[4].radius:=6;
      sferi[4].mat_fill:=1;
      sferi[4].mat_shell:=3;
      sferi[4].mat_thick:=1;
      sferi[4].fill_level:=sferi[0].radius*2;  }

    fill_spheres_chunks(sferi);
    setlength(intersect_sferi,0);
    setlength(region_sferi,0);

    //r.Free;
  end;

  //vivodim v log soobshenie ob obshem kol-ve sfer
  //vivod dal'she vmeste so statistikoy
  {mess_str:='Overall spheres created: '+inttostr(length(sferi));
  mess_to_manager:=pchar(mess_str);
  postmessage(app_hndl,WM_USER+309,integer(mess_to_manager),0); }

  //opredelaem tochku spauna, a tochnee sferu, kotoraya blizhe vsego k tochke 0,(3/4 seredini spauna sfer),0
  //vichislaem 3/4 spavna sfer
  x:=(spawn_max-spawn_min) div 2;
  x:=((spawn_max-x) div 2)+spawn_min;
  //opredelaem rasstoyanie do etoy tochki ot pervoy sferi
  y:=0;
  z:=round(sqrt(sqr(sferi[y].x)+sqr(sferi[y].y-x)+sqr(sferi[y].z)));
  //idem po vsem sferam i smotrim rezultat
  if crc_rasch=crc_rasch_man then
  for i:=1 to length(sferi)-1 do
  begin
    j:=round(sqrt(sqr(sferi[i].x)+sqr(sferi[i].y-x)+sqr(sferi[i].z)));
    if (j<z)and((sferi[i].mat_shell=18)or(sferi[i].mat_shell=3)) then
    begin
      z:=j;
      y:=i;
    end;

    check_stop;
    if stopping=true then
    begin
      //result:=true;
      result:=false;
      postmessage(app_hndl,WM_USER+310,0,0);  //soobshenie ob uspeshnoy ostanovke
      exit;
    end;
  end;

  //udalaem vse sferi krome pervoy esli ne nash menedger
  if crc_rasch<>crc_rasch_man then
  begin
    for i:=1 to length(sferi)-1 do
      setlength(sferi[i].chunks,0);
    setlength(sferi,1);
  end;

  //menaem tochku spauna
  x:=sferi[y].x;
  z:=sferi[y].z;
  y:=sferi[y].y+sferi[y].radius+2;
  //y:=sloi[length(sloi)-1].start_alt+sloi[length(sloi)-1].width+1;
  //sohranaem koordinati spauna
  spawn_x:=x;
  spawn_y:=y;
  spawn_z:=z;

  postmessage(app_hndl,WM_USER+306,0,x);
  postmessage(app_hndl,WM_USER+306,1,y);
  postmessage(app_hndl,WM_USER+306,2,z);

  //vivodim statistiku sfer
  mess_str:='Statistika sfer:'+#13+#10;
  //obshee kol-vo
  mess_str:=mess_str+'Overall spheres created: '+inttostr(length(sferi))+#13+#10;
  //kamennaya s miksom
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=1)and(sferi[i].parameter=1) then inc(j);
  mess_str:=mess_str+'Stone sphere with mix:'+inttostr(j)+#13+#10;
  //kamennaya s dungeonom
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=1)and(sferi[i].parameter=2) then inc(j);
  mess_str:=mess_str+'Stone sphere with dungeon:'+inttostr(j)+#13+#10;
  //kamennaya s biosferoy
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=1)and(sferi[i].parameter=3) then inc(j);
  mess_str:=mess_str+'Stone sphere with biosphere:'+inttostr(j)+#13+#10;
  //glowstone s biosferoy
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=89)and(sferi[i].parameter=2) then inc(j);
  mess_str:=mess_str+'Glowstone with biosphere:'+inttostr(j)+#13+#10;
  //obsidian s dangem
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=49)and(sferi[i].parameter=1) then inc(j);
  mess_str:=mess_str+'Obsidian with dungeon:'+inttostr(j)+#13+#10;
  //bedrock s dungeon
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=7)and(sferi[i].parameter=1) then inc(j);
  mess_str:=mess_str+'Bedrock with dungeon:'+inttostr(j)+#13+#10;
  //bedrock s lovushkoy
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=7)and(sferi[i].parameter=2) then inc(j);
  mess_str:=mess_str+'Bedrock with trap:'+inttostr(j)+#13+#10;
  //bedrock s lovushkoy+sokrovisha
  j:=0;
  for i:=0 to length(sferi)-1 do
    if (sferi[i].mat_shell=7)and(sferi[i].parameter=3) then inc(j);
  mess_str:=mess_str+'Bedrock with treasure:'+inttostr(j)+#13+#10;
  mess_to_manager:=pchar(mess_str);
  postmessage(app_hndl,WM_USER+309,integer(mess_to_manager),0);

  //ochishaem panel' i vivodim soobshenie o tom, chto generator gotov
  postmessage(app_hndl,WM_USER+300,0,0);
  //peredaem soobshenie o smene leybla
  mess_str:='Planetoid generator ready';
  mess_to_manager:=PChar(mess_str);
  postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),4);

  result:=true;
end;

function generate_chunk(i,j:integer):TGen_Chunk;
var pop:boolean;
x,y,a1,a2:integer;
begin
  if stopped then
  begin
    mess_str:='Reseived chunk return after stop';
    mess_to_manager:=PChar(mess_str);
    postmessage(app_hndl,WM_USER+309,integer(mess_to_manager),0);
    result:=chunk;
    exit;
  end;

  //ochishaem chank
  zeromemory(chunk.Blocks,length(chunk.Blocks));
  zeromemory(chunk.Data,length(chunk.Data));
  zeromemory(chunk.Biomes,length(chunk.Biomes));
  //fillchar(chunk.Biomes[0],length(chunk.Biomes),255);

  //vistavlaem sid, zavisashiy ot obshego i koordinat chanka
  r_obsh.SetSeed((i * $4f9939f508 + j * $1ef1565bd5)xor obsh_sid);

  //delaem zemlu esli nuzhno
  if map_type<>0 then
  begin
    case map_type of
      1:x:=9;
      2:x:=11
      else x:=0;
    end;

    for a1:=0 to 15 do  //x
      for a2:=0 to 15 do  //z
      begin
        for y:=0 to ground_level-1 do  //y
          chunk.Blocks[a1+a2*16+y*256]:=7;
        for y:=ground_level to ground_level+2 do
          chunk.Blocks[a1+a2*16+y*256]:=x;
      end;
  end;

  //opredelaem, sozdavali li mi ob'ekti dla etogo chanka uzhe ili net
  pop:=false;
  for x:=0 to length(pop_chunks)-1 do
    if (pop_chunks[x].x=i)and(pop_chunks[x].z=j) then
    begin
      pop:=true;
      break;
    end;

  if crc_rasch=crc_rasch_man then
    draw_spheres(i,j,pop);

  //dobavlaem koordinati chanka v massiv populacii
  if pop=false then
  begin
    x:=length(pop_chunks);
    setlength(pop_chunks,x+1);
    pop_chunks[x].x:=i;
    pop_chunks[x].z:=j;
  end;

  //generim stenu esli nuzhno
  if gen_wall=true then
  begin
    if i=fromx_obsh then
      for a1:=0 to 15 do  //Z
        for a2:=0 to 255 do  //Y
          chunk.Blocks[a1*16+a2*256]:=7;

    if i=tox_obsh then
      for a1:=0 to 15 do  //Z
        for a2:=0 to 255 do  //Y
          chunk.Blocks[15+a1*16+a2*256]:=7;

    if j=fromy_obsh then
      for a1:=0 to 15 do  //X
        for a2:=0 to 255 do  //Y
          chunk.Blocks[a1+a2*256]:=7;

    if j=toy_obsh then
      for a1:=0 to 15 do  //X
        for a2:=0 to 255 do  //Y
          chunk.Blocks[a1+15*16+a2*256]:=7;
  end;

  result:=chunk;
end;

function gen_region(i,j:integer; map:region):boolean; register;
var k,z:integer;
begin
  //ochishaem povtoreniya
  //ishem povtoreniya
  for k:=0 to length(obj)-2 do
  begin
    if obj[k].y=1000 then continue;
    for z:=k+1 to length(obj)-1 do
    begin
      if obj[z].y=1000 then continue;
      if (obj[k].x=obj[z].x)and(obj[k].y=obj[z].y)and
      (obj[k].z=obj[z].z)and(obj[k].id=obj[z].id) then
        obj[z].y:=1000;
    end;
  end;

  //samo udalenie
  k:=0;
  if length(obj)>2 then
  repeat
    if obj[k].y=1000 then
    begin
      if k<>(length(obj)-1) then
        move(obj[k+1],obj[k],(length(obj)-k-1)*sizeof(TObj));
      setlength(obj,length(obj)-1);
    end
    else
      inc(k);
  until k>(length(obj)-1);  

  //otrisovka ob'ektov
  gen_objects(i,j,map);

  //sozdanie snega
  gen_snow_region(i,j,map);

  //ochishenie spauna
  set_block_id_data(map,i,j,spawn_x,spawn_y,spawn_z,0,0);
  set_block_id_data(map,i,j,spawn_x,spawn_y-1,spawn_z,0,0);

  result:=true;
end;

end.
