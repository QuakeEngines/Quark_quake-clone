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
unit QkHL;

interface

uses Windows, SysUtils, Classes, Graphics, Dialogs, Controls,
     QkObjects, QkFileObjects, QkTextures, QkWad,
     QkQ1;

type
 QTextureHL = class(QTexture1)
        protected
          procedure SaveFile(Info: TInfoEnreg1); override;
          procedure ChargerFin(F: TStream; TailleRestante: Integer); override;
        public
          class function CustomParams : Integer; override;
          class function TypeInfo: String; override;
          function BaseGame : Char; override;
          class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
        end;
 QTextureHL1 = class(QTextureHL)
        public
          class function TypeInfo: String; override;
        end;

const
 SignatureWad3 = $33444157;   { 'WAD3' }

 {------------------------}

implementation

uses Game, Setup, Quarkx, QkObjectClassList;

 {------------------------}

class function QTextureHL.TypeInfo: String;
begin
 TypeInfo:='.wad3_C';
end;

class function QTextureHL1.TypeInfo: String;
begin
 TypeInfo:='.wad3_@';
end;

class procedure QTextureHL.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.FileObjectDescriptionText:=LoadStr1(5164);
end;

class function QTextureHL.CustomParams : Integer;
begin
 Result:=cp4MipIndexes or cpPalette;
end;

function QTextureHL.BaseGame : Char;
begin
 Result:=mjHalfLife;
end;

procedure QTextureHL.ChargerFin(F: TStream; TailleRestante: Integer);
const
 Spec2 = 'Pal=';
 MAXPAL = SizeOf(TPaletteLmp) div SizeOf(TPaletteLmp1);
var
 Data: String;
 P: PPaletteLmp;
 PalSize: SmallInt;
begin
  { reads the palette }
 Data:=Spec2;
 SetLength(Data, Length(Spec2)+SizeOf(TPaletteLmp));
 P:=PPaletteLmp(@Data[Length(Spec2)+1]);
 FillChar(P^, SizeOf(TPaletteLmp), 0);

 if TailleRestante>SizeOf(PalSize) then
  begin
   TailleRestante:=(TailleRestante-SizeOf(PalSize)) div SizeOf(TPaletteLmp1);
   F.ReadBuffer(PalSize, SizeOf(PalSize));
   if PalSize>MAXPAL then
     PalSize:=MAXPAL;
   if PalSize>TailleRestante then
     PalSize:=TailleRestante;
   if PalSize>0 then
     F.ReadBuffer(P^, PalSize*SizeOf(TPaletteLmp1));
  end;

 Specifics.Add(Data);  { "Pal=xxxxx" }
end;

procedure QTextureHL.SaveFile(Info: TInfoEnreg1);
(*
var
 S: String;
 PalSize: SmallInt;
*)
begin
 with Info do case Format of
  rf_Default: begin  { as stand-alone file }
      SaveAsHalfLife(F);
(*
      SaveAsQuake1(F);
       { writes the palette }
      S:=GetSpecArg('Pal');
      if S='' then
       PalSize:=0
      else
       PalSize:=(Length(S)-Length('Pal=')) div SizeOf(TPaletteLmp1);
      F.WriteBuffer(PalSize, SizeOf(PalSize));
      if PalSize>0 then
       F.WriteBuffer((PChar(S)+Length('Pal='))^, PalSize*SizeOf(TPaletteLmp1));
*)
     end;
 else
   inherited;
 end;
end;

 {------------------------}

initialization
  RegisterQObject(QTextureHL, 'a');
  RegisterQObject(QTextureHL1, 'a');
end.
