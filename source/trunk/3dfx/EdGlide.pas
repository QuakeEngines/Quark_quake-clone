(**************************************************************************
QuArK -- Quake Army Knife -- 3D game editor
Copyright (C) QuArK Development Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

http://quark.sourceforge.net/ - Contact information in AUTHORS.TXT
**************************************************************************)
unit EdGlide;

interface

uses Windows, Classes, Setup, SysUtils,
     PyMath, qmath, Bezier,
     QkObjects,
     Glide,
     EdSceneObject;

type
 TViewRect = record
              R: TRect; //Rect sent to the renderer
              Left, Top, Right, Bottom, ProjDx, ProjDy: FxFloat;
             end;

 TGlideSceneObject = class(TSceneObject)
 private
   FBuildNo: LongWord;
   FVertexList: TMemoryStream;
   VOID_COLOR, FRAME_COLOR: GrColor_t;
   CurrentAlpha: FxU32;
   Fog: Boolean;
   ViewRect: TViewRect;
   FogTableCache: ^GrFogTable_t;
   GlideLoaded: Boolean;
 protected
   ScreenX, ScreenY: Integer;
   function StartBuildScene({var PW: TPaletteWarning;} var VertexSize: Integer) : TBuildMode; override;
   procedure stScalePoly(Texture: PTexture3; var ScaleS, ScaleT: TDouble); override;
   procedure stScaleModel(Skin: PTexture3; var ScaleS, ScaleT: TDouble); override;
   procedure stScaleBezier(Texture: PTexture3; var ScaleS, ScaleT: TDouble); override;
   procedure stScaleSprite(Skin: PTexture3; var ScaleS, ScaleT: TDouble); override;
   procedure WriteVertex(PV: PChar; Source: Pointer; const ns,nt: Single; HiRes: Boolean); override;
   procedure PostBuild(nVertexList, nVertexList2: TList); override;
   procedure RenderPList(PList: PSurfaces; TransparentFaces: Boolean);
   procedure RenderTransparent(Transparent: Boolean);
   procedure BuildTexture(Texture: PTexture3); override;
   procedure ChangedViewWnd; override;
 public
   constructor Create;
   procedure Init(nCoord: TCoordinates;
                  nDisplayMode: TDisplayMode;
                  nDisplayType: TDisplayType;
                  nRenderMode: TRenderMode;
                  const LibName: String;
                  var AllowsGDI: Boolean); override;
   destructor Destroy; override;
   procedure Render3DView; override;
   procedure Draw3DView; override;
   procedure ClearFrame; override;
   procedure ClearScene; override;
   procedure SetViewSize(SX, SY: Integer); override;
   function ChangeQuality(nQuality: Integer) : Boolean; override;
 end;

procedure Do3DFXTwoMonitorsActivation; //FIXME: Currently unused!
procedure Do3DFXTwoMonitorsDeactivation; //FIXME: Currently unused!
procedure Set3DFXGammaCorrection(Value: TDouble);

var
 ScreenSizeX: Integer;
 ScreenSizeY: Integer;
 ScreenCenterX: Integer;
 ScreenCenterY: Integer;

 {------------------------}

implementation

uses Game, Quarkx, QkExceptions, Travail,
     PyMath3D, QkPixelSet, QkTextures, QkMapPoly, QkApplPaths;

const
 //See the "Floating Point Vertex Snapping and Area Calculations"-section
 //of chapter 14 of the Glide 2.4 Programming Guide for more information.
 VertexSnapper = 1.0*(3 shl 18);

type
 PVect3D = ^TVect3D;
 TVect3D = record
            BuildNo: LongWord;
            x, y, oow: Single;
            v: Pointer;
            OffScreen: Byte;
            LowPrecision: Boolean;   { if v points to a vec3_t - otherwise, it points to a TVect }
            Reserved1, Reserved2: Byte;
           end;
 PVertex3D = ^TVertex3D;
 TVertex3D = record
              v: PVect3D;
              s,t: scalar_t;
             end;
 {TSkinType = (stNone, stTexture, stSkin);}
 TGlideTextureFiltering = (tfNone, tfBilinear, tfTrilinear);

var
 FPControl: Word;

procedure SetFPUPrecision; forward;
procedure RestoreFPUPrecision; forward;

 {------------------------}

procedure ClearBuffers(Col: GrColor_t);
begin
 grBufferClear(Col, 0, GR_WDEPTHVALUE_FARTHEST);
end;

 {------------------------}

type  { this is the data shared by all existing TGlideSceneObjects }
  TGlideState = class
  public
    FMinAddress, FLoopAddress, FMaxAddress: FxU32;
    PerspectiveMode: Byte;
    DitherMode: GrDitherMode_t;
    CullMode: GrCullMode_t;
    TextureFiltering: TGlideTextureFiltering;
   {PalWarning: Boolean;}
    constructor Create;
    procedure NeedTex(PTex: PTexture3);
    procedure SetPerspectiveMode(nPerspectiveMode: Byte);
   {procedure PaletteWarning;}
    procedure Init;
  end;

var
 qrkGlideState: TGlideState = nil;

constructor TGlideState.Create;
begin
 inherited;

 { first time hardware setup }
 FMinAddress:=grTexMinAddress(GR_TMU0);
 FMaxAddress:=grTexMaxAddress(GR_TMU0);
 FLoopAddress:=FMinAddress;
end;

(*procedure TGlideState.PaletteWarning;
begin
 if not PalWarning then
  begin
   if qrkGlideVersion < SoftMultiplePalettes then
    GlobalWarning(LoadStr1(5656));
   PalWarning:=True;
  end;
end;*)

procedure TGlideState.NeedTex(PTex: PTexture3);
const
 TEXMEM_2MB_EDGE = 2097152;
var
 nStartAddress, nSize: FxU32;
 I: Integer;
 TextureManager: TTextureManager;
begin
 {$IFDEF Debug}
 if PTex^.info.data=Nil then
  Raise InternalE(LoadStr1(6010));
 {$ENDIF}
 if (PTex^.startAddress = GR_NULL_MIPMAP_HANDLE) then
  begin
   TextureManager:=TTextureManager.GetInstance;
    { computes destination address }
   nStartAddress:=FLoopAddress;
   nSize:=grTexTextureMemRequired(GR_MIPMAPLEVELMASK_BOTH, PTex^.info);
   if nStartAddress+nSize > FMaxAddress then
    nStartAddress:=FMinAddress
   else
    if (nStartAddress < TEXMEM_2MB_EDGE)
    and (nStartAddress+nSize > TEXMEM_2MB_EDGE) then
     nStartAddress:=TEXMEM_2MB_EDGE;
   FLoopAddress:=nStartAddress+nSize;

    { invalidates any other texture overlapping this interval }
   for I:=TextureManager.Textures.Count-1 downto 0 do
    with PTexture3(TextureManager.Textures.Objects[I])^ do
     if (startAddress<>GR_NULL_MIPMAP_HANDLE)
     and (startAddress<FLoopAddress)
     and (endAddress>nStartAddress) then
      startAddress:=GR_NULL_MIPMAP_HANDLE;

    { downloads the new texture }
   grTexDownloadMipMap(GR_TMU0, nStartAddress, GR_MIPMAPLEVELMASK_BOTH, PTex^.info);
   PTex^.startAddress:=nStartAddress;
   PTex^.endAddress:=FLoopAddress;
   {$IFDEF DeXXXXbugLOG} LogS:='DL-'; {$ENDIF}
  end
 else
  TextureManager:=Nil;

 if PTex^.GuPalette<>Nil then
  begin
   if TextureManager=Nil then
    TextureManager:=TTextureManager.GetInstance;
   if PTex^.GuPalette <> TextureManager.DownloadedPalette then
    begin
     TextureManager.DownloadedPalette:=PTex^.GuPalette;
     grTexDownloadTable(GR_TMU0, GR_TEXTABLE_PALETTE, TextureManager.DownloadedPalette);
    end;
  end;

 grTexSource(GR_TMU0, PTex^.startAddress, GR_MIPMAPLEVELMASK_BOTH, PTex^.info);
end;

procedure TGlideState.SetPerspectiveMode(nPerspectiveMode: Byte);
{var
 I: Integer;
 FogTable2D: GrFogTable_t;}
begin
 if PerspectiveMode<>nPerspectiveMode then
  begin
   PerspectiveMode:=nPerspectiveMode;
   if nPerspectiveMode=0 then
    Exit;
   if nPerspectiveMode=2 then  { flat display }
    grHints(GR_HINT_STWHINT, GR_STWHINT_W_DIFF_TMU0)
   else
    grHints(GR_HINT_STWHINT, 0);
   (*if nPerspectiveMode=2 then  { flat display }
     begin
     {for I:=0 to GR_FOG_TABLE_SIZE-1 do
       FogTable2D[I]:=I*(256 div GR_FOG_TABLE_SIZE);}
      guFogGenerateExp2(FogTable2D, 0.003);
      grFogTable(FogTable2D);
     end
    else
     Result:=True;*)
  end;
end;

procedure TGlideState.Init;
begin
 grDitherMode(DitherMode);
 grCullMode(CullMode);

 if TextureFiltering = tfNone then
  grTexFilterMode(GR_TMU0, GR_TEXTUREFILTER_POINT_SAMPLED, GR_TEXTUREFILTER_POINT_SAMPLED)
 else
  grTexFilterMode(GR_TMU0, GR_TEXTUREFILTER_BILINEAR, GR_TEXTUREFILTER_BILINEAR);

 grTexClampMode(GR_TMU0, GR_TEXTURECLAMP_WRAP, GR_TEXTURECLAMP_WRAP);
 if TextureFiltering = tfTrilinear then
  grTexMipMapMode(GR_TMU0, GR_MIPMAP_NEAREST, FXTRUE)
 else
  grTexMipMapMode(GR_TMU0, GR_MIPMAP_NEAREST, FXFALSE);

 grTexLodBiasValue(GR_TMU0, +0.5);
 grTexCombineFunction(GR_TMU0, GR_TEXTURECOMBINE_DECAL);
 grFogMode(GR_FOG_WITH_TABLE);

 grDepthBufferMode(GR_DEPTHBUFFER_WBUFFER);
 grDepthMask(FXTRUE);
 ClearBuffers(0);

 SetPerspectiveMode(0);
end;

 {------------------------}

constructor TGlideSceneObject.Create;
begin
 inherited;
 FVertexList:=TMemoryStream.Create;
end;

procedure TGlideSceneObject.Init(nCoord: TCoordinates; nDisplayMode: TDisplayMode; nDisplayType: TDisplayType;
          nRenderMode: TRenderMode; const LibName: String; var AllowsGDI: Boolean);
var
 hwconfig: GrHwConfiguration;
 AdapterNo: Integer;
 FogColor, FrameColor: TColorRef;
 Setup: QObject;
 SetupResolution: Integer;
 Resolution: GrScreenResolution_t;
 SetupMirror, SetupDither: Integer;
 Origin: GrOriginLocation_t;
begin
 ClearScene;

 DisplayMode:=nDisplayMode;
 DisplayType:=nDisplayType;
 RenderMode:=nRenderMode;

 Setup:=SetupSubSet(ssGeneral, 'Glide (3DFX)');
 if Setup.Specifics.Values['DisableDWM']<>'' then
  DisableDWM();

 SetupResolution:=StrToInt(Setup.Specifics.Values['Resolution']);
 case SetupResolution of
  0 : begin
        ScreenSizeX:=320;
        ScreenSizeY:=200;
        Resolution:=GR_RESOLUTION_320x200;
      end;
  1 : begin
        ScreenSizeX:=320;
        ScreenSizeY:=240;
        Resolution:=GR_RESOLUTION_320x240;
      end;
  2 : begin
        ScreenSizeX:=400;
        ScreenSizeY:=256;
        Resolution:=GR_RESOLUTION_400x256;
      end;
  3 : begin
        ScreenSizeX:=512;
        ScreenSizeY:=384;
        Resolution:=GR_RESOLUTION_512x384;
      end;
  4 : begin
        ScreenSizeX:=640;
        ScreenSizeY:=200;
        Resolution:=GR_RESOLUTION_640x200;
      end;
  5 : begin
        ScreenSizeX:=640;
        ScreenSizeY:=350;
        Resolution:=GR_RESOLUTION_640x350;
      end;
  6 : begin
        ScreenSizeX:=640;
        ScreenSizeY:=400;
        Resolution:=GR_RESOLUTION_640x400;
      end;
  7 : begin
        ScreenSizeX:=640;
        ScreenSizeY:=480;
        Resolution:=GR_RESOLUTION_640x480;
      end;
  8 : begin
        ScreenSizeX:=800;
        ScreenSizeY:=600;
        Resolution:=GR_RESOLUTION_800x600;
      end;
  9 : begin
        ScreenSizeX:=960;
        ScreenSizeY:=720;
        Resolution:=GR_RESOLUTION_960x720;
      end;
  10: begin
        ScreenSizeX:=856;
        ScreenSizeY:=480;
        Resolution:=GR_RESOLUTION_856x480;
      end;
  11: begin
        ScreenSizeX:=512;
        ScreenSizeY:=256;
        Resolution:=GR_RESOLUTION_512x256;
      end;
  12: begin
        ScreenSizeX:=1024;
        ScreenSizeY:=768;
        Resolution:=GR_RESOLUTION_1024x768;
      end;
  13: begin
        ScreenSizeX:=1280;
        ScreenSizeY:=1024;
        Resolution:=GR_RESOLUTION_1280x1024;
      end;
  14: begin
        ScreenSizeX:=1600;
        ScreenSizeY:=1200;
        Resolution:=GR_RESOLUTION_1600x1200;
      end;
  15: begin
        ScreenSizeX:=400;
        ScreenSizeY:=300;
        Resolution:=GR_RESOLUTION_400x300;
      end;
  else begin
        ScreenSizeX:=640;
        ScreenSizeY:=480;
        Resolution:=GR_RESOLUTION_640x480;  //Default to 640x480
      end;
 end;
 ScreenCenterX:=ScreenSizeX div 2;
 ScreenCenterY:=ScreenSizeY div 2;
 SetupMirror:=StrToInt(Setup.Specifics.Values['Mirror']);
 case SetupMirror of
 0: Origin:=GR_ORIGIN_UPPER_LEFT;
 1: Origin:=GR_ORIGIN_LOWER_LEFT;
 else
   Origin:=GR_ORIGIN_UPPER_LEFT;  //Default to upper left
 end;

 AdapterNo:=StrToInt(Setup.Specifics.Values['AdapterNo']);

 if not GlideLoaded then
  begin
   if LibName='' then
    Raise EError(6001);
   if not LoadGlide(LibName, GetQPath(pQuArKDll)) then
    Raise EErrorFmt(6002, [LibName, GetLastError]);
   if not Hardware3DFX then
    Raise EError(6206);
   try
    grGlideInit();
    if not grSstQueryHardware(hwconfig) then
     Raise EErrorFmt(6200, ['grSstQueryHardware']);
    if AdapterNo >= hwconfig.num_sst then
     Raise EErrorFmt(6207, [AdapterNo, hwconfig.num_sst]);

    grSstSelect(AdapterNo);
    if GlideTimesLoaded=1 then
      //Glide 2 only only supports 1 window at a time. So we can't use ViewWnd here!
      if not grSstWinOpen(GetGlideDummyHwnd,
                        Resolution,
                        GR_REFRESH_60HZ,
                        GR_COLORFORMAT_ARGB,
                        Origin,
                        2, 1) then //Note: Glide 2 doesn't support single buffering
       Raise EErrorFmt(6200, ['grSstWinOpen']);
    // grSstControl(GR_CONTROL_DEACTIVATE);
    if (not Assigned(qrkGlideState)) then
     qrkGlideState:=TGlideState.Create();
    GlideLoaded:=true;
   finally
    //If something went wrong, unload Glide because the set-up was incomplete
    if not GlideLoaded then
     UnloadGlide();
   end;
  end;
 if (DisplayMode=dmFullScreen) then
   Raise InternalE(LoadStr1(6220));

 Coord:=nCoord;
 TTextureManager.AddScene(Self);

   // Assigned check added by SilverPaladin
 if (not Assigned(qrkGlideState)) then
   raise InternalE(LoadStr1(6221));

 SetupDither:=StrToInt(Setup.Specifics.Values['Dither']);
 case SetupDither of
 0: qrkGlideState.DitherMode := GR_DITHER_DISABLE;
 1: qrkGlideState.DitherMode := GR_DITHER_2x2;
 2: qrkGlideState.DitherMode := GR_DITHER_4x4;
 else
   raise InternalE('Invalid Glide dithering value!');
 end;

 if Setup.Specifics.Values['Culling']<>'' then
   qrkGlideState.CullMode:=GR_CULL_NEGATIVE
 else
   qrkGlideState.CullMode:=GR_CULL_DISABLE;

 case StrToInt(Setup.Specifics.Values['TextureFiltering']) of
 0: qrkGlideState.TextureFiltering := tfNone;
 1: qrkGlideState.TextureFiltering := tfBilinear;
 2: qrkGlideState.TextureFiltering := tfTrilinear;
 else
   raise InternalE('Invalid Glide texture filtering value!');
 end;

 qrkGlideState.Init();

 Setup:=SetupSubSet(ssGeneral, '3D View');
 if (DisplayMode=dmWindow) or (DisplayMode=dmFullScreen) then
 begin
   FarDistance:=Setup.GetFloatSpec('FarDistance', 1500);
 end
 else
 begin
   FarDistance:=GetMapLimit();
 end;
 FogDensity:=Setup.GetFloatSpec('FogDensity', 1);
 FogColor:=SwapColor(Setup.IntSpec['FogColor']);
 FrameColor:=SwapColor(Setup.IntSpec['FrameColor']);
 VOID_COLOR:=FogColor;
 FRAME_COLOR:=FrameColor;

 Setup:=SetupSubSet(ssGeneral, 'Glide (3DFX)');
 if (DisplayMode=dmWindow) or (DisplayMode=dmFullScreen) then
 begin
   Fog:=Setup.Specifics.Values['Fog']<>'';
 end
 else
 begin
   Fog:=False;
 end;

 if Fog=True then
 begin
   ReallocMem(FogTableCache, SizeOf(GrFogTable_t));
   guFogGenerateExp2(FogTableCache^, FogDensity/MaxW);
   grFogColorValue(FogColor);
 end;
end;

destructor TGlideSceneObject.Destroy;
var
 Old: TMemoryStream;
begin
 Old:=FVertexList;
 if not (FogTableCache = nil) then
 begin
   FreeMem(FogTableCache);
   FogTableCache := nil;
 end;
 if GlideLoaded = True then
  begin
   if GlideTimesLoaded=1 then
    begin
     Do3DFXTwoMonitorsDeactivation;
     if (Assigned(qrkGlideState)) then
      begin
       qrkGlideState.Free;
       qrkGlideState:=Nil;
      end;
     grSstWinClose;
     grGlideShutdown;
    end;
   UnloadGlide;
  end;
 inherited;
 Old.Free;
end;

procedure TGlideSceneObject.ClearScene;
begin
 FVertexList.Clear;
 inherited;
end;

procedure TGlideSceneObject.WriteVertex(PV: PChar; Source: Pointer; const ns,nt: Single; HiRes: Boolean);
var
 L, R, Test: Integer;
 Base, Found: PVect3D;
begin
 Base:=PVect3D(FVertexList.Memory);
 L:=0;
 R:=FVertexList.Size div SizeOf(TVect3D);

 { this looks like some sort of binary-search }
 while R>L do
 begin
   Test:=(L+R) div 2;
   Found:=Base;
   Inc(Found, Test);

   if Found^.v = Source then
   begin
     with PVertex3D(PV)^ do
     begin
       v:=Found;
       s:=ns;
       t:=nt;

       Exit;
     end;
   end;

   if PChar(Found^.v) < PChar(Source) then
     L:=Test+1
   else
     R:=Test;
 end;

 Raise InternalE('GetVertex');
end;

(*function ComputeVDelta(const Eye: vec3_t; const Vect: TVect3D) : vec3_t;
begin
 with Vect do
  begin
   if LowPrecision then
    begin
     Result[0]:=vec3_p(v)^[0] - Eye[0];
     Result[1]:=vec3_p(v)^[1] - Eye[1];
     Result[2]:=vec3_p(v)^[2] - Eye[2];
    end
   else
    with PVect(v)^ do
     begin
      Result[0]:=X - Eye[0];
      Result[1]:=Y - Eye[1];
      Result[2]:=Z - Eye[2];
     end;
  end;
end;

procedure ComputeRadius(Surf: PSurface3D);
var
 Source, Delta: vec3_t;
 PV: PVertex3D;
 I: Integer;
 nRadius: FxFloat;
begin
 with Surf^ do
  begin
   Inc(Surf);
   Source[0]:=0;
   Source[1]:=0;
   Source[2]:=0;
   PV:=PVertex3D(Surf);
   Source:=ComputeVDelta(Source, PV^.v^);
   Radius:=0;
   for I:=2 to VertexCount do
    begin
     Inc(PV);
     Delta:=ComputeVDelta(Source, PV^.v^);
     nRadius:=Sqr(Delta[0])+Sqr(Delta[1])+Sqr(Delta[2]);
     if nRadius>Radius then
      Radius:=nRadius;
    end;
  end;
end;*)

function TGlideSceneObject.StartBuildScene({var PW: TPaletteWarning;} var VertexSize: Integer) : TBuildMode;
begin
{PW:=qrkGlideState.PaletteWarning;}
 VertexSize:=SizeOf(TVertex3D);
 FBuildNo:=1;
 Result:=bmGlide;
end;

function PtrListSortR(Item1, Item2: Pointer): Integer;
begin
 if PChar(Item1)<PChar(Item2) then
  Result:=+1
 else
  if Item1=Item2 then
   Result:=0
  else
   Result:=-1;
end;

procedure TGlideSceneObject.PostBuild(nVertexList, nVertexList2: TList);
var
  Vect: TVect3D;
  I, J, K: Integer;
  nv, nv2: Pointer;
begin
  FVertexList.Clear;

  nVertexList.Sort(PtrListSortR);
  nVertexList2.Sort(PtrListSortR);

  FillChar(Vect, SizeOf(Vect), 0);
  Vect.LowPrecision:=True;

  I:=nVertexList.Count-1;
  if I>=0 then
    nv:=nVertexList[I]
  else
    nv:=Nil;

  J:=nVertexList2.Count-1;
  if J>=0 then
    nv2:=nVertexList2[J]
  else
    nv2:=Nil;

  while (I>=0) and (J>=0) do
  begin
    Vect.LowPrecision:=PChar(nv2)<PChar(nv);
    if Vect.LowPrecision then
    begin
      Vect.v:=nv2;
      Dec(J);
      if J>=0 then
        nv2:=nVertexList2[J];
    end
    else
    begin
      Vect.v:=nv;
      Dec(I);
      if I>=0 then
        nv:=nVertexList[I];
    end;
    FVertexList.Write(Vect, SizeOf(Vect));
  end;

  Vect.LowPrecision:=False;
  for K:=I downto 0 do
  begin
    Vect.v:=nVertexList[K];
    FVertexList.Write(Vect, SizeOf(Vect));
  end;

  Vect.LowPrecision:=True;
  for K:=J downto 0 do
  begin
    Vect.v:=nVertexList2[K];
    FVertexList.Write(Vect, SizeOf(Vect));
  end;
end;

procedure TGlideSceneObject.stScalePoly(Texture: PTexture3; var ScaleS, ScaleT: TDouble);
var
 CorrW, CorrH: TDouble;
begin
  CorrW:= 1/(EchelleTexture*256);
  CorrH:=-1/(EchelleTexture*256);
  with Texture^ do
  begin
    case info.aspectratio of
      GR_ASPECT_8x1: CorrH:=-1/(EchelleTexture*32);
      GR_ASPECT_4x1: CorrH:=-1/(EchelleTexture*64);
      GR_ASPECT_2x1: CorrH:=-1/(EchelleTexture*128);
      GR_ASPECT_1x2: CorrW:= 1/(EchelleTexture*128);
      GR_ASPECT_1x4: CorrW:= 1/(EchelleTexture*64);
      GR_ASPECT_1x8: CorrW:= 1/(EchelleTexture*32);
    end;
    ScaleS:=CorrW*TexW;
    ScaleT:=CorrH*TexH;
  end;
end;


procedure StandardScaling(Tex: PTexture3; var ScaleS, ScaleT: TDouble);
var
 w, h: Integer;
begin
  // This routine was added to show the standard scaling done between routines
  w:=256;
  h:=256;
  case Tex.info.aspectratio of
    GR_ASPECT_8x1: h:=32;
    GR_ASPECT_4x1: h:=64;
    GR_ASPECT_2x1: h:=128;
    GR_ASPECT_1x2: w:=128;
    GR_ASPECT_1x4: w:=64;
    GR_ASPECT_1x8: w:=32;
  end;

  // SilverPaladin - 12/01/2003 - If the tex width was 0, the whole routine was blowing up
  // with a divide by 0.  I've changed it to simply return a scale factor of 1:1.
  // If the width is 0 that needs to be detected and handled somewhere else.
  if Tex.TexW = 0
  then ScaleS := 1
  else ScaleS := w / Tex.TexW;

  // SilverPaladin - 12/01/2003 - Ditto
  if Tex.TexH = 0
  then ScaleT := 1
  else ScaleT := h / Tex.TexH;
end;

procedure TGlideSceneObject.stScaleModel(Skin: PTexture3; var ScaleS, ScaleT: TDouble);
begin
  StandardScaling(Skin, ScaleS, ScaleT);
end;

procedure TGlideSceneObject.stScaleSprite(Skin: PTexture3; var ScaleS, ScaleT: TDouble);
begin
  StandardScaling(Skin, ScaleS, ScaleT);
end;

procedure TGlideSceneObject.stScaleBezier(Texture: PTexture3; var ScaleS, ScaleT: TDouble);
begin
  // SilverPaladin - 1/5/2003 - This is a change.  This routine was not
  // returning a scale but the unaltered w and h variables. So, when handled
  // as a scale, it was enlarging the textures by 256 or 128 (whichever) and
  // I don't think that could have been right.
  StandardScaling(Texture, ScaleS, ScaleT);
end;

 {------------------------}

procedure SetFPUPrecision;
var
 TMPFPControl: Word;
begin
 asm
  fstcw [FPControl]
  fwait
  push eax
  mov ax, [FPControl]
  mov [TMPFPControl], ax
  pop eax
  and [TMPFPControl], $FCFF
  fldcw [TMPFPControl]
  fwait
 end;
end;

procedure RestoreFPUPrecision;
begin
 asm
  fldcw [FPControl]
  fwait
 end;
end;

procedure Do3DFXTwoMonitorsActivation;
begin
 grSstControl(GR_CONTROL_ACTIVATE);
end;

procedure Do3DFXTwoMonitorsDeactivation;
begin
 grSstControl(GR_CONTROL_DEACTIVATE);
end;

procedure Set3DFXGammaCorrection(Value: TDouble);
begin
 grGammaCorrectionValue(Value);
end;

 {------------------------}

type
 TV1 = record
        x, y, oow, sow, tow: FxFloat;
        Scr: Byte;
        OnEdge: Byte;
       end;
 TLoadVProc = procedure (var PrevV1: TV1; PV: PVertex3D);

var
 FlatZFactor, FlatZDelta, FlatZValue: TDouble;
 LoadV: TLoadVProc;
 IteratedAlpha: Boolean;

procedure InitFlatZ;
begin
 FlatZFactor:=(Minoow-Maxoow)/(CCoord.MaxDistance-CCoord.MinDistance+rien);
 FlatZDelta:=Maxoow-CCoord.MinDistance*FlatZFactor;
end;

procedure LoadVFlat(var PrevV1: TV1; PV: PVertex3D); forward;
procedure LoadV3D(var PrevV1: TV1; PV: PVertex3D); forward;

(*procedure TSceneObject.GetProjInfo(var ProjInfo: TProjInfo; nRFactor: scalar_t);
var
 SA,CA,SP,CP: TDouble;
begin
 ProjInfo.Eye:=Eye;
 SA:=Sin(HorzAngle);  CA:=Cos(HorzAngle);
 SP:=Sin(PitchAngle); CP:=Cos(PitchAngle);
 ProjInfo.Look[0]:=CA*CP;
 ProjInfo.Look[1]:=SA*CP;
 ProjInfo.Look[2]:=SP;
 ProjInfo.Right[0]:=SA*nRFactor;
 ProjInfo.Right[1]:=-CA*nRFactor;
 ProjInfo.Right[2]:=0;
 ProjInfo.Up[0]:=-SP*CA*nRFactor;
 ProjInfo.Up[1]:=-SP*SA*nRFactor;
 ProjInfo.Up[2]:=CP*nRFactor;
 ProjInfo.ViewRectLeft  :=ViewRect.Left  +VertexSnapper;
 ProjInfo.ViewRectTop   :=ViewRect.Top   +VertexSnapper;
 ProjInfo.ViewRectRight :=ViewRect.Right +VertexSnapper;
 ProjInfo.ViewRectBottom:=ViewRect.Bottom+VertexSnapper;
 ProjInfo.ooWFactor:=FarDistance*(1/MaxW);
end;*)

procedure TGlideSceneObject.ClearFrame;
var
 L, T, R, B: Integer;
 DepthMaskModified: Boolean;

  procedure ClearFrame1(X,Y,W,H: Integer);
  begin
   grClipWindow(X,Y,X+W,Y+H);
   if not DepthMaskModified then
    begin
     DepthMaskModified:=True;
     grDepthMask(FXFALSE);
    end;
   ClearBuffers(FRAME_COLOR);
  end;

begin
 L:=ViewRect.R.Left;
 T:=ViewRect.R.Top;
 R:=ViewRect.R.Right;
 B:=ViewRect.R.Bottom;
 DepthMaskModified:=False;
 if L>0 then ClearFrame1(0, T, L, B-T);
 if T>0 then ClearFrame1(0, 0, ScreenSizeX, T);
 if R<ScreenSizeX then ClearFrame1(R, T, ScreenSizeX-R, B-T);
 if B<ScreenSizeY then ClearFrame1(0, B, ScreenSizeX, ScreenSizeY-B);
 if DepthMaskModified then
  grDepthMask(FXTRUE);
end;

procedure TGlideSceneObject.RenderTransparent(Transparent: Boolean);
var
 PList: PSurfaces;
begin
  if Transparent=false then
  begin
    PList:=FListSurfaces;
    while Assigned(PList) do
    begin
      if (PList^.Transparent=False) then
        RenderPList(PList, False);
      PList:=PList^.Next;
    end;
  end
  else
  begin
    PList:=FListSurfaces;
    while Assigned(PList) do
    begin
      if (PList^.Transparent=True) or (PList^.NumberTransparentFaces>0) then
        RenderPList(PList, True);
      PList:=PList^.Next;
    end;
  end;
end;

procedure TGlideSceneObject.Render3DView;
var
 OldMinDist, OldMaxDist: TDouble;
begin
 CCoord:=Coord;  { PyMath.CCoord }
 if CCoord.FlatDisplay then
 begin
   InitFlatZ;
   LoadV:=LoadVFlat;
 end
 else
   LoadV:=LoadV3D;

 if RenderMode=rmSolidcolor then
   guColorCombineFunction(GR_COLORCOMBINE_CCRGB)
 else
   guColorCombineFunction(GR_COLORCOMBINE_TEXTURE_TIMES_CCRGB);

 qrkGlideState.SetPerspectiveMode(Ord(CCoord.FlatDisplay)+1);
 if Fog=True then
   grFogTable(FogTableCache^);

 grClipWindow(ViewRect.R.Left, ViewRect.R.Top, ViewRect.R.Right, ViewRect.R.Bottom);

 CurrentAlpha:=0;
 IteratedAlpha:=False;
 {grDepthMask(FXTRUE);}

 grAlphaCombine(GR_COMBINE_FUNCTION_SCALE_OTHER, GR_COMBINE_FACTOR_ONE, GR_COMBINE_LOCAL_NONE, GR_COMBINE_OTHER_CONSTANT, FXFALSE);
 grAlphaBlendFunction(GR_BLEND_ONE, GR_BLEND_ZERO, GR_BLEND_ONE, GR_BLEND_ZERO);

 ClearBuffers(VOID_COLOR);
 Inc(FBuildNo);
{GetProjInfo(ProjInfo, RFactor);
 FProjInfo:=@ProjInfo;}

 if Fog=True then
   grFogMode(GR_FOG_WITH_TABLE)
 else
   grFogMode(GR_FOG_DISABLE);
 RenderTransparent(False);
 {grDepthMask(FXFALSE);}
 grAlphaBlendFunction(GR_BLEND_SRC_ALPHA, GR_BLEND_ONE_MINUS_SRC_ALPHA, GR_BLEND_ONE, GR_BLEND_ZERO);
 RenderTransparent(True);

 if CCoord.FlatDisplay and (TranspFactor>0) then
 begin
   Inc(FBuildNo);
   //grAlphaCombine(GR_COMBINE_FUNCTION_BLEND_LOCAL, GR_COMBINE_FACTOR_OTHER_ALPHA, GR_COMBINE_LOCAL_DEPTH, GR_COMBINE_OTHER_CONSTANT, FXTRUE);
   grAlphaCombine(GR_COMBINE_FUNCTION_SCALE_OTHER, GR_COMBINE_FACTOR_ONE_MINUS_LOCAL_ALPHA, GR_COMBINE_LOCAL_ITERATED, GR_COMBINE_OTHER_CONSTANT, FXFALSE);
   IteratedAlpha:=True;
   //grAlphaCombine(GR_COMBINE_FUNCTION_SCALE_OTHER, GR_COMBINE_FACTOR_LOCAL_ALPHA, GR_COMBINE_LOCAL_CONSTANT, GR_COMBINE_OTHER_ITERATED, FXFALSE);
   //grConstantColorValue($30FFFFFF);
   OldMinDist:=CCoord.MinDistance;
   OldMaxDist:=CCoord.MaxDistance;
   try
     CCoord.MinDistance:=OldMinDist - (OldMaxDist-OldMinDist)*TranspFactor;
     CCoord.MaxDistance:=OldMinDist;
     InitFlatZ;
     grFogMode(GR_FOG_DISABLE);
     grDepthMask(FXFALSE);
     grDepthBufferFunction(GR_CMP_ALWAYS);
     RenderTransparent(False);
     RenderTransparent(True);
   finally
     grDepthBufferFunction(GR_CMP_LESS);
     grDepthMask(FXTRUE);
     if Fog=True then
       grFogMode(GR_FOG_WITH_TABLE);
     CCoord.MinDistance:=OldMinDist;
     CCoord.MaxDistance:=OldMaxDist;
   end;
 end;
end;

procedure Proj(var Vect: TVect3D; const ViewRect: TViewRect; nBuildNo: LongWord{; DistMin, DistMax: FxFloat}) {: Boolean};
var
 V1: TVect;
 PP: TPointProj;
 nOffScreen: Byte;
begin
 with Vect do
  begin
   if LowPrecision then
    begin
     V1.X:=vec3_p(v)^[0];
     V1.Y:=vec3_p(v)^[1];
     V1.Z:=vec3_p(v)^[2];
     PP:=CCoord.Proj(V1);
    end
   else
    PP:=CCoord.Proj(PVect(v)^);
   nOffScreen:=0;
   if CCoord.FlatDisplay then
    begin
     FlatZValue:=PP.oow;
     oow:=FlatZValue*FlatZFactor + FlatZDelta;
     if oow>Maxoow then Inc(nOffScreen, os_Back) else
     if oow<Minoow then Inc(nOffScreen, os_Far);
    end
   else
    begin
     oow:=PP.oow;
     if (oow>Maxoow) or (oow<0) then Inc(nOffScreen, os_Back) else
     if (oow<Minoow)            then Inc(nOffScreen, os_Far);
    end;
    x:=PP.x + ViewRect.ProjDx;
    y:=ViewRect.ProjDy - PP.y;

   if x<ViewRect.Left   then Inc(nOffScreen, os_Left) else
   if x>ViewRect.Right  then Inc(nOffScreen, os_Right);

   if y<ViewRect.Top    then Inc(nOffScreen, os_Top) else
   if y>ViewRect.Bottom then Inc(nOffScreen, os_Bottom);

   OffScreen:=nOffScreen;
   BuildNo:=nBuildNo;
  end;
end;
(*var
 Delta: vec3_t;
 Dist: FxFloat;
 nOffScreen: Byte;
begin
 with ProjInfo, Vect do
  begin
   if LowPrecision then
    begin
     Delta[0]:=vec3_p(v)^[0] - Eye[0];
     Delta[1]:=vec3_p(v)^[1] - Eye[1];
     Delta[2]:=vec3_p(v)^[2] - Eye[2];
    end
   else
    with PVect(v)^ do
     begin
      Delta[0]:=X - Eye[0];
      Delta[1]:=Y - Eye[1];
      Delta[2]:=Z - Eye[2];
     end;
   Dist:=Delta[0]*Look[0]
       + Delta[1]*Look[1]
       + Delta[2]*Look[2];
   if (Dist>-rien) and (Dist<rien) then
    if Dist>0 then
     Dist:=rien
    else
     Dist:=-rien;
   oow:=ooWFactor/Dist;
   x:=(Delta[0]*Right[0]
     + Delta[1]*Right[1]
     + Delta[2]*Right[2]) * oow + (ScreenCenterX+VertexSnapper);
   y:=(Delta[0]*Up[0]
     + Delta[1]*Up[1]
     + Delta[2]*Up[2]) * oow + (ScreenCenterY+VertexSnapper);
   nOffScreen:=0;
   if x<ViewRectLeft   then Inc(nOffScreen, os_Left) else
   if x>ViewRectRight  then Inc(nOffScreen, os_Right);
   if y<ViewRectTop    then Inc(nOffScreen, os_Top) else
   if y>ViewRectBottom then Inc(nOffScreen, os_Bottom);
   if (oow>Maxoow) or (oow<0) then Inc(nOffScreen, os_Back) else
   if oow<Minoow       then Inc(nOffScreen, os_Far);
   OffScreen:=nOffScreen;
   BuildNo:=nBuildNo;
  end;
end;*)

{type          d�clar� plus haut
 TV1 = record
        x, y, oow, sow, tow: FxFloat;
        Scr: Byte;
        OnEdge: Byte;
       end;}

procedure LoadV3D(var PrevV1: TV1; PV: PVertex3D);
begin
  with PV^.v^ do
  begin
    PrevV1.x:=x;
    PrevV1.y:=y;
    PrevV1.oow:=oow;
    PrevV1.sow:=PV^.s*oow;
    PrevV1.tow:=PV^.t*oow;
    PrevV1.Scr:=OffScreen;
    PrevV1.OnEdge:=0;
  end;
end;

procedure LoadVFlat(var PrevV1: TV1; PV: PVertex3D);
begin
  with PV^.v^ do
  begin
    PrevV1.x:=x;
    PrevV1.y:=y;
    PrevV1.oow:=oow;
    PrevV1.sow:=PV^.s;
    PrevV1.tow:=PV^.t;
    PrevV1.Scr:=OffScreen;
    PrevV1.OnEdge:=0;
  end;
end;

procedure TGlideSceneObject.RenderPList(PList: PSurfaces; TransparentFaces: Boolean);
type
 TBBox = (bbX, bbY, bbW);
const
 MAX_VERTICES = 4*MaxFVertices;
 oe_Left   = 1;
 oe_Top    = 2;
 oe_Right  = 3;
 oe_Bottom = 4;
var
 nColor: FxU32;
 NeedTex, PrevChanged: Boolean;
 ScrDiff, ScrTotal: Byte;
 SourceEdge, LastEdge: Byte;
 Surf: PSurface3D;
 SurfEnd: PChar;
 VList: array[0..MAX_VERTICES-1] of GrVertex;
 I, J, N, FindVertexState, CopyV1Count: Integer;
 PV, BaseV, SourceV, LoadedTarget, BaseMaxV: PVertex3D;
 PV1, PrevV1, NewV1, TargetV1: TV1;
 CopyV1: array[1..MAX_VERTICES] of TV1;
 Corners: Integer;
 aa, bb, cc, dd, MinRadius, MaxRadius: FxFloat;
 LocalViewRectLeft,
 LocalViewRectTop,
 LocalViewRectRight,
 LocalViewRectBottom: FxFloat;
 PSD: TPixelSetDescription;

  procedure ScaleInterval(var PrevV1: TV1; const PV1: TV1; F: FxFloat; BBox: TBBox; nValue: FxFloat);
  var
   nScr: Byte;
  begin
   nScr:=0;
   if BBox=bbX then
    PrevV1.x:=nValue
   else
    begin
     PrevV1.x:=PrevV1.x + (PV1.x-PrevV1.x)*F;
     if PrevV1.x<LocalViewRectLeft  then Inc(nScr, os_Left) else
     if PrevV1.x>LocalViewRectRight then Inc(nScr, os_Right);
    end;
   if BBox=bbY then
    PrevV1.y:=nValue
   else
    begin
     PrevV1.y:=PrevV1.y + (PV1.y-PrevV1.y)*F;
     if PrevV1.y<LocalViewRectTop    then Inc(nScr, os_Top) else
     if PrevV1.y>LocalViewRectBottom then Inc(nScr, os_Bottom);
    end;
   if BBox=bbW then
    PrevV1.oow:=nValue
   else
    begin
     PrevV1.oow:=PrevV1.oow + (PV1.oow-PrevV1.oow)*F;
     {$IFDEF Debug}
     if (PrevV1.oow<1/MaxW) or (PrevV1.oow>1/MinW) then
      Raise InternalE('ScaleInterval');
     {$ENDIF}
    end;
   PrevV1.sow:=PrevV1.sow + (PV1.sow-PrevV1.sow)*F;
   PrevV1.tow:=PrevV1.tow + (PV1.tow-PrevV1.tow)*F;
   PrevV1.Scr:=nScr;
  end;

  procedure ComingFrom(F: FxFloat; BBox: TBBox; nValue: FxFloat);
  begin
   ScaleInterval(PrevV1, PV1, F, BBox, nValue);
   ScrDiff:=PrevV1.Scr xor PV1.Scr;
   PrevChanged:=True;
  end;

  procedure GoingInto(F: FxFloat; BBox: TBBox; nValue: FxFloat);
  begin
   ScaleInterval(PV1, PrevV1, F, BBox, nValue);
   ScrDiff:=PV1.Scr xor PrevV1.Scr;
  end;

  procedure Output(const V1: TV1);
  begin
  {if N>0 then
    with VList[N-1] do
     if Abs(x-V1.x)+Abs(y-V1.y) < MinVertexDist1 then
      Exit;}
   with VList[N] do
    begin
     x:=V1.x;
     y:=V1.y;
     oow:=V1.oow;
     tmuvtx[0].sow:=V1.sow;
     tmuvtx[0].tow:=V1.tow;
    end;
   Inc(N);
  end;

  procedure AddCorners(Target: Byte);
  begin
   while Target<>LastEdge do
    begin
     with VList[N] do
      begin
       case LastEdge of
        oe_Left:   begin
                    x:=LocalViewRectLeft;
                    y:=LocalViewRectTop;
                   end;
        oe_Top:    begin
                    x:=LocalViewRectRight;
                    y:=LocalViewRectTop;
                   end;
        oe_Right:  begin
                    x:=LocalViewRectRight;
                    y:=LocalViewRectBottom;
                   end;
        oe_Bottom: begin
                    x:=LocalViewRectLeft;
                    y:=LocalViewRectBottom;
                   end;
       end;
       z:=Corners;   { linked list }
      end;
     Corners:=N;
     Inc(N);
     LastEdge:=(LastEdge and 3)+1;
    end;
  end;

  function FindVertex : Boolean;
  var
   Scr, Scr2: Byte;
   ClosingLoop: Integer;
  begin
   ClosingLoop:=3;
   Result:=True;
   repeat
    case FindVertexState of
     0: begin  { initialization }
         with SourceV^.v^ do
          begin
           if BuildNo <> FBuildNo then
            Proj(SourceV^.v^, ViewRect, FBuildNo{, MinRadius, MaxRadius});
           if CCoord.FlatDisplay then
            begin
             if (FlatZValue < MinRadius) or (FlatZValue > MaxRadius) then
              begin
               Result:=False;
               Exit;
              end;
            end
           else
            if oow<0 then
             begin
              if MinRadius*oow < T3DCoordinates(CCoord).FCheckRadius then
               begin
                Result:=False;
                Exit;
               end;
             end
            else
             if MaxRadius*oow < T3DCoordinates(CCoord).FCheckRadius then
              begin
               Result:=False;
               Exit;
              end;
           Scr:=OffScreen;
          end;
         if Scr and (os_Back or os_Far) = 0 then
          begin
           LoadV(PV1, SourceV);
           FindVertexState:=1;
           Exit;
          end;
         FindVertexState:=2;
         ClosingLoop:=5;
        end;
     1: begin  { previous vertex (PrevV1) was on-screen }
         if PV=BaseV then
          begin
           Result:=False;
           Exit;
          end;
         Dec(PV);
         with PV^.v^ do
          begin
           if BuildNo <> FBuildNo then
            Proj(PV^.v^, ViewRect, FBuildNo);
           Scr:=OffScreen;
          end;
         LoadV(PV1, PV);
         if Scr and (os_Back or os_Far) = 0 then
          Exit;  { next vertex is also on-screen }
         TargetV1:=PV1;
         LoadedTarget:=PV;
         if Scr and os_Back <> 0 then
          begin   { entering the back area }
           ScaleInterval(PV1, PrevV1,
            (Maxoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Maxoow);
          end
         else
          begin   { entering the far area }
           ScaleInterval(PV1, PrevV1,
            (Minoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Minoow);
          end;
         SourceV:=PV;
         FindVertexState:=2;
         Exit;
        end;
     2: begin  { previous vertex (SourceV) off-screen, searching }
         if PV=BaseV then
          begin
           if ClosingLoop<>3 then
            begin
             Result:=False;
             Exit;
            end;
           ClosingLoop:=4;
           PV:=BaseMaxV;
          end;
         Dec(PV);
         Scr:=SourceV^.v^.OffScreen;
         with PV^.v^ do
          begin
           if BuildNo <> FBuildNo then
            Proj(PV^.v^, ViewRect, FBuildNo);
           Scr2:=OffScreen;
           if (Scr and (os_Back or os_Far)) = (Scr2 and (os_Back or os_Far)) then
            SourceV:=PV   { keep searching }
           else
            begin
             if LoadedTarget=SourceV then
              PV1:=TargetV1
             else
              LoadV(PV1, SourceV);
             LoadV(TargetV1, PV);
             LoadedTarget:=PV;
             if Scr and os_Back <> 0 then
              begin   { entering the visible area from os_Back }
               ScaleInterval(PV1, TargetV1,
                (Maxoow-PV1.oow) / (TargetV1.oow-PV1.oow), bbW, Maxoow);
              end
             else
              begin   { entering the visible area from os_Far }
               ScaleInterval(PV1, TargetV1,
                (Minoow-PV1.oow) / (TargetV1.oow-PV1.oow), bbW, Minoow);
              end;
             FindVertexState:=ClosingLoop;
             Exit;
            end;
          end;
        end;
     3: begin  { previous vertex (PrevV1) was on w-edge }
         with PV^.v^ do
          Scr:=OffScreen;
         PV1:=TargetV1;
         if Scr and (os_Back or os_Far) = 0 then
          begin   { target vertex is on-screen }
           FindVertexState:=1;
           Exit;
          end;
         if Scr and os_Back <> 0 then
          begin   { entering the back area }
           ScaleInterval(PV1, PrevV1,
            (Maxoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Maxoow);
          end
         else
          begin   { entering the far area }
           ScaleInterval(PV1, PrevV1,
            (Minoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Minoow);
          end;
         SourceV:=PV;
         FindVertexState:=2;
         Exit;
        end;
     4: begin   { ClosingLoop }
         Result:=False;
         Exit;
        end;
     5: FindVertexState:=3;  { end of initialization }
    end;
   until False;
  end;

begin
 LocalViewRectLeft  :=ViewRect.Left;
 LocalViewRectTop   :=ViewRect.Top;
 LocalViewRectRight :=ViewRect.Right;
 LocalViewRectBottom:=ViewRect.Bottom;

 NeedTex:=(RenderMode=rmTextured);

 Surf:=PList^.Surf;
 SurfEnd:=PChar(Surf)+PList^.SurfSize;

 while Surf<SurfEnd do
 begin
   with Surf^ do
   begin
    Inc(Surf);

    if (((AlphaColor and $FF000000)=$FF000000) xor TransparentFaces) and CCoord.PositiveHalf(Normale[0], Normale[1], Normale[2], Dist) then
    begin
      nColor:=SwapColor(AlphaColor);

      if RenderMode = rmSolidcolor then
      begin
        with PList^.Texture^ do
        begin
          if MeanColor = MeanColorNotComputed then
          begin
            PSD:=GetTex3Description(PList^.Texture^);
            try
              MeanColor:=ComputeMeanColor(PSD);
            finally
              PSD.Done;
            end;
          end;
          nColor:= ((((nColor         and $FF)* (MeanColor         and $FF)) and $00FF00) shl 8)
               or  ((((nColor shr 8)  and $FF)*((MeanColor shr 8)  and $FF)) and $00FF00)
               or (((((nColor shr 16) and $FF)*((MeanColor shr 16) and $FF)) and $00FF00) shr 8)
               or (((nColor shr 24) and $FF) shl 24);
        end;
      end;

      if (nColor<>CurrentAlpha) then
      begin
        grConstantColorValue(nColor);
        CurrentAlpha:=nColor;
      end;

      if CCoord.FlatDisplay then
      begin
        MinRadius:=CCoord.MinDistance-GlideRadius;
        MaxRadius:=CCoord.MaxDistance+GlideRadius;
      end
      else
      begin
        MinRadius:=-GlideRadius;
        MaxRadius:=GlideRadius+FarDistance;
      end;

      PV:=PVertex3D(Surf);
      BaseV:=PV;
      Inc(PV, VertexCount);
      BaseMaxV:=PV;
      SourceV:=BaseV;
      LoadedTarget:=Nil;
      FindVertexState:=0;

      if FindVertex then
      begin
        PrevV1:=PV1;
        N:=0;
        CopyV1Count:=0;
        SourceEdge:=0;
        LastEdge:=0;
        Corners:=-1;
        ScrTotal:=PrevV1.Scr;

        while FindVertex do
        begin
          ScrTotal:=ScrTotal or PV1.Scr;
          Inc(CopyV1Count);
          CopyV1[CopyV1Count]:=PV1;
          if PrevV1.Scr and PV1.Scr <> 0 then
            PrevV1:=PV1  { completely off-screen }
          else
            if PrevV1.Scr or PV1.Scr = 0 then
            begin
              { completely on-screen }
              Output(PV1);
              PrevV1:=PV1;
              LastEdge:=0;
            end
            else
            begin
              { partially on-screen }
              NewV1:=PV1;
              PrevChanged:=False;
              ScrDiff:=PrevV1.Scr xor PV1.Scr;

             {if ScrDiff and os_Back <> 0 then
               if PV1.Scr and os_Back = 0 then
                ComingFrom((Maxoow-PrevV1.oow) / (PV1.oow-PrevV1.oow), bbW, Maxoow)
               else
                GoingInto((Maxoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Maxoow);
              if ScrDiff and os_Far <> 0 then
               if PV1.Scr and os_Far = 0 then
                ComingFrom((Minoow-PrevV1.oow) / (PV1.oow-PrevV1.oow), bbW, Minoow)
               else
                GoingInto((Minoow-PV1.oow) / (PrevV1.oow-PV1.oow), bbW, Minoow);}

              if ScrDiff and os_Left <> 0 then
              begin
                if PV1.Scr and os_Left = 0 then
                begin
                  ComingFrom((LocalViewRectLeft-PrevV1.x) / (PV1.x-PrevV1.x), bbX, LocalViewRectLeft);
                  PrevV1.OnEdge:=oe_Left;
                end
                else
                begin
                  GoingInto((LocalViewRectLeft-PV1.x) / (PrevV1.x-PV1.x), bbX, LocalViewRectLeft);
                  PV1.OnEdge:=oe_Left;
                end;
              end;

              if ScrDiff and os_Right <> 0 then
              begin
                if PV1.Scr and os_Right = 0 then
                begin
                  ComingFrom((LocalViewRectRight-PrevV1.x) / (PV1.x-PrevV1.x), bbX, LocalViewRectRight);
                  PrevV1.OnEdge:=oe_Right;
                end
                else
                begin
                  GoingInto((LocalViewRectRight-PV1.x) / (PrevV1.x-PV1.x), bbX, LocalViewRectRight);
                  PV1.OnEdge:=oe_Right;
                end;
              end;

              if ScrDiff and os_Top <> 0 then
              begin
                if PV1.Scr and os_Top = 0 then
                begin
                  ComingFrom((LocalViewRectTop-PrevV1.y) / (PV1.y-PrevV1.y), bbY, LocalViewRectTop);
                  PrevV1.OnEdge:=oe_Top;
                end
                else
                begin
                  GoingInto((LocalViewRectTop-PV1.y) / (PrevV1.y-PV1.y), bbY, LocalViewRectTop);
                  PV1.OnEdge:=oe_Top;
                end;
              end;

              if ScrDiff and os_Bottom <> 0 then
              begin
                if PV1.Scr and os_Bottom = 0 then
                begin
                  ComingFrom((LocalViewRectBottom-PrevV1.y) / (PV1.y-PrevV1.y), bbY, LocalViewRectBottom);
                  PrevV1.OnEdge:=oe_Bottom;
                end
                else
                begin
                  GoingInto((LocalViewRectBottom-PV1.y) / (PrevV1.y-PV1.y), bbY, LocalViewRectBottom);
                  PV1.OnEdge:=oe_Bottom;
                end;
              end;

              if PrevV1.Scr or PV1.Scr = 0 then
              begin
                { the resulting line is on-screen }
                if PrevChanged then
                begin
                  if (LastEdge<>0) and (PrevV1.OnEdge<>0) then
                    AddCorners(PrevV1.OnEdge);
                  if N=0 then
                    SourceEdge:=PrevV1.OnEdge;
                  Output(PrevV1);
                end;
                Output(PV1);
                LastEdge:=PV1.OnEdge;
              end;

              PrevV1:=NewV1;
            end;
        end;

        if (LastEdge<>0) and (SourceEdge<>0) then
          AddCorners(SourceEdge);

        if (N=0) and (ScrTotal
        and (os_Top or os_Bottom or os_Left or os_Right)
          = (os_Top or os_Bottom or os_Left or os_Right)) then
        begin  { maybe we are in the case of a big, full-screen polygon }
          aa:=(LocalViewRectLeft+LocalViewRectRight)*0.5;
          bb:=(LocalViewRectTop+LocalViewRectBottom)*0.5;
          PV:=BaseMaxV;
          SourceV:=BaseV;
          LoadedTarget:=Nil;
          FindVertexState:=0;
          FindVertex;
          repeat
            PrevV1:=PV1;
            if not FindVertex then
            begin  { we are in this case }
              LastEdge:=oe_Left;
              AddCorners(oe_Right);
              AddCorners(oe_Left);
              Break;
            end;
          until (PV1.y-PrevV1.y)*(aa-PrevV1.x) > (PV1.x-PrevV1.x)*(bb-PrevV1.y);
        end;

        if N>=3 then
        begin
          if Corners>=0 then
          begin
            { keep only three of the points in CopyV1:
               [1] the one with the largest absolute w
               [2] the fartest from [1] as seen on screen
               [3] to make the largest triangle on screen }
            aa:=abs(CopyV1[1].oow);
            I:=1;
            for J:=2 to CopyV1Count do
            begin
              bb:=abs(CopyV1[J].oow);
              if bb<aa then
              begin
                aa:=bb;
                I:=J;
              end;
            end;
            PV1:=CopyV1[I];
            CopyV1[I]:=CopyV1[1];
            CopyV1[1]:=PV1;
            aa:=-1;
            for J:=2 to CopyV1Count do
            begin
              bb:=Sqr(CopyV1[J].x - PV1.x) + Sqr(CopyV1[J].y - PV1.y);
              if bb>aa then
              begin
                aa:=bb;
                I:=J;
              end;
            end;
            PV1:=CopyV1[I];
            CopyV1[I]:=CopyV1[2];
            CopyV1[2]:=PV1;
            dd:=rien2;
            I:=0;
            aa:=CopyV1[2].x-CopyV1[1].x;
            cc:=CopyV1[2].y-CopyV1[1].y;
            for J:=3 to CopyV1Count do
            begin
              bb:=aa*(CopyV1[J].y-CopyV1[1].y) - (CopyV1[J].x-CopyV1[1].x)*cc;
              if Abs(bb)>Abs(dd) then
              begin
                dd:=bb;
                I:=J;
              end;
            end;

            { equations to solve :
               a*(CopyV1[2].x-CopyV1[1].x) + b*(CopyV1[3].x-CopyV1[1].x) = x-CopyV1[1].x
               a*(CopyV1[2].y-CopyV1[1].y) + b*(CopyV1[3].y-CopyV1[1].y) = y-CopyV1[1].y }

            if I=0 then
              N:=1   { error, ignore polygon }
            else
            begin
              dd:=1/dd;
              repeat
                with VList[Corners] do
                begin
                  aa:=((x-CopyV1[1].x)*(CopyV1[I].y-CopyV1[1].y) - (CopyV1[I].x-CopyV1[1].x)*(y-CopyV1[1].y)) * dd;
                  bb:=((y-CopyV1[1].y)*(CopyV1[2].x-CopyV1[1].x) - (CopyV1[2].y-CopyV1[1].y)*(x-CopyV1[1].x)) * dd;

                  oow:=CopyV1[1].oow + aa*(CopyV1[2].oow-CopyV1[1].oow) + bb*(CopyV1[I].oow-CopyV1[1].oow);

                  tmuvtx[0].sow:=CopyV1[1].sow + aa*(CopyV1[2].sow-CopyV1[1].sow) + bb*(CopyV1[I].sow-CopyV1[1].sow);
                  tmuvtx[0].tow:=CopyV1[1].tow + aa*(CopyV1[2].tow-CopyV1[1].tow) + bb*(CopyV1[I].tow-CopyV1[1].tow);

                  Corners:=Round(z);
                  z:=0;
                end;
              until Corners<0;
            end;
          end;

         {with VList[N-1] do
           if Abs(x-VList[0].x)+Abs(y-VList[0].y) < MinVertexDist1 then
            Dec(N);}

        (*aa:=VList[0].x; bb:=aa;
          cc:=VList[0].y; dd:=cc;
          for I:=1 to N-1 do
           with VList[I] do
            begin
             if x<aa then aa:=x;
             if x>bb then bb:=x;
             if y<cc then cc:=y;
             if y>dd then dd:=y;
            end;*)

          if (N>=3) {and (bb-aa>MinVertexDist1) and (dd-cc>MinVertexDist1)} then
          begin
            if NeedTex then
            begin
              qrkGlideState.NeedTex(PList^.Texture);
              NeedTex:=False;
            end;

            SetFPUPrecision();
            try
              for I:=0 to N-1 do
              begin
                with VList[I] do
                begin
                  x:=x-VertexSnapper;
                  y:=y-VertexSnapper;
                  tmuvtx[0].oow:=1.0;
                end;
              end;

              if IteratedAlpha then
              begin
                for I:=0 to N-1 do
                begin
                  with VList[I] do
                    a:=oow * (MinW*255.0);
                end;
              end;

             {grDrawPlanarPolygonVertexList(N, VList[0]);
             {grDrawPolygonVertexList(N, VList[0]);}
              for I:=1 to N-2 do
              begin
                if {Abs((VList[I+1].x-VList[0].x)*(VList[I].y-VList[0].y)
                      -(VList[I+1].y-VList[0].y)*(VList[I].x-VList[0].x))
                 > MinTriangleArea2} True then
                  grDrawTriangle(VList[0], VList[I], VList[I+1]);
                  //FIXME: Implement grAADrawTriangle too?
              end;
            finally
              RestoreFPUPrecision();
            end;
          end;
        end;
      end;
    end;

    Inc(PVertex3D(Surf), VertexCount);
   end;
 end;
end;

procedure TGlideSceneObject.Draw3DView;
var
 I, L, R, T, B, Count1: Integer;
 bmiHeader: TBitmapInfoHeader;
 BmpInfo: TBitmapInfo;
 info: GrLfbInfo_t;
 Bits, SrcPtr: Pointer;
 FrameBrush: HBrush;
 DIBSection: HGDIOBJ;

  procedure Frame(X,Y,W,H: Integer);
  var
   Rect: TRect;
  begin
   if FrameBrush=0 then
    FrameBrush:=CreateSolidBrush(SwapColor(FRAME_COLOR));
   Rect:=Bounds(X,Y,W,H);
   FillRect(ViewDC, Rect, FrameBrush);
  end;

begin
 (* In case of hardware drawing:
  grBufferSwap(0);
  grSstIdle;
  Exit;
 *)

 FillChar(bmiHeader, SizeOf(bmiHeader), 0);
 FillChar(BmpInfo, SizeOf(BmpInfo), 0);
 with bmiHeader do
  begin
   biSize:=SizeOf(TBitmapInfoHeader);
   biPlanes:=1;
   biBitCount:=24;
   biCompression:=BI_RGB;
   biWidth:=ViewRect.R.Right-ViewRect.R.Left;
   biHeight:=ViewRect.R.Bottom-ViewRect.R.Top;
  end;
 BmpInfo.bmiHeader:=bmiHeader;

 SetViewDC(True);
 try
   DIBSection:=CreateDIBSection(ViewDC,bmpInfo,DIB_RGB_COLORS,Bits,0,0);
   if DIBSection = 0 then
     Raise EErrorFmt(6200, ['CreateDIBSection']);
   try
    FillChar(info, SizeOf(info), 0);
    info.size := sizeof(GrLfbInfo_t);
    if not grLfbLock(GR_LFB_READ_ONLY or GR_LFB_IDLE, GR_BUFFER_BACKBUFFER, GR_LFBWRITEMODE_ANY, GR_ORIGIN_UPPER_LEFT, FXFALSE, info) then
      Raise EErrorFmt(6200, ['grLfbLock']);
    try
      if info.writeMode <> GR_LFBWRITEMODE_565 then
        Raise EErrorFmt(6200, ['grLfbLock']);
      I:=bmiHeader.biHeight;
      SrcPtr:=info.lfbptr;
      Inc(PChar(SrcPtr), ViewRect.R.Left*2 + (ScreenSizeY-ViewRect.R.Bottom)*Integer(info.strideInBytes));
      Count1:=(ViewRect.R.Right-ViewRect.R.Left) div 4;
      asm
       push esi
       push edi
       mov edi, [Bits]

       @BoucleY:
        mov esi, [SrcPtr]
        mov eax, [info.strideInBytes]
        add eax, esi
        mov [SrcPtr], eax
        mov ecx, [Count1]
        push ebx

        @Boucle:

         mov eax, [esi]
         mov edx, eax
         shl eax, 11    { 1B }
         mov ebx, edx
         shr edx, 3
         mov al, dl     { 1G }
         shl eax, 16
         mov ah, bh     { 1R }
         shr edx, 10
         mov al, dl     { 2B }
         and eax, $F8FCF8F8
         bswap eax
         mov [edi], eax

         shr edx, 6
         shl dh, 3
         and dl, $F8
         bswap edx    { 2G - 2R }
         mov eax, [esi+4]
         add esi, 8
         shld ebx, eax, 16
         shl eax, 3
         mov dh, al   { 3B }
         shl eax, 2
         mov dl, ah   { 3G }
         bswap edx
         mov [edi+4], edx

         mov ah, bl   { 4B }
         shl eax, 11  { 3R }
         mov al, bh   { 4R }
         shr ebx, 3
         mov ah, bl   { 4G }
         and eax, $F8F8FCF8
         bswap eax
         mov [edi+8], eax
         add edi, 12

         dec ecx
        jnz @Boucle

        pop ebx
        dec [I]
       jnz @BoucleY

       pop edi
       pop esi
      end;
     finally
      grLfbUnlock(GR_LFB_READ_ONLY or GR_LFB_IDLE, GR_BUFFER_BACKBUFFER);
     end;

     L:=(ScreenX-bmiHeader.biWidth) div 2;
     T:=(ScreenY-bmiHeader.biHeight) div 2;
     R:=L+bmiHeader.biWidth;
     B:=T+bmiHeader.biHeight;
     FrameBrush:=0;
     try
       if L>0 then Frame(0, T, L, B-T);
       if T>0 then Frame(0, 0, ScreenX, T);
       if R<ScreenX then Frame(R, T, ScreenX-R, B-T);
       if B<ScreenY then Frame(0, B, ScreenX, ScreenY-B);
     finally
       if FrameBrush<>0 then
        DeleteObject(FrameBrush);
     end;
     if SetDIBitsToDevice(ViewDC, L, T, bmiHeader.biWidth, bmiHeader.biHeight, 0,0,
      0,bmiHeader.biHeight, Bits, BmpInfo, DIB_RGB_COLORS) = 0 then
       Raise EErrorFmt(6200, ['SetDIBitsToDevice']);
   finally
     DeleteObject(DIBSection);
   end;
 finally
   SetViewDC(False);
 end;
end;

procedure TGlideSceneObject.SetViewSize(SX, SY: Integer);
var
 XMargin, YMargin: Integer;
begin
 if SX<1 then SX:=1;
 if SY<1 then SY:=1;
 ScreenX:=SX;
 ScreenY:=SY;

 if DisplayMode=dmFullScreen then
  begin
   XMargin:=0;
   YMargin:=0;
  end
 else
  begin
   XMargin:=(ScreenSizeX-SX) div 2;
   if (XMargin<0) then XMargin:=0;
   YMargin:=(ScreenSizeY-SY) div 2;
   if (YMargin<0) then YMargin:=0;
  end;

 ViewRect.R.Left:=XMargin;
 ViewRect.R.Top:=YMargin;
 ViewRect.R.Right:=ScreenSizeX-XMargin;
 ViewRect.R.Bottom:=ScreenSizeY-YMargin;
 ViewRect.R.Left:=ViewRect.R.Left and not 3;
 ViewRect.R.Right:=(ViewRect.R.Right+3) and not 3;

 if Coord=nil then
  begin
   ViewRect.ProjDx:=(VertexSnapper+ScreenCenterX);
   ViewRect.ProjDy:=(VertexSnapper+ScreenCenterY);
  end
 else
  begin
   ViewRect.ProjDx:=(VertexSnapper+ScreenCenterX)-Coord.ScrCenter.X;
   ViewRect.ProjDy:=(VertexSnapper+ScreenCenterY)+Coord.ScrCenter.Y;
  end;

 ViewRect.Left  := ViewRect.R.Left  + (VertexSnapper-0.5);
 ViewRect.Top   := ViewRect.R.Top   + (VertexSnapper-0.5);
 ViewRect.Right := ViewRect.R.Right + (VertexSnapper+0.5);
 ViewRect.Bottom:= ViewRect.R.Bottom+ (VertexSnapper+0.5);
end;

procedure TGlideSceneObject.ChangedViewWnd;
begin
  //FIXME: Do we need to set grSstWinOpen again?
end;

function TGlideSceneObject.ChangeQuality(nQuality: Integer) : Boolean;
begin
 Result:=False;  //DanielPharos: No quality settings for Glide
end;

procedure TGlideSceneObject.BuildTexture(Texture: PTexture3);
var
 PSD, PSD2, PSD3: TPixelSetDescription;
 MemSize, MemSizeTotal, J, w, h: Integer;
 Source, Dest: PChar;
 GammaBuf: Pointer;
begin
  with Texture^.info do
  begin
    if data=Nil then
    begin
      GetwhForTexture(Texture^.info, w, h);
      MemSize:=w*h;

      PSD2.Init;
      PSD2.AlphaBits:=psaNoAlpha;
      PSD:=GetTex3Description(Texture^);

      try
        // Assigned check added by SilverPaladin
        if PSD.Format=psf24bpp then
        begin
          format:=GR_TEXFMT_RGB_565;
          if smallLod<>largeLod then
            raise InternalE('true-color+anti-aliasing');

          MemSize:=MemSize*2;
          GetMem(data, MemSize);

          PSD2.Format:=psf24bpp;
          PSD2.Size.X:=w;
          PSD2.Size.Y:=h;
          PSDConvert(PSD2, PSD, ccTemporary);

          Source:=PSD2.StartPointer;
          Dest:=PChar(data);
          GammaBuf:=@(TTextureManager.GetInstance.GammaBuffer);

          { Make a gamma-corrected copy of the 24-bits (RGB:888) texture to a
            16-bits (RGB:565) data-buffer }
          for J:=1 to h do
          begin
            asm
             push esi
             push edi
             push ebx
             mov ecx, [W]             { get the width, and put it into ecx-register, for the 'loop' to work with }
             mov esi, [Source]        { get the Source-pointer, and put it into esi-register }
             mov edi, [Dest]          { get the Dest-pointer, and put it into edi-register }
             mov ebx, [GammaBuf]      { get the GammaBuf-pointer, and put it into ebx-register }
             cld
             xor edx, edx             { clear the edx-register value (edx-high-register must be zero!) }

             @xloop:
              mov dl, [esi]           { copy 'Blue' byte from source to edx-low-register }
              mov al, [ebx+edx]   {B} { copy the gamma-corrected 'Blue'-byte from gammabuf to eax-low-register }
              mov dl, [esi+1]         { copy 'Green' byte from source to edx-low-register }
              mov ah, [ebx+edx]   {G} { copy the gamma-corrected 'Green'-byte from gammabuf to eax-high-register }
              mov dl, [esi+2]         { copy 'Red' byte from source to edx-low-register }
              mov dl, [ebx+edx]   {R} { copy the gamma-corrected 'Red'-byte from gammabuf to edx-low-register }
              shr ah, 2         {G}   { shift the 'Green'-byte so only 6 bits are used for green }
              shr ax, 3         {GB}  { shift the 'Blue'-byte so only 5 bits are used for blue, and shift the green-bits too to make place for red-bits }
              and dl, $F8       {R}   { filter the 'Red'-byte so only the top 5 bits are used for red }
              or ah, dl         {RGB} { merge the red-bits to the space, now shifted free from green-bits }
              stosw                   { store the two-byte (word) eax value to dest which edi-register points to, and increment edi with 2 }
              add esi, 3              { increment source-pointer, the esi-register with 3 }
             loop @xloop              { decrement ecx-register with 1, and continue to loop if ecx value is bigger than zero }

             mov [Dest], edi          { put the now incremented edi-register value, back as the Dest-pointer }
             pop ebx
             pop edi
             pop esi
            end;

            Inc(Source, PSD2.ScanLine);
          end;
        end
        else
        begin
          format:=GR_TEXFMT_P_8;

          if smallLod<>largeLod then
            MemSizeTotal:=(MemSize*(64+16+4+1)) div 64
          else
            MemSizeTotal:=MemSize;

          GetMem(data, MemSizeTotal);

          PSD2.Format:=psf8bpp;
          PSD2.Size.X:=w;
          PSD2.Size.Y:=h;
          PSD2.ScanLine:=w;
          PSD2.Data:=data;

          PSD3:=PSD2;
          PSDConvert(PSD2, PSD, ccTemporary);

          { gamma correction included in ComputeGuPalette }
          Texture^.GuPalette:=TTextureManager.GetInstance.ComputeGuPalette(PSD2.ColorPalette);

          if smallLod<>largeLod then
          begin
            for J:=1 to 3 do
            begin
              Dest:=PChar(PSD2.Data);

              PSD.Done;
              PSD:=(Texture^.SourceTexture as QTextureFile).ScaledDownDescription(J);

              PSD3.Size.X:=PSD3.Size.X div 2;
              PSD3.Size.Y:=PSD3.Size.Y div 2;
              PSD3.ScanLine:=PSD3.Size.X;
              Inc(PChar(PSD3.Data), MemSize);

              MemSize:=MemSize div 4;

              PSD2.Done;
              PSD2:=PSD3;

              PSDConvert(PSD2, PSD, ccTemporary);
            end;
          end;
        end;
      finally
       PSD.Done;
       PSD2.Done;
      end;
    end;
  end;
end;

 {------------------------}

end.
