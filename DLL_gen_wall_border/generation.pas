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
border_in,border_out:integer;
border_in_out:boolean;
border_blocks:integer;
border_void:boolean;
border_void_chunks:integer;
border_material:integer;
min_x_ot,min_x_do,max_x_ot,max_x_do:integer;  //granici steni po X
min_z_ot,min_z_do,max_z_ot,max_z_do:integer;  //granici steni po Z
set_save:TGen_settings;

trans_bl:set_trans_blocks;
light_bl:set_trans_blocks;
diff_bl:set_trans_blocks;
solid_bl:set_trans_blocks;


function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
function generate_chunk(i,j:integer):TGen_Chunk;
procedure clear_dynamic;
function gen_region(i,j:integer; map:region):boolean; register;
procedure generate_add_chunk(chx,chz:integer; var chunk:TGen_Chunk);

implementation

uses windows, settingsf, sysutils;

procedure clear_dynamic;
begin
end;

function init_generator(gen_set:TGen_settings; var bord_in,bord_out:integer):boolean;
begin
  //sohranaem nastroyki generacii
  set_save:=gen_set;

  //vichislaem nuzhnoe kol-vo chankov
  if border_in_out=false then
  begin
    border_in:=0;
    if (border_blocks mod 16)=0 then border_out:=border_blocks div 16
    else border_out:=(border_blocks div 16)+1;

    if (border_blocks mod 16)>5 then inc(border_out,border_void_chunks)
    else inc(border_out,border_void_chunks-1);     
  end
  else
  begin
    if (border_blocks mod 16)=0 then border_in:=border_blocks div 16
    else border_in:=(border_blocks div 16)+1;

    if border_void=true then border_out:=border_void_chunks
    else border_out:=0;
  end;

  //vichislaem granicu steni
  //po X minimum
  min_x_ot:=-(gen_set.Width div 2);
  min_x_ot:=min_x_ot*16;
  if border_in_out=true then
    min_x_do:=min_x_ot+border_blocks-1
  else
  begin
    min_x_do:=min_x_ot-1;
    min_x_ot:=min_x_do-border_blocks+1;
  end;
  //po X maximum
  max_x_ot:=(gen_set.Width div 2)-1;
  max_x_ot:=max_x_ot*16+16;
  if border_in_out=true then
  begin
    max_x_do:=max_x_ot-1;
    max_x_ot:=max_x_do-border_blocks+1;
  end
  else
    max_x_do:=max_x_ot+border_blocks-1;
  //po Z minimum
  min_z_ot:=-(gen_set.Length div 2);
  min_z_ot:=min_z_ot*16;
  if border_in_out=true then
    min_z_do:=min_z_ot+border_blocks-1
  else
  begin
    min_z_do:=min_z_ot-1;
    min_z_ot:=min_z_do-border_blocks+1;
  end;
  //po Z maximum
  max_z_ot:=(gen_set.Length div 2)-1;
  max_z_ot:=max_z_ot*16+16;
  if border_in_out=true then
  begin
    max_z_do:=max_z_ot-1;
    max_z_ot:=max_z_do-border_blocks+1;
  end
  else
    max_z_do:=max_z_ot+border_blocks-1;

  //formiruem izmenenie nastroek granici v menedgere 
  bord_in:=border_in;
  bord_out:=border_out;

  result:=true;
end;

procedure generate_add_chunk(chx,chz:integer; var chunk:TGen_Chunk);
var bl_x_ot,bl_x_do,bl_z_ot,bl_z_do:integer;
otx,otz:integer;
minsm_x_ot,minsm_x_do,minsm_z_ot,minsm_z_do:integer;
maxsm_x_ot,maxsm_x_do,maxsm_z_ot,maxsm_z_do:integer;
i,j,k:integer;
begin
  //postmessage(app_hndl,WM_USER+307,chx,chz);

  //vichislaem koordinati nachalnih blokov v dannom chanke
  otx:=chx*16;
  otz:=chz*16;

  //vichislaem smeshenie nachala i konca steni po minimu
  minsm_x_ot:=min_x_ot-otx;
  minsm_x_do:=min_x_do-otx;
  minsm_z_ot:=min_z_ot-otz;
  minsm_z_do:=min_z_do-otz;
  //vichislaem smeshenie nachala i konca steni po maksimumu
  maxsm_x_ot:=max_x_ot-otx;
  maxsm_x_do:=max_x_do-otx;
  maxsm_z_ot:=max_z_ot-otz;
  maxsm_z_do:=max_z_do-otz;

  bl_x_ot:=16;
  bl_x_do:=-1;
  bl_z_ot:=16;
  bl_z_do:=-1;
  //vichislaem granici imenno v dannom chanke
  //po minimumu X
  if ((minsm_x_ot<=15)and(minsm_x_ot>=0))or
  ((minsm_x_do<=15)and(minsm_x_do>=0))then
  begin
    if minsm_x_ot<bl_x_ot then bl_x_ot:=minsm_x_ot;
    if minsm_x_do>bl_x_do then bl_x_do:=minsm_x_do;
  end;
  //po minimumu Z
  if ((minsm_z_ot<=15)and(minsm_z_ot>=0))or
  ((minsm_z_do<=15)and(minsm_z_do>=0))then
  begin
    if minsm_z_ot<bl_z_ot then bl_z_ot:=minsm_z_ot;
    if minsm_z_do>bl_z_do then bl_z_do:=minsm_z_do;
  end;

  //po maksimumu X
  if ((maxsm_x_ot<=15)and(maxsm_x_ot>=0))or
  ((maxsm_x_do<=15)and(maxsm_x_do>=0))then
  begin
    if maxsm_x_ot<bl_x_ot then bl_x_ot:=maxsm_x_ot;
    if maxsm_x_do>bl_x_do then bl_x_do:=maxsm_x_do;
  end;
  //po maksimumu Z
  if ((maxsm_z_ot<=15)and(maxsm_z_ot>=0))or
  ((maxsm_z_do<=15)and(maxsm_z_do>=0))then
  begin
    if maxsm_z_ot<bl_z_ot then bl_z_ot:=maxsm_z_ot;
    if maxsm_z_do>bl_z_do then bl_z_do:=maxsm_z_do;
  end; 
  

  //zapolnenie pravuyu i levuyu storonu
  otx:=0;
  otz:=15;
  if (minsm_z_ot>0)and(minsm_z_ot<=15)then otx:=minsm_z_ot
  else if (minsm_z_ot>15) then otx:=16;
  if (maxsm_z_do<15)and(maxsm_z_do>=0)then otz:=maxsm_z_do
  else if (maxsm_z_do<0) then otz:=-1;
  for i:=0 to 15 do
  begin
    if (i>=bl_x_ot)and(i<=bl_x_do) then
      for j:=otx to otz do
        for k:=0 to 255 do
          chunk.Blocks[i+j*16+k*256]:=border_material;
  end;

  //zapolnaem verhnuyu i nizhnuyu storonu
  otx:=0;
  otz:=15;
  if (minsm_x_ot>0)and(minsm_x_ot<=15)then otx:=minsm_x_ot
  else if (minsm_x_ot>15) then otx:=16;
  if (maxsm_x_do<15)and(maxsm_x_do>=0)then otz:=maxsm_x_do
  else if (maxsm_x_do<0) then otz:=-1;
  for j:=0 to 15 do
  begin       
    if (j>=bl_z_ot)and(j<=bl_z_do) then
      for i:=otx to otz do
        for k:=0 to 255 do
          chunk.Blocks[i+j*16+k*256]:=border_material;
  end; 
end;

function generate_chunk(i,j:integer):TGen_Chunk;
begin
  last_error:='Plugin is not supposed to generate the terrain';
end;

function gen_region(i,j:integer; map:region):boolean; register;
begin     
  result:=false;
end;

end.
