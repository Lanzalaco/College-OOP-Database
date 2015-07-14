program DemoOverlay2;
{demov2 - be sure that the OVERLAY compiler directive is enabled
 in the TOTFLAGS.INC file before compiling}

{$I TOTFLAGS.INC}

Uses OVERLAY, DOS, CRT,
     totSYS, totLOOK, totINPUT, totFAST, totWIN, totIO1, totMSG;

{$O totWIN}
{$O totIO1}
{$O totMSG}

Var
   MsgWin : MessageOBJ;

begin
   OvrInit('DEMOV2.OVR');   {initialize the overlay}
   OvrInitEMS;
   SYSInit;                 {initialize the Toolkit units}
   LOOKInit;
   INPUTInit;
   FASTInit;
   WINInit;
   IO1Init;
   MSGInit;
   Screen.Clear(white,'°'); {paint the screen}
   with MsgWin do
   begin
      Init(1,' Message ');
      AddLine('');
      AddLine('The message unit provides a');
      AddLine('very easy way of displaying');
      AddLine('pop-up messages in a move-');
      AddLine('able window.');
      AddLine('');
      Show;
      Done;
   end;
end.

