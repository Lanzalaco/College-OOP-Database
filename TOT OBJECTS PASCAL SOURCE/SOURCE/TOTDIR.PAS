{               Copyright 1991 TechnoJock Software, Inc.               }
{                          All Rights Reserved                         }
{                         Restricted by License                        }

{                             Build # 1.00                             }

Unit totDIR;
{$I TOTFLAGS.INC}

{
 Development Notes:

}

INTERFACE

uses DOS,CRT,
     totIO1, totIO2, totLINK, totSTR, totSYS, totWIN,
     totINPUT, totFAST, totMISC, totMsg;

CONST
   SignalUpdateDirField  =  10;   {Signal ID}
   SignalUpdateFileField =  11;
   ReadMessage: string[20] = 'Reading files...';
   SortMessage: string[20] = 'Sorting files...';

TYPE

pDirDLLOBJ = ^DirDLLOBJ;
DirDLLOBJ = object (DLLOBJ)
   vShowDrives: boolean;
   {methods ...}
   constructor Init;
   procedure   FillList;
   procedure   SetDrives(On:boolean);
   function    GetStr(Node:DLLNodePtr;Start,Finish: longint):string;  VIRTUAL;
   destructor  Done;
end; {DirDLLOBJ}

pFilesFieldOBJ = ^FilesFieldOBJ;
FilesFieldOBJ = object (ListIOOBJ)
   vFileList: ^FileDLLOBJ;
   vSortCode: byte;
   vSortOrder: boolean;
   {methods ...}
   constructor Init;
   procedure   SetFileDetails(FileMasks:string; FileAttrib: word);
   procedure   SetSortDetails(SortCode: byte; SortOrder: boolean);
   procedure   FillList;
   function    GetChosenFile: string;
   function    Select(K:word; X,Y:byte):TAction;                       VIRTUAL;
   procedure   ShowItemDetails(HiPick: integer);                       VIRTUAL;
   function    GetString(Pick:integer): string;                        VIRTUAL;
   function    SelectPick(InKey:word;X,Y:byte): tAction;               VIRTUAL;
   procedure   HandleSignal(var BaseSig:tSignal; var NewSig:tSignal);  VIRTUAL;
   destructor  Done;                                                   VIRTUAL;
end; {FilesFieldOBJ}

pDirFieldOBJ = ^DirFieldOBJ;
DirFieldOBJ = object (ListIOOBJ)
   vDirList: ^DirDLLOBJ;
   {methods ...}
   constructor Init;
   procedure   FillList;
   procedure   ReadDir(Status:tStatus);
   function    Select(K:word; X,Y:byte):TAction;                       VIRTUAL;
   function    GetString(Pick:integer): string;                        VIRTUAL;
   function    SelectPick(InKey:word;X,Y:byte): tAction;               VIRTUAL;
   procedure   RaiseSignal(var TheSig:tSignal);                        VIRTUAL;
   procedure   HandleSignal(var BaseSig:tSignal; var NewSig:tSignal);  VIRTUAL;
   destructor  Done;                                                   VIRTUAL;
end; {DirFieldOBJ}

pFileInputFieldOBJ = ^FileInputFieldOBJ;
FileInputFieldOBJ = object (LateralIOOBJ)
   vChangeDir: boolean;
   vChangeMask: boolean;
   vLastInput: string;
   {methods ...}
   constructor Init;
   procedure   SetLastValue(Mask:string);
   procedure   WriteLabel(Status:tStatus);                             VIRTUAL;
   function    ProcessEnter:tAction;                                   VIRTUAL;
   procedure   RaiseSignal(var TheSig:tSignal);                        VIRTUAL;
   procedure   ShutdownSignal(var BaseSig:tSignal);                    VIRTUAL;
   function    Suspend:boolean;                                        VIRTUAL;
   destructor  Done;                                                   VIRTUAL;
end; {FileInputFieldOBJ}

pDirWinOBJ = ^DirWinOBJ;
DirWinOBJ = object
   vFileSpec: ^FileInputFieldOBJ;
   vFileList: ^FilesFieldOBJ;
   vDirList: ^DirFieldOBJ;
   vOK:  Strip3DIOOBJ;
   vCancel: Strip3DIOOBJ;
   vHelp: Strip3DIOOBJ;
   vControl: ControlKeysIOOBJ;
   vManager: WinFormOBJ;
   vOldDir: string[80];
   vStartDir: string[80];
   vEndDir: string[80];
   {methods ...}
   constructor Init;
   function    Action: pWinFormOBJ;
   function    Go: tAction;
   procedure   SetFileDetails(StartDir:string; FileMasks:string; FileAttrib: word);
   procedure   SetSortDetails(SortCode: byte; SortOrder: boolean);
   function    Win: MoveWinPtr;
   function    GetChosenFile: string;
   destructor  Done;                                                   VIRTUAL;
end; {DirWinOBJ}

IMPLEMENTATION
var Floppies: byte;
{|||||||||||||||||||||||||||||||||||||||||||||}
{                                             }
{     M i s c.  P r o c s   &   F u n c s     }
{                                             }
{|||||||||||||||||||||||||||||||||||||||||||||}
procedure WriteFullDir;
{}
var Str:string;
begin
   GetDir(0,Str);
   Screen.WritePlain(1,17,padleft(Str,45,' '));
end; {WriteFullDir}

{$F+}
procedure DirHelp(ID:word);
{}
var  HelpWin: MessageOBJ;
begin
   with HelpWin do
   begin
      Init(1,'File Load Help');
      AddLine('Enter a filename (or file mask) in the Name ');
      Addline('box, or TAB to the file list and select a');
      Addline('file from the list by pressing Enter or ');
      AddLine('double clicking the mouse.');
      AddLine('');
      AddLine('To change directories, TAB to the Directories');
      AddLine('list and select one.');
      AddLine('');
      Show;
      Done;
   end;
end; {DirHelp}
{$IFNDEF OVERLAY}
  {$F-}
{$ENDIF}
{|||||||||||||||||||||||||||||||||||||||||||}
{                                           }
{     D i r D L L O b j   M E T H O D S     }
{                                           }
{|||||||||||||||||||||||||||||||||||||||||||}
constructor DirDLLOBJ.Init;
{}
begin
   DLLOBJ.Init;
   vShowDrives := true;
end; {DirDLLOBJ.Init}

procedure DirDLLOBJ.SetDrives(On:boolean);
{}
begin
   vShowDrives := On;
end; {DirDLLOBJ.SetDrives}

procedure DirDLLOBJ.FillList;
{}
var
  DirInfo: SearchRec;
  Drive: string;
  I : integer;
  Result: longint;
  Ecode : integer;
  ActiveDrive: integer;
begin
   if vStartNodePtr <> Nil then
      EmptyList;
   FindFirst('*.*', AnyFile, DirInfo);
   while DOSError = 0 do
   begin
      if ((DirInfo.Attr and Directory) = Directory)
      and (DirInfo.Name <> '.') then
      begin
         Drive := '['+DirInfo.Name+']';
         Ecode := Add(Drive,succ(length(Drive)));
         if Ecode = 0 then
            vActiveNodePtr^.SetStatus(0,true);  {indicates directory change}
      end;
      FindNext(DirInfo);
   end;
   if vShowDrives then  {get active drives}
   begin
      {$I-}
      getdir(0,Drive);
      {$I-}
      if IOResult = 0 then
         ActiveDrive := ord(Drive[1]) - 64
      else
         ActiveDrive := 0;
      if (Floppies >= 1) and (ActiveDrive <> 1) then
      begin
         Drive := '[ -A- ]';
         Ecode := Add(Drive,8);
      end;
      if (Floppies >= 2) and (ActiveDrive <> 2) then
      begin
         Drive := '[ -B- ]';
         Ecode := Add(Drive,8);
      end;
      for I := 3 to 26 do {test all letters}
      begin
         Result := DiskSize(I);
         if (Result <> -1) and (ActiveDrive <> I) then {valid drive}
         begin
            Drive := '[ -'+char(I+64)+'- ]';
            Ecode := Add(Drive,8);
         end;
      end;
   end;
   Jump(1);
end; {DirDLLOBJ.FillList}

function DirDLLOBJ.GetStr(Node:DLLNodePtr;Start,Finish: longint):string;
{ignores Start and Finish parameters}
var temp : string;
begin
   if (Node = Nil)
   or (Node^.vDataPtr = Nil)
   or (Node^.vSize = 0)  then
      GetStr := ''
   else
   begin
      Move(mem[seg(Node^.vDataPtr^):ofs(Node^.vDataPtr^)],Temp[0],15);
      GetStr := Temp;
   end;
end; {DirDLLOBJ.GetStr}

destructor DirDLLOBJ.Done;
{}
begin
   DLLOBJ.Done;
end; {DirDLLOBJ.Done}
{||||||||||||||||||||||||||||||||||||||||||||||||||||}
{                                                    }
{     F i l e s F i e l d O B J   M e t h o d s      }
{                                                    }
{||||||||||||||||||||||||||||||||||||||||||||||||||||}
constructor FilesFieldOBJ.Init;
{}
begin
   ListIOOBJ.Init(3,4,13,12,'Files:');
   new(vFileList,Init);
   vSortCode := 0;
   vSortOrder := true;
end; {FilesFieldOBJ.Init}

procedure FilesFieldOBJ.SetFileDetails(FileMasks:string; FileAttrib: word);
{}
begin
   vFileList^.SetFileDetails(FileMasks,FileAttrib);
end; {FilesFieldOBJ.SetFileDetails}

procedure FilesFieldOBJ.ShowItemDetails(HiPick: integer);
{}
var FileInfo: tFileInfo;
begin
   vFileList^.GetFileRecord(FileInfo,HiPick);
   if FileInfo.FileName = NoFiles then
     Screen.WritePlain(1,18,replicate(45,' '))
   else
     Screen.WritePlain(1,18,padleft(LongName(FileInfo),45,' '));
end; {FilesFieldOBJ.ShowItemDetails}

procedure FilesFieldObj.FillList;
{}
begin
   Screen.WritePlain(1,18,padleft(ReadMessage,45,' '));
   vFileList^.FillList;
   Screen.WritePlain(1,18,padleft(SortMessage,45,' '));
   vFileList^.Sort(vSortCode,vSortOrder);
   vListAssigned := true;
   vTotPicks := vFileList^.TotalNodes;
end;  {FilesFieldObj.AssignList}

function FilesFieldOBJ.GetString(Pick:integer): string;
{}
var
  TempPtr : DLLNodePtr;
begin
   TempPtr := vFileList^.NodePtr(Pick);
   if TempPtr <> Nil then
      vFileList^.ShiftActiveNode(TempPtr,Pick);
   GetString := vFileList^.GetStr(TempPtr,0,0);
end; {FilesFieldOBJ.GetString}

function FilesFieldOBJ.SelectPick(InKey:word;X,Y:byte):tAction;
{}
var SP: tAction;
begin
  if (Inkey = 523) and (TargetPick(X,Y) <> 0) then  {select the new pick}
  begin
     MouseChoose(X,Y);
     SP := Finished;
  end
  else if (Inkey = 13) then
     SP := Finished
  else
     SP := none;
  if (SP = Finished) and (GetString(vFileList^.ActiveNodeNumber) = NoFiles) then
     SP := none;
  SelectPick := SP;
end; {FilesFieldOBJ.SelectPick}

function FilesFieldOBJ.Select(K:word; X,Y:byte):TAction;
{}
var New: byte;
begin
   vScrollBarOn := (vTotPicks >= vRows);
   vActiveField := true;
   Display(HiStatus);
   WriteLabel(HiStatus);
   WriteMessage;
   if (K = 513) or (K=523) then
   begin
      if vScrollBarOn and (X = vBorder.X2) then
        {nothing for now}
      else
      begin
         New := HitItem(Y);
         if New > 0 then
         begin
            WriteItem(vActivePick,false);
            vActivePick := New;
            WriteItem(vActivePick,true);
            if (K=523) then
            begin
               Select := SelectPick(K,X,Y);
               exit;
            end;   
         end;
      end;
   end;
   Select := none;
end; {FilesFieldOBJ.Select}

procedure FilesFieldOBJ.SetSortDetails(SortCode: byte; SortOrder: boolean);
{}
begin
   vSortCode := SortCode;
   vSortOrder := SortOrder;
end; {FilesFieldOBJ.SetSortDetails}

procedure FilesFieldOBJ.HandleSignal(var BaseSig:tSignal; var NewSig:tSignal);
{}
var
  Len : byte;
  NewMask: string;
begin
   if BaseSig.ID = SignalUpdateFileField then
   begin
      if (BaseSig.MSGtype = 0) then {new filemask}
      begin
         move(BaseSig.MsgPtr^,Len,1);
         if len > 0 then
         begin
            move(BaseSig.MsgPtr^,NewMask,succ(Len));
            Screen.WritePlain(1,18,padleft(ReadMessage,45,' '));
            vFileList^.FillNewMask(NewMask);
            Screen.WritePlain(1,18,padleft(SortMessage,45,' '));
            vFileList^.Sort(vSortCode,vSortOrder);
         end;
      end
      else
         FillList;
      vTopPick := 1;
      vTotPicks := vFileList^.TotalNodes;
      vActivePick := 1;
      Display(Norm);
      BaseSig.ID := 0; {All Done!}
   end;
end; {FilesFieldOBJ.HandleSignal}

function FilesFieldOBJ.GetChosenFile:string;
{}
begin
   GetChosenFile := GetString(vTopPick + pred(vActivePick));
end; {FilesFieldOBJ.GetChosenFile}

destructor FilesFieldOBJ.Done;
{}
begin
   ListIOOBJ.Done;
   dispose(vFileList,Done);
end; {FilesFieldOBJ.Done}
{||||||||||||||||||||||||||||||||||||||||||||||||}
{                                                }
{     D i r F i e l d O B J   M e t h o d s      }
{                                                }
{||||||||||||||||||||||||||||||||||||||||||||||||}
constructor DirFieldOBJ.Init;
{}
begin
   ListIOOBJ.Init(18,4,15,12,('Directories:'));
   new(vDirList,Init);
end; {DirFieldOBJ.Init}

function DirFieldOBJ.GetString(Pick:integer): string;
{}
var
  TempPtr : DLLNodePtr;
begin
   TempPtr := vDirList^.NodePtr(Pick);
   if TempPtr <> Nil then
      vDirList^.ShiftActiveNode(TempPtr,Pick);
   GetString := vDirList^.GetStr(TempPtr,0,0);
end; {DirFieldOBJ.GetString}

procedure DirFieldOBJ.RaiseSignal(var TheSig:tSignal);
{}
begin
   with TheSig do
   begin
      ID := SignalUpdateFileField;
      MsgType := 99;
   end;
end; {DirFieldOBJ.RaiseSignal}

procedure DirFieldOBJ.HandleSignal(var BaseSig:tSignal; var NewSig:tSignal);
{}
begin
   if (BaseSig.ID = SignalUpdateDirField) then
   begin
      ReadDir(Norm);
      BaseSig.ID := 0; {All Done!}
   end;
end; {DirFieldOBJ.HandleSignal}

procedure DirFieldOBJ.FillList;
{}
begin
   vDirList^.FillList;
   vTopPick := 1;
   vTotPicks := vDirList^.TotalNodes;
   vActivePick := 1;
   vListAssigned := true;
end; {DirFieldOBJ.FillList}

procedure DirFieldOBJ.ReadDir(Status:tStatus);
{}
begin
   FillList;
   Display(Status);
end; {DirFieldOBJ.ReadDir}

function DirFieldOBJ.SelectPick(InKey:word;X,Y:byte):tAction;
{}
var
  TempPtr : DLLNodePtr;
  NewDir : string;
begin
  if (Inkey = 523) then  {select the new pick}
  begin
     if TargetPick(X,Y) <> 0 then
        MouseChoose(X,Y)
     else
     begin
        SelectPick := none;
        exit;
     end;
  end;
  {change to the new drive/directory and display the new list}
  NewDir := GetString(pred(vTopPick)+vActivePick);
  TempPtr := vDirList^.NodePtr(pred(vTopPick)+vActivePick);
  if TempPtr^.GetStatus(0) then {directory}
  begin
     delete(NewDir,1,1);  {remove []}
     delete(NewDir,length(NewDir),1);
  end
  else
  begin
     NewDir := NewDir[4]+':';
  end;
{$I-}
  ChDir(NewDir);
{$I+}
  if IOResult = 0 then
  begin
     WriteFullDir;
     ReadDir(HiStatus);
     vScrollBarOn := vTotPicks > vRows;
     {now raise a signal to load a new directory}
     SelectPick := Signal;
  end
  else
     SelectPick := none;
end; {DirFieldOBJ.SelectPick}

function DirFieldOBJ.Select(K:word; X,Y:byte):TAction;
{}
var New: byte;
begin
   vScrollBarOn := (vTotPicks >= vRows);
   vActiveField := true;
   Display(HiStatus);
   WriteLabel(HiStatus);
   WriteMessage;
   if (K = 513) or (K=523) then
   begin
      if vScrollBarOn and (X = vBorder.X2) then
        {nothing for now}
      else
      begin
         New := HitItem(Y);
         if New > 0 then
         begin
            WriteItem(vActivePick,false);
            vActivePick := New;
            WriteItem(vActivePick,true);
            if (K=523) then
            begin
               Select := SelectPick(K,X,Y);
               exit;
            end;   
         end;
      end;
   end;
   Select := none;
end; {DirFieldOBJ.Select}

destructor DirFieldOBJ.Done;
{}
begin
   ListIOOBJ.Done;
   dispose(vDirList,Done);
end; {DirFieldOBJ.Done}
{||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||}
{                                                            }
{     F i l e I n p u t F i e l d O B J   M e t h o d s      }
{                                                            }
{||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||}
constructor FileInputFieldOBJ.Init;
{}
begin
   LateralIOOBJ.Init(3,2,30,75);
   vRules := EraseDefault;
   vInputStr := '*.*';
   vLastInput := vInputStr;
   vChangeDir := false; 
   vChangeMask := false;
   SetPadChar(' ');
end; {FileInputFieldOBJ.Init}

procedure FileInputFieldOBJ.SetLastValue(Mask:string);
{}
begin
   vLastInput := Mask;
end; {FileInputFieldOBJ.SetLastValue}

procedure FileInputFieldOBJ.WriteLabel(Status:tStatus);
{}
var
  Norm,Hi: byte;
begin
   AssignColors(IOTOT^.vLabel,IOTOT^.vField,Status,Hi,Norm);
   if (Hi = 0) or (Norm = 0) then
      Screen.WritePlain(vBoundary.X1,pred(vBoundary.Y1),'Name:')
   else
      Screen.WriteHi(vBoundary.X1,pred(vBoundary.Y1),Hi,Norm,'Name:');
end; {FileInputFieldOBJ.WriteLabel}

function FileInputFieldOBJ.ProcessEnter: tAction;
{if a file is specified, finish, otherwise raise a signal}
var
  D,N,E,FN : string;
begin
   vChangeDir  := false;
   vChangeMask := false;
   if vInputStr = '' then
   begin
      vInputStr := '*.*';
      vChangeMask := true;
   end
   else
   begin
      FSplit(vInputStr,D,N,E);
      FN := N+E;
      if  (pos('*',FN) = 0)
      and (pos('?',FN) = 0)
      and (FN <> '') then {a real filename was entered}
      begin
         ProcessEnter := Finished;
         exit;
      end
      else
      begin
         if D <> '' then
         begin
            if  (D[length(D)] = '\')
            and  not ((length(D) = 3) and (pos(':',D) = 2) )
            and (D <> '\') then
               delete(D,length(D),1);
            {$I-}
            chdir(D);
            {$I+}
            if IOResult = 0 then
            begin
               WriteFullDir;
               vChangeDir := true;
            end;
            if FN = '' then
               vInputStr := '*.*'
            else
               vInputStr := FN;
            vChangeMask := true;
         end
         else  {must have entered one or more wildcard file names}
            vChangeMask := true;
      end;
   end;
   CursorHome;
   Display(HiStatus);
   vLastInput := vInputStr;
   ProcessEnter := signal;
end; {FileInputFieldOBJ.ProcessEnter}

procedure FileInputFieldOBJ.RaiseSignal(var TheSig:tSignal);
{}
begin
   with TheSig do
   begin
      if vChangeDir then
      begin
         ID := SignalUpdateDirField;
         MsgType := 99;
         vChangeDir := false;
      end
      else
      begin
         ID := SignalUpdateFileField;
         MsgType := 0;
         MsgPtr := @vInputStr;
         vChangeMask := false;
      end;
   end;
end; {FileInputFieldOBJ.RaiseSignal}

procedure FileInputFieldOBJ.ShutdownSignal(var BaseSig:tSignal);
{}
begin
   with BaseSig do
   begin
      if vChangeMask then
      begin
         ID := SignalUpdateFileField;
         MsgType := 0;
         MsgPtr := @vInputStr;
         vChangeMask := false;
      end;
   end;
   MoveCursor;
end; {FileInputFieldOBJ.ShutdownSignal}

function FileInputFieldOBJ.Suspend:boolean;
{}
begin
   Suspend := LateralIOOBJ.Suspend;
   if vLastInput <> vInputStr then
   begin
      Suspend := false;
      Key.StuffBuffer(13);
      Key.StuffBuffer(9);
   end;
end; {FileInputFieldOBJ.Suspend}

destructor FileInputFieldOBJ.Done;
{}
begin
   LateralIOOBJ.Done;
end; {FileInputFieldOBJ.Done}
{||||||||||||||||||||||||||||||||||||||||||||}
{                                            }
{     D i r W i n O B J   M e t h o d s      }
{                                            }
{||||||||||||||||||||||||||||||||||||||||||||}
constructor DirWinOBJ.Init;
{}
begin
   new(vFileSpec,Init);
   new(vFileList,Init);
   new(vDirList,Init);
   vOK.Init(35,2,'   ~O~K   ',Finished);
   vOK.SetHotKey(280); {Alt-O}
   vCancel.Init(35,5,' ~C~ancel ',Escaped);
   vCancel.SetHotkey(302); {Alt-C}
   vHelp.Init(35,8,'  ~H~elp  ',Help);
   vHelp.SetHotkey(291); {Alt-H}
   vControl.Init; {Tab, STab, F10, Esc}
   vStartDir := '';
   vFileSpec^.SetID(1);
   vFileList^.SetID(2);
   vDirList^.SetID(3);
   vOK.SetID(4);
   vCancel.SetID(5);
   vHelp.SetID(HelpID);
   with vManager do
   begin
      Init;
      Win^.SetSize(18,3,63,22,1);
      Win^.SetTitle(' Choose a file ');
      AddItem(vControl);
      AddItem(vFileSpec^);
      AddItem(vFileList^);
      AddItem(vDirList^);
      AddItem(vOK);
      AddItem(vCancel);
      AddItem(vHelp);
      SetHelpHook(DirHelp);
   end;
end; {DirWinOBJ.Init}

function DirWinOBJ.Win:MoveWinPtr;
{}
begin
   Win := vManager.Win;
end; {DirWinOBJ.Win}

function DirWinOBJ.Action: pWinFormOBJ;
{}
begin
   Action := @vManager;
end; {DirWinOBJ.Action}

procedure DirWinOBJ.SetFileDetails(StartDir:string; FileMasks:string; FileAttrib: word);
{}
begin
   vStartDir := StartDir;
   vFileList^.SetFileDetails(FileMasks,FileAttrib);
   vFileSpec^.SetValue(FileMasks);
   vFileSpec^.SetLastValue(FileMasks);
end; {DirWinOBJ.SetFileDetails}

procedure DirWinOBJ.SetSortDetails(SortCode: byte; SortOrder: boolean);
{}
begin
   vFileList^.SetSortDetails(SortCode,SortOrder);
end; {DirWinOBJ.SetSortDetails}

function DirWinOBJ.Go: tAction;
{}
var
   Visible,kDouble: boolean;
   Result: tAction;
begin
   Visible:= Mouse.Visible;
   kDouble := Key.GetDouble;
   if not kDouble then
      Key.SetDouble(true);
   getdir(0,vOldDir);
   if vStartDir <> '' then
   begin
      {$I-}
      chdir(vStartDir);
      {$I+}
      if IOResult <> 0 then
         {whogivesashit};
   end;
   vManager.Draw;
   vFileList^.FillList;
   vDirList^.FillList;
   WriteFullDir;
   if not Visible then
      Mouse.Show;
   repeat
      Result := vManager.Go;
   until ((Result = Finished) and (vFileList^.GetChosenFile=NoFiles)) = false;
   Go := Result;
   vManager.Win^.Remove;
   getdir(0,vEndDir);
   {$I-}
   chdir(vOldDir);
   {$I+}
   if IOResult <> 0 then
      {whogivesashit};
   Key.SetDouble(kDouble);
   if not Visible then
      Mouse.Hide;
end; {DirWinOBJ.Go}

function DirWinOBJ.GetChosenFile:string;
{}
var Str: string;
begin
   Str := vFileSpec^.GetValue;
   if  (pos('*',Str) = 0)
   and (pos('?',Str) = 0)
   and (Str <> '') then
     GetChosenFile := Str
   else
     GetChosenFile := SlashedDirectory(vEndDir)+vFileList^.GetChosenFile;
end; {DirWinOBJ.GetChosenFile}

destructor DirWinOBJ.Done;
{}
begin
   dispose(vFileSpec,Done);
   dispose(vFileList,Done);
   dispose(vDirList,Done);
   vOK.Done;
   vCancel.Done;
   vHelp.Done;
   vControl.Done;
   vManager.Done;
end; {DirWinOBJ.Done}
{|||||||||||||||||||||||||||||||||||||||||||||||}
{                                               }
{     U N I T   I N I T I A L I Z A T I O N     }
{                                               }
{|||||||||||||||||||||||||||||||||||||||||||||||}
procedure DIRInit;
{initilizes objects and global variables}
var Equip: EquipObj;
begin
   Equip.Init;
   Floppies := Equip.FloppyDrives;
end;

{end of unit - add initialization routines below}
{$IFNDEF OVERLAY}
begin
   DIRInit;
{$ENDIF}
end.



