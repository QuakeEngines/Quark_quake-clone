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

unit Qk1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QkGroup, StdCtrls, ExtCtrls, CommCtrl, QkExplorer, QkObjects,
  QkFileObjects, Menus, TB97, QkFileExplorer, ShellApi,
  QkForm, ComCtrls, Buttons;

const
  BlueHintPrefix = '?';

type
  TIdleJobEvent = function (Counter: Integer) : Integer of object;
  PIdleJob = ^TIdleJob;
  TIdleJob = record
              Counter: Integer;
              Event: TIdleJobEvent;
              Control: TObject;
              Next: PIdleJob;
              Working: Boolean;
             end;

  TQrkExplorer = class(TFileExplorer)
  protected
   {function AfficherObjet(Parent, Enfant: QObject) : Integer; override;}
  (*procedure InvalidatePaintBoxes(ModifSel: Integer); override;*)
   {procedure DoubleClic; override;}
  (*procedure OpDansScene(Q: QObject; Aj: TAjScene; PosRel: Integer); override;*)
  public
  (*function MsgUndo(Op: TMsgUndo; Data: Pointer) : Pointer; override;*)
   {procedure MAJAffichage(Q: QFileObject); override;}
    procedure GetExplorerInfo(var Info: TExplorerInfo); override;
    function DropObjectsNow(Gr: QExplorerGroup; const Texte: String; Beep: boolean) : Boolean; override;
    procedure ReplaceRoot(Old, New: QObject); override;
  end;

  TForm1 = class(TQkForm)
    Panel2: TPanel;
    topdock: TDock97;
    ToolbarMenu1: TToolbar97;
    Edit1: TToolbarButton97;
    FileMenu: TPopupMenu;
    EditMenu: TPopupMenu;
    Undo1: TMenuItem;
    Redo1: TMenuItem;
    N1: TMenuItem;
    File1: TToolbarButton97;
    News1: TMenuItem;
    Open1: TMenuItem;
    Saveall1: TMenuItem;
    Saveinnewentry1: TMenuItem;
    Saveasfile1: TMenuItem;
    N3: TMenuItem;
    Close1: TMenuItem;
    leftdock: TDock97;
    rightdock: TDock97;
    bottomdock: TDock97;
    Panel3: TPanel;
    Window1: TToolbarButton97;
    Help1: TToolbarButton97;
    WindowMenu: TPopupMenu;
    TbList1: TMenuItem;
    MainWindow1: TMenuItem;
    ToolbarMenu2: TToolbar97;
    Games1: TToolbarButton97;
    Minimize1: TMenuItem;
    OpenSel1: TMenuItem;
    N4: TMenuItem;
    Copy1: TMenuItem;
    Cut1: TMenuItem;
    Paste1: TMenuItem;
    Delete1: TMenuItem;
    WinList1: TMenuItem;
    Saveentryasfile1: TMenuItem;
    Save1: TMenuItem;
    SSep1: TMenuItem;
    Copyas1: TMenuItem;
    N2: TMenuItem;
    FileSep1: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    GamesMenu: TPopupMenu;
    PasteObj1: TMenuItem;
    N10: TMenuItem;
    Properties1: TMenuItem;
    GameSep1: TMenuItem;
    Options2: TMenuItem;
    Addons1: TMenuItem;
    ObjMenu: TPopupMenu;
    ObjSep1: TMenuItem;
    Cut2: TMenuItem;
    Copy2: TMenuItem;
    OpenSel2: TMenuItem;
    Properties2: TMenuItem;
    N12: TMenuItem;
    UndoRedo1: TMenuItem;
    N11: TMenuItem;
    Configuration1: TMenuItem;
    HelpMenu: TPopupMenu;
    Importfromfile1: TMenuItem;
    Importfiles1: TMenuItem;
    Makefilelinks1: TMenuItem;
    About1: TMenuItem;
    ExtEdit1: TMenuItem;
    Outputdirectories1: TMenuItem;
    Viewconsole1: TMenuItem;
    N13: TMenuItem;
    Go1: TMenuItem;
    Registering1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Edit1Click(Sender: TObject);
    procedure EditMacroClick(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure WindowMenuPopup(Sender: TObject);
    procedure MainWindow1Click(Sender: TObject);
    procedure Minimize1Click(Sender: TObject);
    procedure EditMenuItemClick(Sender: TObject);
    procedure ToolBoxClick(Sender: TObject);
    procedure News1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Saveentryasfile1Click(Sender: TObject);
    procedure Saveall1Click(Sender: TObject);
    procedure Saveinnewentry1Click(Sender: TObject);
    procedure CopyAsClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure RecentFileClick(Sender: TObject);
    procedure GameSwitch1Click(Sender: TObject);
    procedure Go1Click(Sender: TObject);
    procedure Games1Click(Sender: TObject);
    procedure PasteObj1Click(Sender: TObject);
    procedure Options2Click(Sender: TObject);
    procedure Makefilelink1Click(Sender: TObject);
    procedure Importfromfile1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Addons1Click(Sender: TObject);
    procedure Outputdirectories1Click(Sender: TObject);
    procedure Viewconsole1Click(Sender: TObject);
    procedure HelpMenuItemClick(Sender: TObject);
    procedure Registering1Click(Sender: TObject);
  private
    IdleJobs: PIdleJob;
    {DefaultTbCount,} OpenFilterIndex: Integer;
    FNoTempDelete: Boolean;
   {TbMenuChar: Char;}
    procedure ReadSetupInformation(Level: Integer);
   {function LoadToolBoxInformation(SetupQrk: QObject) : Integer;}
    function LoadToolBoxList(SetupQrk: QObject) : Integer;
   {function GetGlobalModified : Boolean;
    procedure SetGlobalModified(Value: Boolean);}
    procedure MenuCopyAs;
{$IFDEF Debug} procedure DataDump1Click(Sender: TObject); {$ENDIF}
    function ProcessCmdLine(Counter: Integer) : Integer;
    procedure LibererMemoireFiches(Sender: TObject);
  protected
    procedure AppIdle(Sender: TObject; var Done: Boolean);
   {procedure AppRestore(Sender: TObject);}
    procedure AppActivate(Sender: TObject);
    procedure AppDeactivate(Sender: TObject);
    procedure AppExceptionMore(Sender: TObject);
    procedure AppShowHint(var HintStr: string; var CanShow: Boolean; var HintInfo: THintInfo);
    procedure AppHint(Sender: TObject);
   {function AppHelp(Command: Word; Data: LongInt; var CallHelp: Boolean) : Boolean;}
    function WindowHook(var Msg: TMessage) : Boolean;
    procedure cmSysColorChange(var Msg: TWMSysCommand); message cm_SysColorChange;
    procedure wmMessageInterne(var Msg: TMessage); message wm_MessageInterne;
    procedure wmDropFiles(var Msg: TMessage); message wm_DropFiles;
    procedure wmCompacting(var Msg: TMessage); message wm_Compacting;
    procedure wmRenderFormat(var Msg: TMessage); message wm_RenderFormat;
    procedure wmRenderAllFormats(var Msg: TMessage); message wm_RenderAllFormats;
    procedure wmDestroyClipboard(var Msg: TMessage); message wm_DestroyClipboard;
   {procedure wmCommand(var Msg: TMessage); message wm_Command;}
  public
    Explorer: TQrkExplorer;
    procedure StartIdleJob(nEvent: TIdleJobEvent; nControl: TObject);
    procedure AbortIdleJob(nControl: TObject);
    procedure Save(AskName: Integer);
    procedure ClearExplorer;
    procedure SetExplorerRoot(Root: QFileObject);
    function NeedExplorerRoot : QExplorerGroup;
   {property GlobalModified: Boolean read GetGlobalModified write SetGlobalModified;}
    property NoTempDelete: Boolean write FNoTempDelete;
    procedure OpenAFile(const FileName: String; ReadOnly: Boolean);
    procedure SavePendingFiles(CanCancel: Boolean);
    function MessageException(E: Exception; const Info: String; Buttons: TMsgDlgButtons) : TModalResult;
    procedure AppException(Sender: TObject; E: Exception);
    function GetEmptyMenu : TPopupMenu;
    function GetObjMenu(Control: TControl; Extra: Boolean) : TPopupMenu;
    procedure LibererMaxMemoire;
  end;

var
  Form1: TForm1;
  Form1Handle: HWnd;

 {------------------------}

implementation

uses Undo, Travail, QkQuakeC, Setup, Config, ToolBox1, Game, QkOwnExplorer,
  QkTextures, ObjProp, qmath, TbUndoMenu, QkInclude, About, Running,
  Output1, QkTreeView, Quarkx, Ed3DFX, PyProcess, Console, Python,
  {$IFDEF Debug} MemTester, {$ENDIF} PyMapView, QkMdlObjects, PyForms;

{$R *.DFM}
{$R ICONES\ICONES.RES}

 {------------------------}

 (*procedure TForm1.Button1Click(Sender: TObject);
var
 P,Q: QObject;
 U: TUndoObject;
begin
 P:=Explorer.TMSelUnique;
 if P=Nil then
  if Explorer.Roots.Count=0 then
   begin
    P:=BuildFileRoot('Bonjour !.qrk', Nil);
    SetExplorerRoot(P as QFileObject);
    {VolatileData.SousElements.Add(P);}
   end
  else
   P:=Explorer.Roots[0];
 if Random(2)=1 then
  Q:=QExplorerGroup.Create('Sous-�l�ment', P)
 else
  Q:=QQuakeC.Create('QuakeC', P);
 U:=TQObjectUndo.Create('temp', Nil, Q);
 Action(Explorer.Roots[0], U);
end;*)

procedure TForm1.ClearExplorer;
var
 Q: QFileObject;
begin
 Explorer.MAJAffichage(Nil);
 try
  if Explorer.Roots.Count>0 then
   begin
    Q:=Explorer.Roots[0] as QFileObject;
    if Q.Flags and ofModified<>0 then
     begin
      ActivateNow(Self);
      case MessageDlg(FmtLoadStr1(5212, [Explorer.Roots[0].Name]), mtConfirmation, mbYesNoCancel, 0) of
       mrYes: begin
               Explorer.CloseUndoObjects;
               Save(fm_Save);
              end;
       mrNo: ;
      else Abort;
      end;
     end;
    Q.CloseUndo;
    SavePendingFiles(True);
   end;
 {ClearUndo(0);}
  Explorer.ClearView;
  UpdateForm1Root;
 finally
  Explorer.InvalidatePaintBoxes(0);
 end;
end;

procedure TForm1.SetExplorerRoot(Root: QFileObject);
begin
 ClearExplorer;
 Explorer.AddRoot(Root);
 UpdateForm1Root;
{Timer1Timer(Nil);}
end;

function TForm1.NeedExplorerRoot : QExplorerGroup;
begin
 if Explorer.Roots.Count=0 then
  begin
   FileMenu.PopupComponent:=File1;
   News1Click(Nil);
  end;
 Result:=Explorer.Roots[0] as QExplorerGroup;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 Item: TMenuItem;
 I, J: Integer;
 S: String;
 L: TStringList;
 C: TColor;
begin
 Application.OnException:=AppException;
 Application.UpdateFormatSettings:=False;
 DecimalSeparator:='.';
 Form1Handle:=Handle;

 PythonLoadMain;

(*ImageList1.Handle:=ImageList_LoadImage(HInstance, MakeIntResource(101),
  16, 2, clTeal, Image_Bitmap, 0);
{ImageList1.Overlay(iiLinkOverlay, 0);}
 OverlayImageList:=ImageList1.Handle;
 OverlayImageIndex:=iiLinkOverlay;*)

 MarsCap.AppCaption:='QuArK';
 MarsCap.ActiveBeginColor:=clNavy;
 MarsCap.ActiveEndColor:=clNavy;
 SetFormIcon(iiQuArK);

 Explorer:=TQrkExplorer.Create(Self);
{Explorer.Visible:=False;}
 Explorer.Parent:=Panel3;
 Explorer.Width:=160;
 Explorer.Align:=alLeft;
 Explorer.AllowEditing:=aeUndo;
{Explorer.ObjToolBar:=ToolBarObj1;}
 Explorer.SetMarsCaption(Self);
 Explorer.ViewPanel:=Panel2;
 Explorer.CreateSplitter;
 {InitSetup;  called by PythonLoadMain}
 ClearExplorer;
 RestorePositionTb('Main', False, Explorer);
 OnClose:=FormClose;
 OnDestroy:=FormDestroy;
 Application.HookMainWindow(WindowHook);
 Application.OnIdle:=AppIdle;
 Application.OnActivate:=AppActivate;
 Application.OnDeactivate:=AppDeactivate;
 Application.OnShowHint:=AppShowHint;
 Application.OnHint:=AppHint;
{Application.OnHelp:=AppHelp;}
{Application.OnRestore:=AppRestore;}     { MARSCAPFIX }

 J:=0;
 with SetupSet[ssGames] do
  for I:=0 to SousElements.Count-1 do
   begin
    S:=SousElements[I].Specifics.Values['Code'];
    if S<>'' then
     begin
      Item:=TMenuItem.Create(Self);
      Item.Caption:=SousElements[I].Name;
      Item.OnClick:=GameSwitch1Click;
      Item.Tag:=Ord(S[1]);
      Item.RadioItem:=True;
      GamesMenu.Items.Insert(J, Item);
      Inc(J);
     end;
   end;

 L:=TStringList.Create; try
 InitGamesMenu(L);
 for I:=0 to L.Count-1 do
  begin
   Item:=TMenuItem.Create(Self);
   Item.Caption:=L[I];
   Item.OnClick:=Go1Click;
   Item.Tag:=I;
   Go1.Add(Item);
  end;
 finally L.Free; end;

 {$IFDEF Debug}
 Item:=TMenuItem.Create(Self);
 Item.Caption:='Data dump (for DEBUG only)';
 Item.OnClick:=DataDump1Click;
 HelpMenu.Items.Add(Item);
 Item:=TMenuItem.Create(Self);
 Item.Caption:='Free some memory (for DEBUG only)';
 Item.OnClick:=LibererMemoireFiches;
 HelpMenu.Items.Add(Item);
 {$ENDIF}

 C:=GetDockColor;
 topdock.Color:=C;
 leftdock.Color:=C;
 rightdock.Color:=C;
 bottomdock.Color:=C;

{Image1.Picture.Bitmap.LoadFromResourceName(HInstance, 'QUARKLOGO');
 StatusBar1.SimpleText:=FmtLoadStr1(1, [QuarkVersion]);}
end;

procedure TForm1.cmSysColorChange(var Msg: TWMSysCommand);
var
 C: TColor;
begin
 C:=GetDockColor;
 topdock.Color:=C;
 leftdock.Color:=C;
 rightdock.Color:=C;
 bottomdock.Color:=C;
end;

(*procedure TForm1.AppRestore;
var
 F: TForm;
begin
 F:=Screen.ActiveForm;
 if F<>Nil then
  F.Perform(WM_NCACTIVATE, 1, 0);
end;*)

procedure TForm1.AppIdle;
var
 P, Q: PIdleJob;
begin
 Done:=ClearPool(False);
 ClearObjectManager;
 ClearTimers;
 ClearMdlObjects;
 {$IFDEF DebugNOTYET} if MemWatch<>Nil then MemWatch.Invalidate; {$ENDIF}
 GlobalDisplayWarnings;
 if IdleJobs<>Nil then
  begin
   P:=IdleJobs;
   IdleJobs:=P^.Next;
   if not P^.Working then
    begin
     try
      P^.Working:=True;
      try
       P^.Counter:=P^.Event(P^.Counter);
      except
       on E: Exception do
        begin
         P^.Counter:=-1;
         AppException(Nil, E);
        end;
      end;
     finally
      P^.Working:=False;
     end;
     if P^.Counter<0 then
      begin
       if P^.Control is TWinControl then
        TWinControl(P^.Control).Cursor:=crDefault;
       Dispose(P);
      end
     else
      if IdleJobs=Nil then
       IdleJobs:=P
      else
       begin
        Q:=IdleJobs;
        while Q^.Next<>Nil do
         Q:=Q^.Next;
        Q^.Next:=P;
        P^.Next:=Nil;
       end;
    end;
   Done:=Done and (IdleJobs=Nil);
  end;
 if Done then
  begin
   SizeDownGameFiles;
  {SaveSetupNow;}
  end;
 {$IFDEF Debug}
 if Screen.ActiveForm<>Nil then MemTesting(Screen.ActiveForm.Handle);
 {$ENDIF}
end;

procedure TForm1.AbortIdleJob(nControl: TObject);
var
 P: ^PIdleJob;
 Q: PIdleJob;
begin
 P:=@IdleJobs;
 while (P^<>Nil) and (P^^.Control<>nControl) do
  P:=@P^^.Next;
 Q:=P^;
 if Q=Nil then
  Exit;
 P^:=Q^.Next;
 Dispose(Q);
end;

procedure TForm1.StartIdleJob(nEvent: TIdleJobEvent; nControl: TObject);
var
 I: Integer;
 P: PIdleJob;
begin
 if nControl<>Nil then
  AbortIdleJob(nControl);
 I:=nEvent(-1);
 if I>=0 then
  begin
   New(P);
   P^.Counter:=I;
   P^.Event:=nEvent;
   P^.Control:=nControl;
   P^.Next:=IdleJobs;
   P^.Working:=False;
   IdleJobs:=P;
   if nControl is TWinControl then
    TWinControl(nControl).Cursor:=crAppStart;
  end;
end;

{$IFDEF Debug}
procedure TForm1.DataDump1Click;
begin
 DataDump;
end;
{$ENDIF}

procedure TForm1.AppActivate(Sender: TObject);
begin
 if Screen.ActiveForm<>Nil then
  PostMessage(Screen.ActiveForm.Handle, wm_MessageInterne,
   wp_AppActivate, 1);
end;

procedure TForm1.AppDeactivate(Sender: TObject);
begin
 if Screen.ActiveForm<>Nil then
  PostMessage(Screen.ActiveForm.Handle, wm_MessageInterne,
   wp_AppActivate, 0);
end;

{------------------------}

(*function TQrkExplorer.AfficherObjet;
begin
 if {((Parent=Nil) or (Parent is QExplorerGroup))
 and} (Enfant is QFileObject) then
  Result:=ofTvSousElement
 else
  Result:=0;
end;*)

(*function TQrkExplorer.MsgUndo(Op: TMsgUndo; Data: Pointer) : Pointer;
begin
{case Op of
  muOneEnd: if Form1.Fiche<>Nil then
             PostMessage(Form1.Fiche.Handle, wm_MessageInterne, wp_AfficherInfos, 0);
 end;}
 Result:=inherited MsgUndo(Op, Data);
end;*)

(*procedure TQrkExplorer.DoubleClic;
var
 Q: QObject;
 Info: TFileObjectClassInfo;
begin
 Q:=TMSelUnique;
 if (Q<>Nil) and not Form1.ReopensWindow(Q as QFileObject) then
  begin
   (Q as QFileObject).FileObjectClassInfo(Info);
   if Info.CanMaximize in StandAloneWndState then
   {with Form1 do}
     begin
      MAJAffichage(Nil);
      with Q as QFileObject do
       OuvrirMaximum;
     {PostMessage(Handle, wm_MessageInterne, wp_AfficherObjet, 0);}
     end;
  end;
end;*)

(*procedure TQrkExplorer.OpDansScene(Q: QObject; Aj: TAjScene; PosRel: Integer);
var
 F: TQForm1;
begin
 case Aj of
  asModifie: begin
              if (Q=Form1.ElSousFiche) and (Form1.Fiche<>Nil) then
               PostMessage(Form1.Fiche.Handle, wm_MessageInterne, wp_AfficherObjet, 0);
              if Q is QFileObject then
               begin
                F:=QFileObject(Q).FindObjectWindow;
                if F<>Nil then
                 PostMessage(F.Handle, wm_MessageInterne, wp_AfficherObjet, 0);
               end;
              end;
  asRetire: begin
             if Q=Form1.ElSousFiche then
              Form1.MAJAffichage(Nil);
             if Q is QFileObject then
              begin
               F:=QFileObject(Q).FindObjectWindow;
               if F<>Nil then
                F.CloseNow;
              end;
            end;
 end;
 inherited;
end;*)

(*procedure TQrkExplorer.MAJAffichage(Q: QFileObject);
begin
 if (Q<>Nil) and Form1.ReopensWindow(Q) then
  Q:=Nil;  { maximized window reopened, don't show anything right here }
 inherited MAJAffichage(Q);
end;*)

procedure TQrkExplorer.GetExplorerInfo(var Info: TExplorerInfo);
begin
 Info.TargetTag:='.qrk';
end;

function TQrkExplorer.DropObjectsNow(Gr: QExplorerGroup; const Texte: String; Beep: boolean) : Boolean;
begin
 Result:=inherited DropObjectsNow(Gr, Texte, False);
 if not Result then
  begin
   TMSelUnique:=Form1.NeedExplorerRoot;
   Result:=inherited DropObjectsNow(Gr, Texte, Beep);
  end;
end;

procedure TQrkExplorer.ReplaceRoot(Old, New: QObject);
begin
 inherited;
 UpdateForm1Root;
end;

 {------------------------}

(*procedure TForm1.Timer1Timer(Sender: TObject);
begin
 MAJAffichage(Explorer.TMSelUnique as QFileObject);
end;*)

procedure TForm1.Close1Click(Sender: TObject);
begin
 ValidParentForm(FileMenu.PopupComponent as TControl).Close;
end;

procedure TForm1.Edit1Click(Sender: TObject);
var
 Form: TQkForm;
 Flags: Integer;
 Q: QObject;
 R: PUndoRoot;
 PasteObjOk, PasteObjReady: Boolean;
begin
 Form:=ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm;
 Q:=HasGotObject(Form.ProcessEditMsg(edGetRoot), True);
 if Q=Nil then
  R:=Nil
 else
  R:=GetUndoRoot(Q);
 Undo1.Enabled:=(R<>Nil) and (R^.Undone < R^.UndoList.Count);
 if Undo1.Enabled then
  Undo1.Caption:=FmtLoadStr1(44, [TUndoObject(R^.UndoList[R^.UndoList.Count-1-R^.Undone]).Text])
 else
  Undo1.Caption:=FmtLoadStr1(44, ['']);
 Redo1.Visible:=(R<>Nil) and (R^.Undone > 0);
 if Redo1.Visible then
  Redo1.Caption:=FmtLoadStr1(45, [TUndoObject(R^.UndoList[R^.UndoList.Count-R^.Undone]).Text]);

 Flags:=Form.ProcessEditMsg(edEdEnable);
 PasteObjReady:=ClipboardChain(Nil);
 PasteObjOk:=(Flags and edPasteObj = edPasteObj)
  and PasteObjReady;

 Cut1.Enabled    := Flags and edCut      = edCut;
 Copy1.Enabled   := Flags and edCopy     = edCopy;
 Paste1.Enabled  :=(Flags and edPasteTxt = edPasteTxt) or PasteObjOk;
 PasteObj1.Enabled := PasteObjReady;
 Delete1.Enabled := Flags and edDelete   = edDelete;

 Flags:=Form.ProcessEditMsg(edObjEnable);
 OpenSel1.Enabled:= Flags and edOpen   = edOpen;

 MenuCopyAs;
end;

procedure TForm1.EditMacroClick(Sender: TObject);
begin
 with ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm do
  MacroCommand((Sender as TMenuItem).Tag);
end;

procedure TForm1.wmMessageInterne(var Msg: TMessage);
begin
 if (Explorer<>Nil) and not Explorer.ProcessMessage(Self, Msg) then
  case Msg.wParam of
   wp_AfficherInfos:
     if Explorer.Roots.Count>0 then
      with Explorer.Roots[0] do
       begin
        Caption:=Name;
        RedrawWindow(Handle, Nil, 0, rdw_Invalidate or rdw_Frame);
       {if Flags and ofTvNode <> 0 then
         GetNode.Text:=Name;}
        Explorer.Invalidate; 
       end;
   wp_SetupChanged:
     ReadSetupInformation(Msg.lParam);
   wp_FileMenu:
     Save(Msg.lParam);
  {wp_Warning:
     GlobalDisplayWarnings;}
   wp_EditMsg:
     if Msg.lParam=edGetRoot then
      Msg.Result:=GetObjectsResult(Explorer.Roots);
  {wp_UpdateInternals:
     if Msg.lParam=ui_Logo then
      begin
       Image1.Free;
       Image1:=Nil;
       Timer1.Free;
       Timer1:=Nil;
       StatusBar1.Free;
       StatusBar1:=Nil;
       Explorer.Visible:=True;
      end;}
   wp_ProcessNotifyFirst..wp_ProcessNotifyLast:
     ProcessNotify(Msg.wParam, Msg.lParam);
  else
   inherited;
  end;
end;

(*function TForm1.ReopensWindow;
var
 F: TQForm1;
begin
 F:=Q.FindObjectWindow;
 if F<>Nil then
  begin
   Explorer.MAJAffichage(Nil);
   ActivateNow(F);
   MarsCaption1.ActiveEndColor:=clNavy;
   ReopensWindow:=True;
  end
 else
  ReopensWindow:=False;
end;*)

(*procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
 I: Integer;
 F: TForm;
begin
 Explorer.MAJAffichage(Nil);
 for I:=0 to Screen.FormCount-1 do
  begin
   F:=Screen.Forms[I];
   if (F<>Self) and Assigned(F.OnCloseQuery) then
    begin
     F.OnCloseQuery(Self, CanClose);
     if not CanClose then
      Exit;
    end;
  end;
 ClearExplorer;
end;*)

procedure TForm1.File1Click(Sender: TObject);
var
 Info: TFileObjectClassInfo;
 FileObject: QFileObject;
 F: TCustomForm;
 MF, QF1: Boolean;
 Tree: TQkExplorer2;
 Q: QObject;
 L: TStringList;
 I: Integer;
begin
 F:=ValidParentForm(FileMenu.PopupComponent as TControl);
 QF1:=F is TQForm1;
 Tree:=Nil;
 MF:=True;
 if F is TQFormExplorer then
  begin
   if TQFormExplorer(F).FileObject<>Nil then
    Tree:=TQFormExplorer(F).Explorer;
  end
 else
  if F=Self then
   begin
    if Explorer.Roots.Count>0 then
     Tree:=Explorer;
   end
  else
   MF:=False;
 Saveinnewentry1.Visible:=QF1;
 SSep1.Visible:=MF;
 Saveall1.Visible:=MF;
 Saveentryasfile1.Visible:=MF;
{Makefilelink1.Visible:=F=Self;}
 if MF then
  begin
  {Saveall1.Enabled:=Tree<>Nil;}
  {Saveentryasfile1.Enabled:=(Tree<>Nil) and (Tree.ElSousFiche<>Nil) and (Tree.ElSousFiche.TvParent<>Nil);}
   Q:=HasGotObject((F as TQkForm).ProcessEditMsg(edGetObject), False);
   Saveentryasfile1.Enabled:=(Q<>Nil) and (Q is QFileObject);
  end;
 Save1.Enabled:=QF1 or (Tree<>Nil);
 Saveasfile1.Enabled:=QF1 or (Tree<>Nil);
 if QF1 then
  FileObject:=TQForm1(F).FileObject
 else
  FileObject:=Nil;
 if FileObject<>Nil then
  FileObject.FileObjectClassInfo(Info)
 else
  Info.NomClasseEnClair:=LoadStr1(5125);
 News1.Caption:=FmtLoadStr1(2, [Info.NomClasseEnClair]);
 if FileMenu.Tag=0 then
  begin
   L:=TStringList.Create; try
   L.Text:=SetupSet[ssGeneral].Specifics.Values['RecentFiles'];
   FileSep1.Visible:=L.Count>0;
   for I:=0 to MaxRecentFiles-1 do
    with FileMenu.Items[FileSep1.MenuIndex+I+1] do
     begin
      Visible:=I<L.Count;
      if I<L.Count then
       Caption:=FmtLoadStr1(3, [I+1, ExtractFileName(L[I])]);
     end;
   finally L.Free; end;
   FileMenu.Tag:=1;
  end;
end;

procedure TForm1.WindowMenuPopup(Sender: TObject);
var
 I, Total: Integer;
 Obj: TComponent;
 Item: TMenuItem;
 Active: TForm;
 LookFor: String;
 SetupQrk: QFileObject;
begin
 for I:=WinList1.MenuIndex-1 downto MainWindow1.MenuIndex+1 do
  WindowMenu.Items[I].Free;
 Active:=Screen.{ActiveForm;}Forms[0];
(*if TbMenuChar<>CharModeJeu then
  begin
   SetupQrk:=MakeAddOnsList; try
   TbMenuChar:=CharModeJeu;
   DefaultTbCount:=0;
    { looks for ToolBox infos in all add-ons }
   DefaultTbCount:=LoadToolBoxInformation(SetupQrk);
   finally SetupQrk.AddRef(-1); end;
  end;
 Total:=DefaultTbCount;
 if Explorer.Roots.Count>0 then
  Inc(Total, LoadToolBoxInformation(Explorer.Roots[0]));*)

 SetupQrk:=MakeAddOnsList; try
 Total:=LoadToolBoxList(SetupQrk);
 finally SetupQrk.AddRef(-1); end;

 if {(Active<>Nil) and} (Active is TToolBoxForm) then
  LookFor:=Active.Caption
 else
  LookFor:='';
 for I:=0 to Total-1 do
  with WindowMenu.Items[I] do
   Checked:=CompareText(Caption, LookFor) = 0;
 MainWindow1.Checked:=Active=Self;
 for I:=0 to Application.ComponentCount-1 do
  begin
   Obj:=Application.Components[I];
   if (Obj is TQForm1) and TQForm1(Obj).Visible then
    begin
     Item:=TMenuItem.Create(Self);
     Item.Caption:=TQForm1(Obj).Caption;
     Item.Tag:=LongInt(Obj);
     Item.OnClick:=MainWindow1Click;
     Item.RadioItem:=True;
     Item.Checked:=Active=Obj;
     WindowMenu.Items.Insert(WinList1.MenuIndex, Item);
    end;
  end;
{Minimize1.Enabled:=Active.BorderStyle<>bsSizeToolWin;}
end;

procedure TForm1.MainWindow1Click(Sender: TObject);
var
 Obj: TQForm1;
begin
 Obj:=TQForm1((Sender as TMenuItem).Tag);
 if Obj=Nil then
  ActivateNow(Self)   { main window }
 else
  ActivateNow(Obj);   { a "TQForm1" window }
end;

procedure TForm1.Minimize1Click(Sender: TObject);
var
 F: TCustomForm;
begin
 F:=ValidParentForm(WindowMenu.PopupComponent as TControl);
 DefWindowProc(F.Handle, wm_SysCommand, sc_Minimize, 0);
{if F is TQForm1 then
  TQForm1(F).MarsCaption1.ApplicationName:=''
 else
  if F is TToolBoxForm then
   TToolBoxForm(F).MarsCaption1.ApplicationName:=''}
end;

procedure TForm1.EditMenuItemClick(Sender: TObject);
begin
 with ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm do
  ProcessEditMsg((Sender as TMenuItem).Tag);
end;

function TForm1.WindowHook(var Msg: TMessage) : Boolean;
var
 Form: TForm;
{SaveFocus: HWnd;}
begin
 Result:=False;
 case Msg.Msg of
  CM_APPKEYDOWN:
    begin
     Form:=Screen.ActiveForm;
     if (Form<>Nil) and (Form is TQkForm) then
      if TQkForm(Form).MenuShortcut(TWMKeyDown(Msg))
      or ((Form.Owner is TQkForm)
       and (TQkForm(Form.Owner).MenuShortcut(TWMKeyDown(Msg)))) then
       begin
        Msg.Result:=1;
        Result:=True;
       end;
    end;
  CM_APPSYSCOMMAND:
    begin
   (*Form:=Screen.ActiveForm;
     if (Form<>Nil) and (Form.Owner is TForm) then
      with TForm(Form.Owner) do
       begin
        SaveFocus := GetFocus;
        Windows.SetFocus(Handle);
        Perform(WM_SYSCOMMAND, Msg.wParam, Msg.lParam);
        Windows.SetFocus(SaveFocus);
       end;*)
     Result:=True;
    end;
 end;
end;

procedure TForm1.ReadSetupInformation;
begin
 FileMenu.Tag:=0;
 if Level>=scToolbars then
  begin
   SavePositionTb('Main', False, Explorer);
   RestorePositionTb('Main', False, Explorer);
  end
 else
  if Level>=scNormal then
   UpdateToolbarSetup;
end;

(*procedure TForm1.ReadSetupInformation;
{var
 SetupQrk: QFileObject;}
begin
 TbMenuChar:=#0;

(* SetupQrk:=MakeAddOnsList; try
  { looks for ToolBox infos in all add-ons }
 DefaultTbCount:=LoadToolBoxInformation(SetupQrk);
 finally SetupQrk.AddRef(-1); end; * )
end;                                *)

(*function TForm1.LoadToolBoxInformation(SetupQrk: QObject) : Integer;
var
 Roots: TQList;
 I, J: Integer;
 L: TStringList;
 ToolBox: QToolBox;
 S: String;
 Item: TMenuItem;
begin
{if DefaultTbCount<0 then DefaultTbCount:=0;}
 for I:=TbList1.MenuIndex-1 downto DefaultTbCount do
  WindowMenu.Items[I].Free;
 Roots:=TQList.Create; try
 BrowseToolBoxes(SetupQrk, '', Roots);
 L:=TStringList.Create; try
 L.Sorted:=True;
 Result:=-1;
 for I:=0 to Roots.Count-1 do
  begin
   ToolBox:=Roots[I] as QToolBox;
   S:=ToolBox.Specifics.Values['ToolBox'];
   if (S<>'') and not L.Find(S, J) then
    begin
     Item:=TMenuItem.Create(Self);
     Item.Caption:=S;
     Item.RadioItem:=True;
     Item.OnClick:=ToolBoxClick;
     WindowMenu.Items.Insert(DefaultTbCount+L.Count, Item);
     L.Add(S);
    end;
  end;
 Result:=L.Count;
 finally L.Free; end;
 finally Roots.Free; end;
end;*)

function TForm1.LoadToolBoxList(SetupQrk: QObject) : Integer;
var
 Roots: TQList;
 I, J: Integer;
 L: TStringList;
 ToolBox: QToolBox;
 S: String;
 Item: TMenuItem;
begin
 Roots:=TQList.Create; try
 BrowseToolBoxes(SetupQrk, '', Roots);
 L:=TStringList.Create; try
 L.Sorted:=True;
 Result:=TbList1.MenuIndex;
 for I:=0 to Roots.Count-1 do
  begin
   ToolBox:=Roots[I] as QToolBox;
   S:=ToolBox.Specifics.Values['ToolBox'];
   if (S<>'') and not L.Find(S,J) then
    begin
     if L.Count<Result then
      Item:=WindowMenu.Items[L.Count]
     else
      begin
       Item:=TMenuItem.Create(Self);
       Item.RadioItem:=True;
       Item.OnClick:=ToolBoxClick;
       WindowMenu.Items.Insert(Result, Item);
       Inc(Result);
      end;
     Item.Caption:=S;
     L.Add(S);
    end;
  end;
 while Result>L.Count do
  begin
   Dec(Result);
   WindowMenu.Items[Result].Free;
  end;
 finally L.Free; end;
 finally Roots.Free; end;
end;

procedure TForm1.ToolBoxClick(Sender: TObject);
begin
 ShowToolBox((Sender as TMenuItem).Caption);
end;

procedure TForm1.News1Click(Sender: TObject);
var
 Info: TFileObjectClassInfo;
 FileObject: QFileObject;
 NewClass, NewObj: String;
 F: TCustomForm;
 Gr, Gr1: QExplorerGroup;
begin
 Info.NomClasseEnClair:=LoadStr1(5125);
 NewClass:='.qrk';
 NewObj:='';
 Gr:=Nil; try
 F:=ValidParentForm(FileMenu.PopupComponent as TControl);
 if F is TQForm1 then
  begin
   FileObject:=TQForm1(F).FileObject;
   if FileObject<>Nil then
    begin
     FileObject.FileObjectClassInfo(Info);
     NewClass:=FileObject.TypeInfo;
     FileObject:=Nil;
    end;
   if (TQForm1(F).WndState=cmOwnExplorer) = (wiOwnExplorer in Info.WndInfo) then
    TQForm1(F).CloseNow;  { will be reused immediately }

   NewObj:=TQForm1(F).GetSpecTbExtra('New');
   if NewObj<>'' then
    begin
     Gr1:=QExplorerGroup.Create('', Nil); try
     if DoIncludeData(Gr1, Nil, NewObj) then
      begin
       Gr:=CopyToOutside(Gr1);
       if Gr.SousElements.Count>0 then
        begin
         FileObject:=Gr.SousElements[0] as QFileObject;
         FileObject.ReadFormat:=rf_Default;
         FileObject.Flags:=(FileObject.Flags or ofFileLink) and not ofModified;
        end;
      end;
     finally Gr1.Free; end;
    end;
  end
 else
  FileObject:=Nil;
 if FileObject=Nil then
  FileObject:=BuildFileRoot(
   FmtLoadStr1(5128, [Info.NomClasseEnClair]) + NewClass, Nil);
 FileObject.NomFichier:='';
 FileObject.OpenStandAloneWindow(Nil, False);
 finally Gr.Free; end;
end;

procedure TForm1.Open1Click(Sender: TObject);
var
 OpenDialog1: TOpenDialog;
 Info: TFileObjectClassInfo;
 FileObject: QFileObject;
 F: TCustomForm;
 L: TStringList;
 I, Code: Integer;
 S: String;
begin
 OpenDialog1:=TOpenDialog.Create(Self); try
 OpenDialog1.Title:=LoadStr1(771);
 L:=TStringList.Create; try
 BuildFileExt(L);
 S:=L[0];
 for I:=1 to L.Count-1 do
  S:=S+'|'+L[I];
 OpenDialog1.Filter:=S;
 Code:=772;
{Info.FileExtCount:=0;}
 F:=ValidParentForm(FileMenu.PopupComponent as TControl);
 if F is TQForm1 then
  begin
   FileObject:=TQForm1(F).FileObject;
   if FileObject<>Nil then
    begin
     FileObject.FileObjectClassInfo(Info);
     OpenDialog1.DefaultExt:=Info.DefaultExt;
     if Info.FileExt{Count}>0 then
      Code:=Info.FileExt{[0]};
    end;
  end;
{if Info.FileExtCount>0 then
  OpenDialog1.DefaultExt:=Info.DefaultExt[0];}
 if Code<>772 then
  OpenFilterIndex:=L.IndexOf(LoadStr1(Code))+1;
 OpenDialog1.FilterIndex:=OpenFilterIndex;
 finally L.Free; end;
 OpenDialog1.Options:=[ofAllowMultiSelect, ofFileMustExist];
 if OpenDialog1.Execute then
  begin
   if (F is TQForm1) and (OpenDialog1.FilterIndex=OpenFilterIndex) then
    TQForm1(F).CloseNow;  { it will be opened in the same window }
   for I:=0 to OpenDialog1.Files.Count-1 do
    OpenAFile(OpenDialog1.Files[I], ofReadOnly in OpenDialog1.Options);
   OpenFilterIndex:=OpenDialog1.FilterIndex;
  end;
 finally OpenDialog1.Free; end;
end;

procedure TForm1.OpenAFile(const FileName: String; ReadOnly: Boolean);
var
 L: TStringList;
 FileObject: QFileObject;
 S: String;
begin
 if CompareText(ExtractFileExt(FileName), '.py') = 0 then
  begin
   L:=TStringList.Create; try
   L.LoadFromFile(FileName);
   S:=TrimStringList(L, $0A);
   finally L.Free; end;
   PyRun_SimpleString(PChar(S));
   PythonCodeEnd;
   Exit;
  end;

 FileObject:=LienFichierExact(FileName, Nil, True) as QFileObject;
 if ReadOnly then
  FileObject.Flags:=FileObject.Flags or ofWarnBeforeChange;
 FileObject.OpenStandAloneWindow(Nil, False);
 AddToRecentFiles(FileName);
end;

procedure TForm1.Save1Click(Sender: TObject);
var
 F: TCustomForm;
begin
 F:=ValidParentForm(FileMenu.PopupComponent as TControl);
 PostMessage(F.Handle, wm_MessageInterne, wp_FileMenu,
  (Sender as TMenuItem).Tag);
end;

procedure TForm1.Save(AskName: Integer);
var
 Dup: QFileObject;
begin
 if Explorer.Roots.Count=0 then Exit;
 if AskName=fm_SaveTagOnly then
  begin
   SaveTag(Explorer.Roots[0]);
   Exit;
  end;
 Dup:=SaveObject(Explorer.Roots[0] as QFileObject, AskName, 0, Self);
 if Dup<>Nil then
  Dup.AddRef(-1);
 Perform(wm_MessageInterne, wp_AfficherInfos, 0);
end;

(*function TForm1.GetGlobalModified : Boolean;
var
 I: Integer;
 F: TForm;
begin
 Result:=True;
 if FModified then Exit;
 for I:=0 to Screen.FormCount-1 do
  begin
   F:=Screen.Forms[I];
   if (F is TQForm1) and TQForm1(F).Modified
   and (TQForm1(F).CurrentlySaved=cs_Explorer) then
    Exit;
  end;
 Result:=False;
end;

procedure TForm1.SetGlobalModified(Value: Boolean);
var
 I: Integer;
 F: TForm;
begin
 FModified:=Value;
 if Value then Exit;
 for I:=0 to Screen.FormCount-1 do
  begin
   F:=Screen.Forms[I];
   if (F is TQForm1) and (TQForm1(F).CurrentlySaved=cs_Explorer) then
    TQForm1(F).Modified:=False;
  end;
end;*)

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
 I: Integer;
 F: TForm;
 CloseAction: TCloseAction;
begin
 if LargeDataInClipboard
 and (MessageDlg(LoadStr1(5681), mtConfirmation, [mbYes, mbNo], 0) = mrNo) then
  begin
   OpenClipboard(0);
   EmptyClipboard;
   CloseClipboard;
  end;

 SavePendingFiles(True);
 I:=Screen.FormCount;
 while I>0 do
  begin
   Dec(I);
   F:=Screen.Forms[I];
   if (F<>Self) and F.Visible then
    begin
     if not F.CloseQuery then Abort;
     if Assigned(F.OnClose) then
      begin
       CloseAction:=caHide;
       F.OnClose(Self, CloseAction);
       case CloseAction of
        caHide: F.Hide;
        caFree: F.Free;
       else Abort;
       end;
       I:=Screen.FormCount;  { browse list again - OnClose might have messed up the list of opened forms }
      end;
    end;
  end;
 ClearExplorer;
 SavePendingFiles(True);
 SavePositionTb('Main', False, Explorer);
 if not FNoTempDelete then
  DeleteTempFiles;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin  { the link to FormDestroy is made in FormCreate }
 try
  SaveSetupNow;
 except
  on E: Exception do
   MessageBox(0, PChar(FmtLoadStr1(5658, [GetExceptionMessage(E)])), PChar(LoadStr1(5657)), MB_OK or MB_ICONHAND or MB_TASKMODAL);
 end;
 ClearGameBuffers(False);
 ClearPool(True);
end;

procedure TForm1.Saveentryasfile1Click(Sender: TObject);
var
 Q: QObject;
begin
 with ValidParentForm(FileMenu.PopupComponent as TControl) as TQkForm do
  Q:=HasGotObject(ProcessEditMsg(edGetObject), False);
 if (Q<>Nil) and (Q is QFileObject) then
  begin
   Q:=SaveObject(QFileObject(Q), fm_SaveAsFile, 0, Nil);
   if Q<>Nil then
    Q.AddRef(-1);
  end;
end;
(*var
 F: TForm;
 Tree: TFileExplorer;
 Q: QFileObject;
begin
 F:=ValidParentForm(FileMenu.PopupComponent as TControl);
 if F is TQFormExplorer then
  begin
   if TQFormExplorer(F).FileObject=Nil then Exit;
   Tree:=TQFormExplorer(F).Explorer;
  end
 else
  if F=Self then
   begin
    if Explorer.Roots.Count=0 then Exit;
    Tree:=Explorer;
   end
  else
   Exit;
 Q:=Tree.ElSousFiche;
 if (Q<>Nil) and (Q.TvParent<>Nil) then
  begin
   Q:=SaveObject(Q, fm_SaveAsFile, False, Nil);
   if Q<>Nil then
    Q.AddRef(-1);
  end;
end;*)

procedure TForm1.Saveall1Click(Sender: TObject);
var
 I: Integer;
 F: TForm;
begin
 for I:=0 to Screen.FormCount-1 do
  begin
   F:=Screen.Forms[I];
   if F.Visible then
    F.Perform(wm_MessageInterne, wp_FileMenu, fm_SaveIfModif);
  end;
 SavePendingFiles(False);
end;

procedure TForm1.LibererMemoireFiches;
var
 I: Integer;
 F: TForm;
begin
 for I:=0 to Screen.FormCount-1 do
  begin
   F:=Screen.Forms[I];
   if (F<>Self) and not F.Visible then
    F.Release;
  end;
end;

procedure TForm1.LibererMaxMemoire;
begin
 LibererMemoireTextures;
 LibererMemoireFiches(Nil);
 DestroyGameBuffers;
end;

procedure TForm1.SavePendingFiles(CanCancel: Boolean);
const
 Buttons: array[Boolean] of TMsgDlgButtons =
  ([mbYes, mbNo], mbYesNoCancel);
var
 L: TQList;
 S, S1: String;
 I: Integer;
begin
 L:=TQList.Create; try
 GetListOfModified(L);
 if L.Count>0 then
  begin
   S:=LoadStr1(5550);
   for I:=0 to L.Count-1 do
    begin
     S1:=(L[I] as QFileObject).NomFichier;
     if S1='' then
      S1:=LoadStr1(5552);
     S:=S+FmtLoadStr1(5551, [S1]);
    end;
   case MessageDlg(S, mtConfirmation, Buttons[CanCancel], 0) of
    mrYes:
      for I:=0 to L.Count-1 do
       QFileObject(L[I]).TrySavingNow;
    mrNo:
      for I:=0 to L.Count-1 do
       with L[I] do
        Flags:=Flags and not ofModified;
   else Abort;
   end;
  end;
 finally L.Free; end;
end;

procedure TForm1.Saveinnewentry1Click(Sender: TObject);
var
 ParentForm: TCustomForm;
 F: TQForm1;
 Gr: QExplorerGroup;
 Reopen: HWnd;
 Dest: QObject;
 Source: QFileObject;
begin
 ParentForm:=ValidParentForm(FileMenu.PopupComponent as TControl);
 if not (ParentForm is TQForm1) then Exit;
 F:=TQForm1(ParentForm);
 if F.FileObject=Nil then Exit;
 F.CheckUniqueWindow;

  { detaches the file object from its old parent }
 if F.AttachPanel<>Nil then
  F.Detach(Nil);

  { we must clear the custom explorer *before* we add the object }
 Reopen:=0;
 Dest:=Nil;
 try
  if (F is TQFormExplorer) and (TQFormExplorer(F).Explorer<>Nil) then
   with TQFormExplorer(F).Explorer do
    begin
     Reopen:=F.Handle;
     MAJAffichage(Nil);
     ClearView;
    end;

  CloseUndoRoot(F.FileObject);

   { adds it in the QuArK Explorer }
  Gr:=QExplorerGroup.Create('(temp)', Nil);
  Gr.AddRef(+1); try
  F.FileObject.Flags:=F.FileObject.Flags and not ofFileLink;
  Gr.SousElements.Add(F.FileObject);
  Source:=F.TmpSwapFileObject(Nil); try
  if not Explorer.DropObjectsNow(Gr, LoadStr1(593), False) then
   Raise EError(5526);   { failed }
  finally F.TmpSwapFileObject(Source); end;
  Dest:=Explorer.TMSelUnique;
  Explorer.TMSelUnique:=Nil;
  F.Attach(Panel2);
 {SendMessage(F.Handle, wm_MessageInterne, wp_SetModify, 0);}
  F.CloseNow;  { closes so that the user sees the new relationship }
  finally Gr.AddRef(-1); end;

 except
  if Reopen<>0 then
   PostMessage(Reopen, wm_MessageInterne, wp_AfficherObjet, 0);
  Raise;
 end;

 Explorer.TMSelUnique:=Dest;
end;

procedure TForm1.MenuCopyAs;
var
 QL: TList;
 Q: QObject;
 L: TStringList;
 Info: TFileObjectClassInfo;
 ConvertClass: QFileObjectClass;
 I, J: Integer;
 Chk: String;
begin
 with ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm do
  QL:=HasGotObjects(ProcessEditMsg(edGetObject));
 try
  if QL.Count=1 then
   Q:=QL[0]
  else
   Q:=Nil;
  ExtEdit1.Enabled:=GetExternalEditorClass(Q)<>Nil;
  Properties1.Enabled:=QL.Count>0;
  L:=TStringList.Create; try
  Chk:='';
  for J:=0 to QL.Count-1 do
   begin
    Q:=QL[J];
    if Q is QFileObject then
     begin
      I:=1;
      repeat
       ConvertClass:=QFileObject(Q).TestConversionType(I);
       if ConvertClass=Nil then Break;
       ConvertClass.FileObjectClassInfo(Info);
       if L.IndexOf(Info.NomClasseEnClair)<0 then
        L.Add(Info.NomClasseEnClair);
       if (ConvertClass=Q.ClassType) and (Chk<>Info.NomClasseEnClair) then
        if Chk='' then
         Chk:=Info.NomClasseEnClair
        else
         Chk:='!';
       Inc(I);
      until False;
     end;
   end;
  Copyas1.Enabled:=L.Count>0;
  if L.Count=0 then
   Exit;
  while Copyas1.Count>L.Count do
   Copyas1.Delete(Copyas1.Count-1);
  for I:=Copyas1.Count to L.Count-1 do
   Copyas1.Add(TMenuItem.Create(Self));
  for I:=0 to L.Count-1 do
   with Copyas1.Items[I] do
    begin
     Caption:=L[I];
     Default:=Caption=Chk;
     OnClick:=CopyAsClick;
    end;
  finally L.Free; end;
 finally
  QL.Free;
 end;
end;

procedure TForm1.CopyAsClick(Sender: TObject);
var
 List: TList;
 Q: QObject;
 S: String;
 Info: TFileObjectClassInfo;
 ConvertClass: QFileObjectClass;
 I, J: Integer;
 Dup: QFileObject;
 Gr: QExplorerGroup;
begin
 S:=(Sender as TMenuItem).Caption;
 with ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm do
  List:=HasGotObjects(ProcessEditMsg(edGetObject));
 Gr:=ClipboardGroup;
 Gr.AddRef(+1);
 try
  for J:=0 to List.Count-1 do
   begin
    Q:=List[J];
    if Q is QFileObject then
     begin
      I:=1;
      repeat
       ConvertClass:=QFileObject(Q).TestConversionType(I);
       if ConvertClass=Nil then
        begin
         MessageBeep(0);  { error }
         Break;
        end;
       ConvertClass.FileObjectClassInfo(Info);
       if S=Info.NomClasseEnClair then
        begin
         Dup:=ConvertClass.Create(Q.Name, Nil);
         Dup.AddRef(+1); try
         if Dup.ConversionFrom(QFileObject(Q)) then
          begin
           Gr.SousElements.Add(Dup);
           Break;   { ok }
          end;
         finally Dup.AddRef(-1); end;
        end;
       Inc(I);
      until False;
     end
    else
     MessageBeep(0);  { error }
   end;
  if Gr.SousElements.Count>0 then
   Gr.CopierObjets(False);
 finally
  Gr.AddRef(-1);
  List.Free;
 end;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
 OnActivate:=Nil;
 DragAcceptFiles(Handle, True);
 if PyDict_GetItemString(QuarkxDict, 'setupchanged')<>Py_None then
  StartIdleJob(ProcessCmdLine, Self);
end;

function TForm1.ProcessCmdLine(Counter: Integer) : Integer;
begin
 Inc(Counter);
 if Counter>ParamCount then
  begin
   RefreshAssociations(False);
   RestoreAutoSaved('.qkm');
   Counter:=-1;
  end
 else
  if Counter>0 then
   OpenAFile(ParamStr(Counter), False);
 Result:=Counter;
end;

procedure TForm1.wmDropFiles(var Msg: TMessage);
var
 I: Integer;
 Z: array[0..MAX_PATH] of Char;
begin
 try
  for I:=0 to DragQueryFile(Msg.wParam, DWORD(-1), Nil, 0) - 1 do
   if DragQueryFile(Msg.wParam, I, Z, SizeOf(Z))>0 then
    OpenAFile(StrPas(Z), False);
 finally
  DragFinish(Msg.wParam);
 end;
end;

procedure TForm1.wmCompacting(var Msg: TMessage);
begin
 LibererMaxMemoire;
end;

procedure TForm1.wmRenderFormat(var Msg: TMessage);
var
 Gr: QExplorerGroup;
begin
 Gr:=DelayedClipboardGroup;
 if Gr<>Nil then
  begin
   Gr.AddRef(+1); try
   Gr.RenderAsText;
   finally Gr.AddRef(-1); end;
  end;
end;

procedure TForm1.wmRenderAllFormats(var Msg: TMessage);
var
 Gr: QExplorerGroup;
begin
 Gr:=DelayedClipboardGroup;
 if Gr<>Nil then
  begin
   Gr.AddRef(+1); try
   Gr.CopierObjets(True);
   finally Gr.AddRef(-1); end;
  end;
end;

procedure TForm1.wmDestroyClipboard(var Msg: TMessage);
begin
 DelayedClipboardGroup.AddRef(-1);
 DelayedClipboardGroup:=Nil;
 LargeDataInClipboard:=False;
end;

procedure TForm1.RecentFileClick(Sender: TObject);
var
 L: TStringList;
 I: Integer;
 FileName: String;
begin
 I:=(Sender as TMenuItem).MenuIndex - FileSep1.MenuIndex - 1;
 L:=TStringList.Create; try
 L.Text:=SetupSet[ssGeneral].Specifics.Values['RecentFiles'];
 FileName:=L[I];
 finally L.Free; end;

 OpenAFile(FileName, False);
end;

procedure TForm1.GameSwitch1Click(Sender: TObject);
begin
 ChangeGameMode(Chr((Sender as TMenuItem).Tag), False);
end;

procedure TForm1.Games1Click(Sender: TObject);
var
 I: Integer;
 C: Char;
begin
 C:=CharModeJeu;
 for I:=0 to GameSep1.MenuIndex-1 do
  with GamesMenu.Items[I] do
   Checked:=Chr(Tag)=C;
 Go1.Enabled:=Explorer.Roots.Count>0;  
end;

procedure TForm1.Go1Click(Sender: TObject);
begin
 NeedExplorerRoot.GO((Sender as TMenuItem).Tag);
end;

procedure TForm1.AppException(Sender: TObject; E: Exception);
begin
 MessageException(E, '%s', [mbOk]);
end;

function TForm1.MessageException(E: Exception; const Info: String; Buttons: TMsgDlgButtons) : TModalResult;
var
 B: TButton;
{P: Integer;}
 S: String;
begin
(*if E.HelpContext=0 then
  Application.ShowException(E)
 else
  begin
   MessageBeep(MB_ICONSTOP);
   MessageDlg(E.Message+'.', mtError, [mbOk, mbHelp], E.HelpContext);
  end;*)
 if E is EAbort then
  begin
   Result:=mrNone;
   Exit;   { silent exception }
  end; 
 MessageBeep(MB_ICONSTOP);
 Include(Buttons, mbIgnore);
 if E.HelpContext<>0 then Include(Buttons, mbHelp);
 S:=Format(Info, [GetExceptionMessage(E)]);
{P:=Pos('//', S);
 if P=0 then
  P:=Length(S)+1;}
 with CreateMessageDialog({Copy(}S{,1,P-1)}, mtError, Buttons) do
  try
   HelpContext := E.HelpContext;
   B:=FindComponent('Ignore') as TButton;
   with B do
    begin
     Caption:=LoadStr1(4614);
     Hint:=E.Message;
     ModalResult:=mrNone;
     OnClick:=AppExceptionMore;
    end;
  {if P<Length(E.Message) then
    ActiveControl:=B;}
   Result:=ShowModal;
  finally
   Free;
  end;
end;

procedure TForm1.AppExceptionMore(Sender: TObject);
const
 DlgW  = 372;
 MemoH = 160;
var
{E: Exception;}
 Msg: String;
 Dlg: TCustomForm;
 P: Integer;
 L: TStringList;
 Delta: Integer;
begin
 with Sender as TButton do
  begin
   Enabled:=False;
  {LongInt(Pointer(E)):=Tag;}
   Msg:=Hint;
  end;
 L:=TStringList.Create; try
 L.Add(FmtLoadStr1(4616, [QuarkVersion, ExceptAddr, @TForm1.AppException]));
 P:=Pos('//', Msg);
 if P=0 then
  L.Add(Msg+'.')
 else
  begin
   L.Add(Copy(Msg, 1, P-1)+'.');
   L.Add('');
   L.Add(Copy(Msg, P+2, MaxInt));
  end;
 L.Add(LoadStr1(4617));
 Dlg:=GetParentForm(TControl(Sender));
 Delta:=DlgW - Dlg.Width;
 if Delta<0 then Delta:=0;
 with TMemo.Create(Dlg) do
  begin
   SetBounds(10, Dlg.ClientHeight, Dlg.ClientWidth+Delta-20, MemoH-10);
   Parent:=Dlg;
   Lines.Text:={$IFDEF Debug}'!! DEBUG !!'+{$ENDIF}L.Text;
   ScrollBars:=ssVertical;
   ReadOnly:=True;
   WantReturns:=False;
   SetFocus;
  end;
 Dlg.SetBounds(Dlg.Left - Delta div 2, Dlg.Top, Dlg.Width + Delta, Dlg.Height + MemoH);
 finally L.Free; end;
end;

procedure TForm1.PasteObj1Click(Sender: TObject);
var
 Gr: QExplorerGroup;
{I: Integer;}
begin
 Gr:=ClipboardGroup;
 Gr.AddRef(+1); try
 if ClipboardChain(Gr) then
 {if (Gr.SousElements.Count<=1)
  or (MessageDlg(FmtLoadStr1(5562, [Gr.SousElements.Count]),
   mtWarning, [mbYes, mbNo], 0) = mrYes) then
    for I:=0 to Gr.SousElements.Count-1 do
     ObjectProperties(Gr.SousElements[I],
      ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm);}
  if Gr.SousElements.Count>0 then
   ObjectProperties(Gr.SousElements,
    ValidParentForm(EditMenu.PopupComponent as TControl) as TQkForm);
 finally Gr.AddRef(-1); end;
end;

procedure TForm1.Options2Click(Sender: TObject);
begin
 ShowConfigDlg('Games:'+SetupGameSet.Name);
end;

(*procedure TForm1.wmCommand(var Msg: TMessage);
begin
 if (Msg.wParam>=cmObjFirst) and (Msg.wParam<=cmObjLast) then
  PopupMenuObject.CallMenuCmd(Msg.wParam)
 else
  inherited;
end;*)

procedure TForm1.AppShowHint(var HintStr: string; var CanShow: Boolean; var HintInfo: THintInfo);
var
 I, Code: Integer;
begin
 Application.HintHidePause:=4000;
 if HintStr<>'' then
  begin
  {if (Form4<>Nil) and (ModeEcran3D<>0) and Form3D.DessinEnCours then
    begin
     CanShow:=False;
     Exit;
    end;}
   if HintInfo.HintControl is TPyMapView then
    begin
     TPyMapView(HintInfo.HintControl).MapShowHint(HintStr, CanShow, HintInfo);
     if HintStr='' then Exit;
     I:=0;
     Code:=-1;
    end
   else
    Val(HintStr, I, Code);
   if Code=0 then
    HintStr:=LoadStr1(I)
   else
    if HintStr[1]=BlueHintPrefix then
     begin
      System.Delete(HintStr, 1, 1);
      if HintStr='' then Exit;
      I:=HintInfo.HintPos.X - Canvas.TextWidth(HintStr) div 3;
      if I<10 then
       HintInfo.HintPos.X:=10
      else
       HintInfo.HintPos.X:=I;
      HintInfo.HintColor:=$00F0CAA6;
      HintInfo.HintMaxWidth:=TailleMaximaleEcranX-20-I;
      Application.HintHidePause:=MaxInt;
     end
    else
     if HintStr='TEX' then
      begin
     (*HintStr:='';
       with ValidParentForm(HintInfo.HintControl) as TTextureDlg do
        if (ListView1.Items.Count=0) and EditionPossible then
         begin
          HintStr:=LoadStr1(1317);
          Dec(HintInfo.HintPos.Y, 100);
          Inc(HintInfo.HintPos.X,
           (HintInfo.HintControl.Width-Canvas.TextWidth(HintStr)) div 2);
         end;*)
      end
     else
      if HintStr[1]='�' then
       HintStr:='';
  end;
end;

procedure TForm1.AppHint(Sender: TObject);
var
 S: String;
 nForm: TForm;
 obj: PyObject;
begin
 nForm:=Screen.ActiveForm;
 if nForm is TPyForm then
  obj:=TPyForm(nForm).WindowObject
 else
  obj:=Py_None;
 S:=Application.Hint;
 Py_XDECREF(CallMacroEx2(Py_BuildValueX('(Os)', [obj, PChar(S)]), 'hint', False));
end;

(*function TForm1.AppHelp(Command: Word; Data: LongInt; var CallHelp: Boolean) : Boolean;
begin
 CallHelp:=False;
 Result:=True;
end;
*)
function TForm1.GetEmptyMenu : TPopupMenu;
var
 C: TComponent;
 I: Integer;
begin
 C:=FindComponent('gem');
 if C=Nil then
  begin
   Result:=TPopupMenu.Create(Self);
   Result.Name:='gem';
  end
 else
  begin
   Result:=C as TPopupMenu;
   for I:=Result.Items.Count-1 downto 0 do
    Result.Items[I].Free;
  end;
end;

function TForm1.GetObjMenu(Control: TControl; Extra: Boolean) : TPopupMenu;
var
 Q: TList;
 I, Flags: Integer;
 Form: TQkForm;
begin
 EditMenu.PopupComponent:=Control;
 Form:=ValidParentForm(Control as TControl) as TQkForm;
{Q:=HasGotObject(Form.ProcessEditMsg(edGetRoot));}

 Flags:=Form.ProcessEditMsg(edEdEnable);
 Cut2.Enabled    := Flags and edCut      = edCut;
 Copy2.Enabled   := Flags and edCopy     = edCopy;

 Flags:=Form.ProcessEditMsg(edObjEnable);
 OpenSel2.Enabled:= Flags and edOpen     = edOpen;

 Q:=HasGotObjects(Form.ProcessEditMsg(edGetObject));
 Properties2.Enabled:=Q.Count>0;
 Q.Free;

 Result:=ObjMenu;
 for I:=ObjSep1.MenuIndex-1 downto 0 do
  ObjSep1.Items[I].Free;
 ObjSep1.Visible:=Extra;
end;

procedure TForm1.Makefilelink1Click(Sender: TObject);
var
 OpenDialog1: TOpenDialog;
 FileObject: QFileObject;
 L: TStringList;
 I: Integer;
 S: String;
 Gr: QExplorerGroup;
 Target: TQkExplorer;
begin
 with ValidParentForm(EditMenu.PopupComponent as TControl) do
  Target:=TQkExplorer(Perform(wm_MessageInterne, wp_TargetExplorer, 0));
 if Target=Nil then Exit;
 OpenDialog1:=TOpenDialog.Create(Self); try
 OpenDialog1.Title:=LoadStr1(5591+Ord(Sender=Importfiles1));
 L:=TStringList.Create; try
 BuildFileExt(L);
 S:=L[0];
 for I:=1 to L.Count-1 do
  S:=S+'|'+L[I];
 OpenDialog1.Filter:=S;
 OpenDialog1.FilterIndex:=OpenFilterIndex;
 finally L.Free; end;
 OpenDialog1.Options:=[ofAllowMultiSelect, ofFileMustExist];
 if OpenDialog1.Execute then
  begin
   Gr:=ClipboardGroup;
   Gr.AddRef(+1); try
   for I:=0 to OpenDialog1.Files.Count-1 do
    begin
     FileObject:=LienFichierExact(OpenDialog1.Files[I], Nil, False);
     if Sender=Importfiles1 then
      FileObject.Flags:=FileObject.Flags and not ofFileLink;
     Gr.SousElements.Add(FileObject);
    end;
   Target.DropObjectsNow(Gr, LoadStr1(604+Ord(Sender=Importfiles1)), True);
   finally Gr.AddRef(-1); end;
   OpenFilterIndex:=OpenDialog1.FilterIndex;
  end;
 finally OpenDialog1.Free; end;
end;

(*procedure TForm1.Timer1Timer(Sender: TObject);
begin
 if Timer1<>Nil then
  PostMessage(Handle, wm_MessageInterne, wp_UpdateInternals, ui_Logo);
end;*)

procedure TForm1.Importfromfile1Click(Sender: TObject);
var
 Target: TQkExplorer;
begin
 with ValidParentForm(EditMenu.PopupComponent as TControl) do
  Target:=TQkExplorer(Perform(wm_MessageInterne, wp_TargetExplorer, 0));
 Importfiles1.Enabled:=Target<>Nil;
 Makefilelinks1.Enabled:=Target<>Nil;
end;

procedure TForm1.About1Click(Sender: TObject);
begin
 with TAboutBox.Create(Application) do
  try
   ShowModal;
  finally
   Free;
  end;
end;

procedure TForm1.Addons1Click(Sender: TObject);
begin
 GameCfgDlg;
end;

procedure TForm1.Outputdirectories1Click(Sender: TObject);
begin
 OutputDirDlg;
end;

procedure TForm1.Viewconsole1Click(Sender: TObject);
begin
 ShowConsole(True);
end;

procedure TForm1.HelpMenuItemClick(Sender: TObject);
var
 s: PyObject;
begin
 s:=Nil;
 try
  with Sender as TMenuItem do
   s:=PyString_FromString(PChar(Caption));
  if s=Nil then Exit;
  CallMacro(s, 'helpmenu');
 finally
  Py_XDECREF(s);
  PythonCodeEnd;
 end;
end;

procedure TForm1.Registering1Click(Sender: TObject);
begin
 HTMLDoc(ApplicationPath+'help\register.html');
end;

end.
