unit generation;

interface

const PROTOCOL_DLL = 5;
WM_USER = $0400;

type ar_byte = array of byte;
     ar_int = array of integer;
     ar_double = array of double;
     ar_boolean = array of boolean;

     par_int = ^ar_int;

     for_set = 0..255;
     set_trans_blocks = set of for_set;
     
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
       Width, Length:integer;
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

     TGen_chunk = record
       Biomes:ar_byte;
       Blocks:ar_byte;
       Data:ar_byte;
       Light:ar_byte;
       Skylight:ar_byte;
       Heightmap:ar_int;
       Has_additional_id:Boolean;
       sections:array[0..15] of boolean;
       Add_id:ar_byte;
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

     line=array of TGen_Chunk;
     region=array of line;

var last_error:PChar;    //stroka s soobsheniem ob oshibke
plug_info_return:TPlugRec;   //zapis' s informaciey o razmerah tipov dannih dla viyasneniya sootvetstviya
plugin_settings:TPlugSettings;   //zapis' s informaciey o plagine
dll_path_str:string = '';  //stroka s putem do DLLki
app_hndl:cardinal;  //hendl Application menedgera
initialized:boolean = false;  //priznak inicializacii plagina
crc_manager:int64;    //CRC poluchennoe ot menedgera
flux:TFlux_set;  //zapis' s informaciey o izmenenii parametrov
mess_str:string;
mess_to_manager:PChar;   //stroka dla peredachi soobsheniy v menedger
stopped:boolean = false;   //priznak ostanovki generacii
map_height:integer;
crc_man,crc_schit:integer;

trans_bl:set_trans_blocks;
light_bl:set_trans_blocks;
diff_bl:set_trans_blocks;
solid_bl:set_trans_blocks;


function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
function generate_chunk(i,j:integer):TGen_Chunk;
procedure clear_dynamic;
function gen_region(i,j:integer; map:region):boolean; register;

function set_block_id(map:region; xreg,yreg:integer; x,y,z,id:integer):boolean;
function set_block_id_data(map:region; xreg,yreg:integer; x,y,z,id,data:integer):boolean;
function get_block_id(map:region; xreg,yreg:integer; x,y,z:integer):byte;
function get_block_data(map:region; xreg,yreg:integer; x,y,z:integer):byte;
function get_top_solid(map:region; xreg,yreg:integer; x,z:integer):byte;
function get_top_any(map:region; xreg,yreg:integer; x,z:integer):byte;

function shll(chislo:integer; smeshenie:byte):integer; overload;
function shrr(chislo:integer; smeshenie:byte):integer; overload;
function shll(chislo:int64; smeshenie:byte):int64; overload;
function shrr(chislo:int64; smeshenie:byte):int64; overload;
          
implementation

uses sysutils, randomMCT, windows, crc32_u, ChunkProviderGenerate_u;

var chunk:TGen_Chunk;
rnd_var:rnd;

gen_settings_save:TGen_settings;
gen_saved:boolean=false;

provider:ChunkProviderGenerate=nil;
//provider_init,provider_gen:boolean;

function shll(chislo:integer; smeshenie:byte):integer; overload;
begin
  if chislo<0 then
    result:=(chislo shl smeshenie)or $80000000
  else
    result:=chislo shl smeshenie;
end;

function shrr(chislo:integer; smeshenie:byte):integer; overload;
var i,t:integer;
begin
  if chislo<0 then
  begin
    t:=chislo;
    for i:=1 to smeshenie do
    begin
      t:=(t shr 1)or $80000000;
      if t=-1 then break;
    end;
    result:=t;
  end
  else
    result:=chislo shr smeshenie;
end;

function shll(chislo:int64; smeshenie:byte):int64; overload;
begin
  if chislo<0 then
    result:=(chislo shl smeshenie)or $8000000000000000
  else
    result:=chislo shl smeshenie;
end;

function shrr(chislo:int64; smeshenie:byte):int64; overload;
var i:integer;
t:int64;
begin
  if chislo<0 then
  begin
    t:=chislo;
    for i:=1 to smeshenie do
    begin
      t:=(t shr 1)or $8000000000000000;
      if t=-1 then break;
    end;
    result:=t;
  end
  else
    result:=chislo shr smeshenie;
end;

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

function get_block_data(map:region; xreg,yreg:integer; x,y,z:integer):byte;
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

      result:=map[chx][chy].data[xx+zz*16+yy*256];
    end
    else result:=255;
  end;

function get_top_solid(map:region; xreg,yreg:integer; x,z:integer):byte;
  var tempxot,tempxdo,tempyot,tempydo:integer;
  chx,chy:integer;
  xx,zz,yy:integer;
  begin
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

      chx:=chx-tempxot;
      chy:=chy-tempyot;

      yy:=127;

      while yy>0 do
      begin
        if(yy=0)or(not(map[chx][chy].blocks[xx+zz*16+yy*256] in solid_bl))or(map[chx][chy].blocks[xx+zz*16+yy*256]=18) then
          dec(yy)
        else
        begin
          result:=yy+1;
          exit;
        end;
      end;

      result:=0;
      //result:=map[chx][chy].blocks[yy+(zz*128+(xx*2048))];
    end
    else result:=0;
  end;

function get_top_any(map:region; xreg,yreg:integer; x,z:integer):byte;
  var tempxot,tempxdo,tempyot,tempydo:integer;
  chx,chy:integer;
  xx,zz,yy:integer;
  begin
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

      chx:=chx-tempxot;
      chy:=chy-tempyot;

      yy:=127;

      while yy>0 do
      begin
        if(map[chx][chy].blocks[xx+zz*16+yy*256]=0) then
          dec(yy)
        else
        begin
          result:=yy+1;
          exit;
        end;
      end;

      result:=0;
      //result:=map[chx][chy].blocks[yy+(zz*128+(xx*2048))];
    end
    else result:=0;
  end;

procedure clear_dynamic;
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

  //if provider_init=true then provider.Free;
  //provider_init:=false;
  if provider<>nil then provider.Free;
  provider:=nil;

  gen_saved:=false;
end;

procedure gen_surf(xkoord,ykoord:integer; chunk:TGen_Chunk);
begin
  provider.ProvideChunk(chunk.Blocks,xkoord,ykoord,chunk.Biomes);
  //provider.Clear;
end;

function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
var x,y,z,t:integer;
mat:integer;
r:rnd;
begin
  stopped:=false;

  map_height:=64;

  gen_settings_save:=gen_set;
  gen_saved:=true;

  //soobshenie ob ochishenii paneli
  postmessage(app_hndl,WM_USER+300,plugin_settings.plugin_type and 7,0);

  //peredaem soobshenie o smene leybla
  mess_str:='Initializing original generator';
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
  r:=rnd.Create(y);
  //vichislaem kol-vo vizovov randoma
  mat:=((t shr 4)and 1)+((t shr 13) and 2)+((t shr 18)and 4)+((t shr 26) and 8);
  //delaem opredelennoe kol-vo vizivov randoma
  for z:=1 to mat do
    r.nextInt;
  t:=r.nextInt;
  //messagebox(app_hndl,pchar('CRC izmenennoe='+inttohex(t,8)+#13+#10+'CRC izmenennoe iz menedgera='+inttohex(x,8)),'Message',mb_ok);
  r.Free;

  crc_schit:=t;
  crc_man:=x;

  //zapolnaem v sootvetstvii so sloyami
  zeromemory(chunk.Biomes,length(chunk.Biomes));
  zeromemory(chunk.Blocks,length(chunk.Blocks));
  zeromemory(chunk.Data,length(chunk.Data));

  rnd_var:=rnd.Create(gen_set.SID);

  //proveraem pravilnost' CRC
  (*if t=x then
  begin
    //messagebox(app_hndl,pchar('Voshli v bloki'),'Message',mb_ok);
    {for t:=0 to length(sloi)-1 do
    begin
      mat:=sloi[t].material;
      data:=sloi[t].material_data;
      for y:=sloi[t].start_alt to sloi[t].start_alt+sloi[t].width-1 do
        for x:=0 to 15 do
          for z:=0 to 15 do
          begin
            chunk.Blocks[x+z*16+y*256]:=mat;
            if data<>0 then chunk.Data[x+z*16+y*256]:=data;
          end;
    end; }
    for y:=0 to map_height-1 do
      for x:=0 to 15 do
        for z:=0 to 15 do
          chunk.Blocks[x+z*16+y*256]:=1;
  end;    *)

  //sozdaem ob'ekt dla generacii landshafta
  provider:=ChunkProviderGenerate.Create(gen_set.SID,false);
  //provider_init:=true;
  //provider_gen:=false;

  //menaem tochku spauna
  if t=x then
    gen_surf(0,0,chunk)
  else zeromemory(chunk.Blocks,length(chunk.Blocks));
  x:=0;
  z:=0;
  y:=255;
  while (chunk.Blocks[x+z*16+(y-1)*256]=0)and(y>0) do
    dec(y);
  inc(y);
  postmessage(app_hndl,WM_USER+306,0,x);
  postmessage(app_hndl,WM_USER+306,1,y);
  postmessage(app_hndl,WM_USER+306,2,z);

  //peredaem soobshenie o smene leybla
  mess_str:='Original generator ready';
  mess_to_manager:=PChar(mess_str);
  postmessage(app_hndl,WM_USER+305,integer(mess_to_manager),4);

  result:=true;
end;

function generate_chunk(i,j:integer):TGen_Chunk;
//var t,mat,data:integer;
begin
  if stopped then
  begin
    mess_str:='Reseived chunk return after stop';
    mess_to_manager:=PChar(mess_str);
    postmessage(app_hndl,WM_USER+309,integer(mess_to_manager),0);
    result:=chunk;
    exit;
  end;

  if crc_man=crc_schit then
  begin
    //if (i>=3)and(j>=3)then
      gen_surf(i,j,chunk);
    //else zeromemory(chunk.Blocks,length(chunk.Blocks));
  end;

  result:=chunk;
end;

procedure gen_population(xreg,yreg:integer; map:region);
var chx,chy,otx,dox,oty,doy,wid,len,chcx,chcy:integer;
begin
  //schitaem koordinati nachalnih i konechnih chankov v regione
    if xreg<0 then
    begin
      otx:=(xreg+1)*32-32;
      dox:=(xreg+1)*32-1;
    end
    else
    begin
      otx:=xreg*32;
      dox:=(xreg*32)+31;
    end;

    if yreg<0 then
    begin
      oty:=(yreg+1)*32-32;
      doy:=(yreg+1)*32-1;
    end
    else
    begin
      oty:=yreg*32;
      doy:=(yreg*32)+31;
    end;

  wid:=gen_settings_save.Width div 2;
  len:=gen_settings_save.Length div 2;

  if (-1*wid)>otx then otx:=-1*wid;
  if (wid-1)<dox then dox:=wid-1;
  if (-1*len)>oty then oty:=-1*len;
  if (len-1)<doy then doy:=len-1;

  while otx<0 do inc(otx,32);
  while oty<0 do inc(oty,32);
  while dox<0 do inc(dox,32);
  while doy<0 do inc(doy,32);

  while otx>31 do dec(otx,32);
  while oty>31 do dec(oty,32);
  while dox>31 do dec(dox,32);
  while doy>31 do dec(doy,32);

  inc(otx,2);
  inc(dox,2);
  inc(oty,2);
  inc(doy,2);

  dec(otx);
  dec(oty);

  for chx:=otx to dox do
    for chy:=oty to doy do
    begin
      //opredelaem koordinati tekuchego chanka
      chcx:=xreg*32;
      chcy:=yreg*32;
      dec(chcx,2);
      dec(chcy,2);
      inc(chcx,chx);
      inc(chcy,chy);
      provider.populate(xreg,yreg,chcx,chcy,map);
    end;
end;

function gen_region(i,j:integer; map:region):boolean; register;
begin
  if gen_saved=false then
    result:=false
  else
  begin
    gen_population(i,j,map);
    result:=true;
  end;
end;

initialization

  trans_bl:=[0,20,8,9,6,18,26,27,28,30,31,32,37,38,39,40,50,51,52,55,59,63,64,65,66,68,69,70,71,72,75,76,77,78,79,81,83,85,90,92,93,94,96,101,102,104,105,106,107,111,113,115];
  light_bl:=[51,91,10,11,89,50,76,90,94,74,62,39,95];
  diff_bl:=[8,9,79];
  solid_bl:=[1,2,3,4,5,7,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,33,34,35,36,41,42,43,44,45,46,47,48,49,52,53,54,56,57,58,60,61,62,64,67,71,73,74,79,80,81,82,84,85,86,87,88,89,91,92,95,96,97,98,99,100,101,102,103,107,108,109,110,112,113,114];

end.
