(**************************************************************************
QuArK -- Quake Army Knife -- 3D game editor
Copyright (C) 1996-99 Armin Rigo

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Contact the author Armin Rigo by e-mail: arigo@planetquake.com
or by mail: Armin Rigo, La Cure, 1854 Leysin, Switzerland.
See also http://www.planetquake.com/quark
**************************************************************************)

unit QkQme;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QkObjects, QkFileObjects, QkForm, TB97, QkMap, QkQuakeC, QkWad, QkPak,
  QkMdl, QkGroup, Python;

type
 QQme = class(QFileObject)
        private
        protected
          function OuvrirFenetre(nOwner: TComponent) : TQForm1; override;
          procedure Enregistrer(Info: TInfoEnreg1); override;
          procedure Charger(F: TStream; Taille: Integer); override;
        public
          class function TypeInfo: String; override;
          procedure EtatObjet(var E: TEtatObjet); override;
          class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
          function IsExplorerItem(Q: QObject) : TIsExplorerItem; override;
          procedure Go1(maplist, extracted: PyObject; var FirstMap: String; QCList: TQList); override;
        end;

type
  TFQQme = class(TQForm1)
  private
    procedure wmMessageInterne(var Msg: TMessage); message wm_MessageInterne;
  protected
    function AssignObject(Q: QFileObject; State: TFileObjectWndState) : Boolean; override;
  end;

 {------------------------}

type
 QQme0  = class(QFileObject) public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme1  = class(QMap       ) public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme2  = class(QQuakeC    ) public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme3  = class(QFileObject) public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme4  = class(QTextureList)public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme5  = class(QImport)     public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme6  = class(QFileObject) public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme7  = class(QExplorerGroup)public class function TypeInfo: String;override;protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;
 QQme8  = class(QMdlFile)    public class function TypeInfo: String; override; protected procedure Charger(F: TStream; Taille: Integer); override; procedure Enregistrer(Info: TInfoEnreg1); override; end;

 {------------------------}

implementation

uses QkMapObjects, QkMapPoly, qmath, Setup, Duplicator, Quarkx, Travail;

{$R *.DFM}

const
 SignatureQM = $50414D51;
 qmDescription = 0;
 qmCarte       = 1;
 qmPatchQC     = 2;
 qmBSP0        = 3;
 qmTextureDef  = 4;
 qmFileDef     = 5;
 qmQContext    = 6;
 qmFileLnk     = 7;
 qmModel       = 8;
 qmInfoTypeMax = 9;

 mapEntity     = 0;
 mapBrush      = 1;
 mapPoly       = 2;
 mapGroup      = 3;
 mapDuplicator = 4;
 mapDigger     = 5;

 MaxNomEntreeQM = 52;

 VersionNXF    = 3;

 nxfBinaire    = 0;
 nxfTexte      = 1;
 nxfNombre     = 2;
 nxfDate       = 3;

type
 TIntroQM = record
             Signature : LongInt;
             PositionRep, TailleRep: LongInt;
            end;
 PEnteteNXF = ^TEnteteNXF;
 TEnteteNXF = record
               Taille: LongInt;
               TailleId: Word;
               Reserve: Byte;
               Format: Byte;
              end;
 TEntreeRepQM = record
                 Nom: array[0..MaxNomEntreeQM-1] of Byte;
                 InfoType, Version: Word;
                 Position: LongInt;
                 Taille: LongInt;
                end;

 {------------------------}

class function QQme0 .TypeInfo; begin TypeInfo:='.qme0';  end;
class function QQme1 .TypeInfo; begin TypeInfo:='.qme1';  end;
class function QQme2 .TypeInfo; begin TypeInfo:='.qme2';  end;
class function QQme3 .TypeInfo; begin TypeInfo:='.qme3';  end;
class function QQme4 .TypeInfo; begin TypeInfo:='.qme4';  end;
class function QQme5 .TypeInfo; begin TypeInfo:='.qme5';  end;
class function QQme6 .TypeInfo; begin TypeInfo:='.qme6';  end;
class function QQme7 .TypeInfo; begin TypeInfo:='.qme7';  end;
class function QQme8 .TypeInfo; begin TypeInfo:='.qme8';  end;

function ReadAsQmeEntry(Q: QFileObject; SourceFile: TStream; Taille: Integer) : Boolean;
var
 I, Compte, TailleIds: Integer;
 Entetes, P: PEnteteNXF;
 Ids, S: String;
begin
 Result:=Q.ReadFormat=rf_Default;
 if Result then
  begin    { reads all QuArK 3.x - style data from the entry into Q.Specifics }
   SourceFile.ReadBuffer(Compte, SizeOf(Compte));
   I:=SizeOf(TEnteteNXF)*Compte;
   GetMem(Entetes, I); try
   SourceFile.ReadBuffer(Entetes^, I);
   TailleIds:=0;
   P:=Entetes;
   for I:=1 to Compte do
    begin
     Inc(TailleIds, P^.TailleId);
     Inc(P);
    end;
   SetLength(Ids, TailleIds);
   if TailleIds>0 then
    SourceFile.ReadBuffer(Ids[1], TailleIds);
   TailleIds:=1;
   P:=Entetes;
   for I:=1 to Compte do
    begin
     S:=Copy(Ids, TailleIds, P^.TailleId)+'=';
     SetLength(S, Length(S)+P^.Taille);
     SourceFile.ReadBuffer(S[P^.TailleId+2], P^.Taille);
     Q.SpecificsAdd(S);
     Inc(TailleIds, P^.TailleId);
     Inc(P);
    end;
   finally FreeMem(Entetes); end;
  end; 
end;

function SaveAsQmeEntry(Q: QFileObject; Format: Integer; F: TStream) : Boolean;
begin
 if Format=rf_Default then
  Raise EError(5554);
 Result:=False;
end;

function SpecAsMemStream(const S: String) : TMemoryStream;
begin
 Result:=TMemoryStream.Create;
 Result.Write(Pointer(S)^, Length(S));
 Result.Position:=0;
end;

 {------------------------}

procedure QQme0 .Charger;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
 else
  inherited;
end;

procedure QQme0. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

 {------------------------}

    { QuArK 4.x maps types and constants }
const
 TailleNomTex = 32;

type
 PSurface = ^TSurface;
 TSurface = record
            { définition de la face }
             Normale: TVect;
             Dist: Reel;
             Params: TFaceParams;
             case Integer of
              0: (Q2Contents, Q2Flags, Q2Value: Integer;
                  NomTex: String[TailleNomTex-1]);
              1: (Q2Data: Byte);
            end;

const
 TailleSurfDef1 = SizeOf(TVect)+6*SizeOf(Reel);     {Normale..Params}
 TailleSurfQ2   = 3*SizeOf(Integer);                {Q2Contents..Q2Value}
 TailleSurfDef  = TailleSurfDef1+TailleSurfQ2;      {Normale..Q2Value}
 TailleSurfPlan = SizeOf(TVect)+SizeOf(Reel);       {Normale..Dist}
 TailleSurfParm1= TailleSurfDef1 - TailleSurfPlan;  {Params}
 TailleSurfParm = TailleSurfDef  - TailleSurfPlan;  {Params..Q2Value}
 TailleSurfVis  = TailleSurfParm + TailleNomTex;    {Params..NomTex}
 tntQuake2 = $80;

type
 PTransfertTreeMap = ^TTransfertTreeMap;
 TTransfertTreeMap = record
                      Tampon: array[0..31, 0..TailleSurfVis-1] of Byte;
                      PositionTampon: Integer;
                     end;

function TTreeMapEntityCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;
function TTreeMapBrushCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;
function TPolyedreCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;
function TTreeMapGroupCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;
function TDuplicatorCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;
function TDiggerCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap; forward;

const
 TreeMapObj : array[mapEntity..mapDigger] of function (S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap
  = (TTreeMapEntityCharger, TTreeMapBrushCharger, TPolyedreCharger,
     TTreeMapGroupCharger, TDuplicatorCharger, TDiggerCharger);

procedure TTreeMapSpecCharger(Q: TTreeMap; S: TStream);
var
 Taille: Word;
 Tampon: String;
begin
 S.ReadBuffer(Taille, SizeOf(Taille));
 SetLength(Tampon, Taille);
 S.ReadBuffer(Pointer(Tampon)^, Taille);
 Q.Specifics.Text:=Tampon;
 Q.Name:=Q.Specifics.Values['classname'];
 Q.Specifics.Values['classname']:='';
end;

function TTreeMapEntityCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
begin
 Result:=TTreeMapEntity.Create('', nParent);
 TTreeMapSpecCharger(Result, S);
end;

function TPolyedreCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
var
 NbFaces: Word;
 I: Integer;
 F: TFace;
 Codes: String;
 Abr: Byte;
 OldF, OldFArray: ^TSurface;
begin
 Result:=TPolyedre.Create(LoadStr1(138), nParent);
 S.ReadBuffer(NbFaces, SizeOf(NbFaces));
 Result.SousElements.Capacity:=NbFaces;
 SetLength(Codes, NbFaces);
 S.ReadBuffer(Pointer(Codes)^, NbFaces);
 GetMem(OldFArray, SizeOf(TSurface)*NbFaces); try
 OldF:=OldFArray;
 for I:=1 to NbFaces do
  begin
   Abr:=Ord(Codes[I]);
   if Abr<8 then
    begin
     FillChar(OldF^.NomTex, TailleNomTex, 0);
     S.ReadBuffer(OldF^.Params, TailleSurfParm1+1);
     SetLength(OldF^.NomTex, OldF^.Q2Data and not tntQuake2);
     S.ReadBuffer(OldF^.NomTex[1], Length(OldF^.NomTex));
     if OldF^.Q2Data and tntQuake2 = tntQuake2 then
      S.ReadBuffer(OldF^.Q2Data, TailleSurfQ2)
     else
      FillChar(OldF^.Q2Data, TailleSurfQ2, 0);
     Move(OldF^.Params, T.Tampon[T.PositionTampon], TailleSurfVis);
     T.PositionTampon:=(T.PositionTampon+1) and 31;
    end
   else
    Move(T.Tampon[Abr and 31], OldF^.Params, TailleSurfVis);
   Inc(OldF);
  end;
 OldF:=OldFArray;
 for I:=1 to NbFaces do
  begin
   Abr:=Ord(Codes[I]);
   if Abr>=8 then
    Abr:=Abr shr 5;
   if Abr=7 then
    S.ReadBuffer(OldF^.Normale, SizeOf(TVect)+SizeOf(Reel))
   else
    begin
     OldF^.Normale:=Origine;
     case Abr of
      1 : OldF^.Normale.X:=-1;
      2 : OldF^.Normale.X:=1;
      3 : OldF^.Normale.Y:=-1;
      4 : OldF^.Normale.Y:=1;
      5 : OldF^.Normale.Z:=-1;
      6 : OldF^.Normale.Z:=1;
     end;
     S.ReadBuffer(OldF^.Dist, SizeOf(Reel));
    end;
   F:=TFace.Create(LoadStr1(139), Result);
   Result.SousElements.Add(F);
   F.NomTex:=OldF^.NomTex;
   F.SetFaceFromParams(OldF^.Normale, OldF^.Dist, OldF^.Params);
   if (OldF^.Q2Contents<>0)
   or (OldF^.Q2Flags<>0)
   or (OldF^.Q2Value<>0) then
    begin
     F.Specifics.Values['Contents']:=IntToStr(OldF^.Q2Contents);
     F.Specifics.Values['Flags']:=IntToStr(OldF^.Q2Flags);
     F.Specifics.Values['Value']:=IntToStr(OldF^.Q2Value);
    end;
   Inc(OldF);
  end;
 finally FreeMem(OldFArray); end;
end;

procedure LoadGroup(Result: TTreeMap; S: TStream; T: PTransfertTreeMap);
var
 I: Integer;
 Nombre: Word;
 InfoTypes: String;
begin
 TTreeMapSpecCharger(Result, S);
 S.ReadBuffer(Nombre, SizeOf(Nombre));
 if Nombre>0 then
  begin
   SetLength(InfoTypes, Nombre);
   S.ReadBuffer(Pointer(InfoTypes)^, Nombre);
   for I:=1 to Nombre do
    begin
     if Ord(InfoTypes[I]) > High(TreeMapObj) then
      Raise EErrorFmt(5509, [9000+Ord(InfoTypes[I])]);
     Result.SousElements.Add(TreeMapObj[Ord(InfoTypes[I])](S, T, Result));
    end;
  end;
end;

function TTreeMapGroupCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
begin
 Result:=TTreeMapGroup.Create('', nParent);
 LoadGroup(Result, S, T);
end;

function TTreeMapBrushCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
begin
 Result:=TTreeMapBrush.Create('', nParent);
 LoadGroup(Result, S, T);
end;

function TDuplicatorCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
var
 Sym, Macro: String;
 I: Integer;
begin
 Result:=TDuplicator.Create('', nParent);
 TTreeMapSpecCharger(Result, S);
 Result.Specifics.Values['out']:='1';
 Macro:='';
 if Result.Specifics.Values['linear']<>'' then
  Macro:='dup lin'
 else
  begin
   Sym:=Result.Specifics.Values['sym'];
   if Sym='' then
    Macro:='dup basic'
   else
    begin
     for I:=1 to Length(Sym) do
      Sym[I]:=Upcase(Sym[I]);
     if Sym='X' then Macro:='symx' else
     if Sym='Y' then Macro:='symy' else
     if Sym='Z' then Macro:='symz' else
     if (Sym='XY') or (Sym='YX') then Macro:='symxy' else
      GlobalWarning(FmtLoadStr1(5624, [Sym]));
    end;
  end;
 Result.Specifics.Values['macro']:=Macro;
end;

function TDiggerCharger(S: TStream; T: PTransfertTreeMap; nParent: QObject) : TTreeMap;
var
 Macro, Depth: String;
begin
 Result:=TDuplicator.Create('', nParent);
 LoadGroup(Result, S, T);
 Depth:=Result.Specifics.Values['hollow'];
 if Depth='' then
  Macro:='digger'
 else
  begin
   Macro:='hollow maker';
   Result.Specifics.Values['hollow']:='';
   Result.Specifics.Values['depth']:=Depth;
  end;
 Result.Specifics.Values['macro']:=Macro;
end;

procedure QQme1 .Charger;
var
 T: TTransfertTreeMap;
 Q: QObject;
 S: String;
 M: TMemoryStream;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
  begin  { turns this data into a map }
   FillChar(T, SizeOf(T), 0);
   S:=Specifics.Values['Map'];
   if S='' then Raise EErrorFmt(5509, [811]);
   M:=SpecAsMemStream(S); try
   Q:=TTreeMapBrushCharger(M, @T, Self);
   SousElements.Add(Q);
   finally M.Free; end;
   Specifics.Values['Root']:=Q.Name+Q.TypeInfo;
   Specifics.Values['Map']:='';
   S:=Specifics.Values['GameCfg'];
   Specifics.Values['GameCfg']:='';
   if (S='') or (CompareText(S, 'Quake')=0) then
    Specifics.Values['Game']:=GetGameName(mjQuake)
   else
    Specifics.Values['Game']:=S;
   FixupAllReferences;
  end
 else
  inherited;
end;

procedure QQme1. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

 {------------------------}

procedure QQme2 .Charger;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
 else
  inherited;
end;

procedure QQme2. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme3 .Charger;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
 else
  inherited;
end;

procedure QQme3. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme4 .Charger;
var
 M: TMemoryStream;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
  begin
   M:=SpecAsMemStream(Specifics.Values['Data']); try
   Specifics.Values['Data']:='';
   inherited Charger(M, M.Size);
   finally M.Free; end;
  end
 else
  inherited;
end;

procedure QQme4. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme5 .Charger;
var
 S: String;
 Folder: QPakFolder;
 nFile: QFileObject;
 I, J: Integer;
 M: TMemoryStream;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
  begin
   Folder:=GetFolder(Specifics.Values['Path']);
   for I:=Specifics.Count-1 downto 0 do
    begin
     S:=Specifics[I];
     if S[1]=':' then
      begin
       J:=Pos('=',S);
       nFile:=BuildFileRoot(Copy(S, 2, J-2), Folder);
       Folder.SousElements.Insert(0, nFile);
       nFile.Flags:=nFile.Flags and not ofFileLink;
       M:=TMemoryStream.Create; try
       M.Write(PChar(S)[J], Length(S)-J);
       M.Position:=0;
       nFile.LoadFromStream(M);
       finally M.Free; end;
       Specifics.Delete(I);
      end;
    end;
  end
 else
  inherited;
end;

procedure QQme5. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme6 .Charger;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
 else
  inherited;
end;

procedure QQme6. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme7 .Charger;
var
 S: String;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
  begin
   S:=Specifics.Values['FileName'];
   if S<>'' then
    LoadedFileLink(S+'.qme', 0);
  end
 else
  inherited;
end;

procedure QQme7. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

procedure QQme8 .Charger;
var
 M: TMemoryStream;
begin
 if ReadAsQmeEntry(Self, F, Taille) then
  begin
   M:=SpecAsMemStream(Specifics.Values['Mdl']); try
   Specifics.Values['Mdl']:='';
   inherited Charger(M, M.Size);
   finally M.Free; end;
  end
 else
  inherited;
end;

procedure QQme8. Enregistrer;
begin
 with Info do if not SaveAsQmeEntry(Self, Format, F) then
  inherited;
end;

 {------------------------}

class function QQme.TypeInfo;
begin
 Result:='.qme';
end;

function QQme.OuvrirFenetre;
begin
 Result:=TFQQme.Create(nOwner);
end;

procedure QQme.EtatObjet(var E: TEtatObjet);
begin
 inherited;
 E.IndexImage:=iiQme;
 E.MarsColor:=clWhite;
end;

class procedure QQme.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.NomClasseEnClair:=LoadStr1(5141);
 Info.FileExt:=783;
 Info.WndInfo:=[wiOwnExplorer];
end;

function QQme.IsExplorerItem(Q: QObject) : TIsExplorerItem;
var
 S: String;
begin
 S:=Q.Name+Q.TypeInfo;
 Result:=ieResult[
  { any ".qme0" to ".qme8" }
    (CompareText(Copy(S, Length(S)-4, 4), '.qme') = 0) and (S[Length(S)] in ['0'..'8'])];
end;

procedure QQme.Charger(F: TStream; Taille: Integer);
var
 Intro: TIntroQM;
 Entree: TEntreeRepQM;
 Origine: LongInt;
 Q: QObject;
 I: Integer;
begin
 case ReadFormat of
  1: begin  { as stand-alone file }
      if Taille<SizeOf(Intro) then
       Raise EError(5519);
      Origine:=F.Position;
      F.ReadBuffer(Intro, SizeOf(Intro));
      if Intro.Signature<>SignatureQM then
       Raise EErrorFmt(5555, [LoadName, Intro.Signature, SignatureQM]);
      for I:=0 to Intro.TailleRep div SizeOf(TEntreeRepQM)-1 do
       begin
        F.Position:=Origine+Intro.PositionRep+I*SizeOf(TEntreeRepQM);
        F.ReadBuffer(Entree, SizeOf(TEntreeRepQM));
        if (Entree.Version<>VersionNXF) or (Entree.InfoType>=qmInfoTypeMax) then
         Raise EErrorFmt(5556, [LoadName, Entree.Version, Entree.InfoType]);
        F.Position:=Origine + Entree.Position;
        Q:=OpenFileObjectData(F, CharToPas(Entree.Nom)+'.qme'+IntToStr(Entree.InfoType),
            Entree.Taille, Self);
        SousElements.Add(Q);
        LoadedItem(rf_Default, F, Q, Entree.Taille);
       end;
     end;
 else inherited;
 end;
end;

procedure QQme.Enregistrer(Info: TInfoEnreg1);
begin
 with Info do case Format of
  1: begin  { as stand-alone file }
      Raise EError(5554);   { not implemented }
     end;
 else inherited;
 end;
end;

procedure QQme.Go1(maplist, extracted: PyObject; var FirstMap: String; QCList: TQList);
var
 I: Integer;
begin
 Acces;
 DebutTravail(175, SousElements.Count); try
 for I:=0 to SousElements.Count-1 do
  begin
   if SousElements[I] is QFileObject then
    QFileObject(SousElements[I]).Go1(maplist, extracted, FirstMap, QCList);
   ProgresTravail;
  end;
 finally FinTravail; end;
end;

 {------------------------}

procedure TFQQme.wmMessageInterne(var Msg: TMessage);
begin
 case Msg.wParam of
  wp_AfficherObjet:
    begin

    end;
 end;
 inherited;
end;

function TFQQme.AssignObject(Q: QFileObject; State: TFileObjectWndState) : Boolean;
begin
 Result:=(Q is QQme) and inherited AssignObject(Q, State);
end;

initialization
  RegisterQObject(QQme, 'b');
  RegisterQObject(QQme0,  'a');
  RegisterQObject(QQme1,  'a');
  RegisterQObject(QQme2,  'a');
  RegisterQObject(QQme3,  'a');
  RegisterQObject(QQme4,  'a');
  RegisterQObject(QQme5,  'a');
  RegisterQObject(QQme6,  'a');
  RegisterQObject(QQme7,  'a');
  RegisterQObject(QQme8,  'a');
end.
