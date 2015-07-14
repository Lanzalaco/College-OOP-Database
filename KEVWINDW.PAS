Program Win_Demo;

Uses WinTypes, WinProcs, Objects, OWindows, ODialogs;

{$R ostdwnds.res}
{$R ostddlgs.res}

Type
    TMyApp = Object(TApplication)
             Procedure InitMainWindow; Virtual;
             End;

    ADialogPtr = ^ADialog;
    ADialog = Object (TDialog)
            Constructor Init(AParent : PWindowsObject; AName : PChar);
            End;

    AWindowPtr = ^AWindow;
    AWindow = Object(TWindow)
              Adlg : ADialogPtr;
              Constructor Init(TheParent : PWindowsObject; TheTitle : PChar);
              Procedure FileNew(Var Msg : TMessage); Virtual CM_FIRST+24330;
              End;

Procedure TMyApp.InitMainWindow;
Begin
     MainWindow:=New(AWindowPtr,Init(NIL,'A Windows Program'));
End;


Constructor AWindow.Init(TheParent : PWindowsObject; TheTitle : PChar);
Begin
     TWindow.Init(TheParent,TheTitle);
     Attr.Menu:=LoadMenu(HInstance,'FILECOMMANDS');
End;

Procedure AWindow.FileNew(Var Msg : TMessage);
Begin
    ADlg:=New(ADialogPtr,Init(@Self,PChar(32512)));
    ADlg^.Execute;
    Dispose(ADlg,Done);
End;

Constructor ADialog.Init(AParent : PWindowsObject;AName : PChar);
Begin
     TDialog.Init(AParent, AName);
End;

Var
   MyApp : TMyApp;

Begin
     MyApp.Init('Test Program');
     MyApp.Run;
     MyApp.Done;
End.