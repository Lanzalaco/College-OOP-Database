{               Copyright 1991 TechnoJock Software, Inc.               }
{                          All Rights Reserved                         }
{                         Restricted by License                        }

{                             Build # 1.00                             }

Unit totINPUT;
{$I TOTFLAGS.INC}

{
 Development Notes:

}


INTERFACE

uses DOS,CRT;

Const
    StuffBufferSize = 30;

Type

InputIdleProc    = procedure;
InputPressedProc = procedure(var W:word);
CharProc         = procedure(W:word);
CaseFunc         = function(Ch:char):char;
CharSet = set of char;

pAlphabetOBJ = ^AlphabetOBJ;
AlphabetOBJ = object
   vUpper: CharSet;
   vLower: CharSet;
   vPunctuation: CharSet;
   vUpCaseFunc: CaseFunc;
   vLoCaseFunc: CaseFunc;
   {methods...}
   constructor Init;
   procedure   AssignUpCaseFunc(Func:caseFunc);
   procedure   AssignLoCaseFunc(Func:caseFunc);
   procedure   SetUpper(Letters:CharSet);
   procedure   SetLower(Letters:CharSet);
   procedure   SetPunctuation(Letters:CharSet);
   function    IsUpper(K:word): boolean;
   function    IsLower(K:word): boolean;
   function    IsLetter(K:word): boolean;
   function    IsPunctuation(K:word): boolean;
   function    GetUpCase(Ch:char):char;
   function    GetLoCase(Ch:char):char;
   destructor  Done;
end; {AlphabetOBJ}

pMouseOBJ = ^MouseOBJ;
MouseOBJ = object
   vInstalled: boolean;   {is the system equipped with a mouse}
   vButtons: byte;        {how many buttons on mouse}
   vLeftHanded: boolean;  {is right button Enter?}
   vIntr: integer;        {mouse interrupt number}
   vVisible: boolean;     {is mouse cursor visible?}
   {methods}
   constructor Init;
   procedure   Reset;
   function    Installed:boolean;
   procedure   CheckInstalled;
   procedure   Show;
   procedure   Hide;
   procedure   Move(X,Y : integer);
   procedure   Confine(X1,Y1,X2,Y2:integer);
   function    Released(Button: integer; var X,Y: byte): byte;
   function    Pressed(Button: integer; var X,Y: byte): byte;
   function    InZone(X1,Y1,X2,Y2: byte):boolean;
   procedure   Location(var X,Y : byte);
   procedure   Status(var L,C,R:boolean; var X,Y : byte);
   function    Visible: boolean;
   procedure   SetMouseCursorStyle(OrdChar,Attr:byte);
   procedure   SetLeft(On:boolean);
   function    GetButtons: byte;
   destructor  Done;
end; {MouseOBJ}

pKeyOBJ = ^KeyOBJ;
KeyOBJ = object
   vMouseMethod: byte;        {0-no mouse, 1-cursor emulation, 2-freefloating mouse}
   vBuffer: array[1..StuffBufferSize] of word;
   vBufferHead: word;         {next character from buffer}
   vBufferTail:word;          {last valid character in buffer}
   vLastkey: word;            {the last key pressed}
   vLastX:byte;               {location of mouse when button pressed}
   vLastY:byte;               {                -"-                  }
   vClick: boolean;           {click after every keypress?}
   vHorizSensitivity: byte;   {no of characters}
   vVertSensitivity: byte;    {      -"-       }
   vWaitForDouble: boolean;
   vIdleHook: InputIdleProc;
   vPressedHook: InputPressedProc;
   vExtended : boolean;       {is it an extended keyboard}
   vButtons : byte;
   {methods...}
   constructor Init;
   procedure   AssignIdleHook(PassedProc: InputIdleProc);
   procedure   AssignPressedHook(PassedProc: InputPressedProc);
   function    Extended: boolean;
   procedure   SetCaps(On:boolean);
   procedure   SetNum(On:boolean);
   procedure   SetScroll(On:boolean);
   function    GetCaps:boolean;
   function    GetNum:boolean;
   function    GetScroll:boolean;
   procedure   SetRepeatRate(Delay,Rate:byte);
   procedure   SetFast;
   procedure   SetSlow;
   procedure   SetMouseMethod(Method:byte);
   procedure   SetClick(On: boolean);
   procedure   SetDouble(On:boolean);
   function    GetDouble:boolean;
   procedure   Click;
   procedure   SetHoriz(Sensitivity:byte);
   procedure   SetVert(Sensitivity:byte);
   procedure   GetInput;
   function    LastKey: word;
   function    LastChar: char;
   function    LastX: byte;
   function    LastY: byte;
   function    GetKey: word;
   procedure   FlushBuffer;
   procedure   StuffBuffer(W:word);
   procedure   StuffBufferStr(Str:string);
   function    Keypressed: boolean;
   procedure   DelayKey(Mills:longint);
   function    AltPressed:boolean;
   function    CtrlPressed:boolean;
   function    LeftShiftPressed: boolean;
   function    RightShiftPressed: boolean;
   function    ShiftPressed: boolean;
   destructor  Done;
end; {KeyOBJ}

procedure NoInputIdleHook;
procedure NoInputPressedHook(var W:word);
function  Altkey(K: word): word;
procedure inputINIT;

VAR
   AlphabetTOT: ^AlphabetOBJ;
   Mouse: MouseOBJ;
   Key:   KeyOBJ;

IMPLEMENTATION
var
   KeyStatusBits : word absolute $0040:$0017;

{|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||}
{                                                               }
{     U N I T   P R O C E D U R E S   &   F U N C T I O N S     }
{                                                               }
{|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||}

{$F+}
 procedure NoInputIdleHook;
 {empty procs}
 begin end; {NoInputIdleHook}

 procedure NoInputPressedHook(var W:word);
 {empty procs}
 begin end; {NoInputPressedHook}

 function EnglishUpCase(Ch:char):char;
 {}
 begin
    EnglishUpCase := upcase(Ch);
 end; {EnglishUpCase}
(*
 inline($58/$3C/$61/$72/$39/$3C/$7A/$76/$33/$3C/$84/$75/$02/$B0/$8E
 /$3C/$94/$75/$02/$B0/$99/$3C/$81/$75/$02/$B0/$9A
 /$3C/$87/$75/$02/$B0/$80/$3C/$86/$75/$02/$B0/$BF
 /$3C/$82/$75/$02/$B0/$90/$3C/$91/$75/$02/$B0/$92
 /$3C/$A4/$75/$02/$B0/$A5/$EB/03/90/$2C/$20);
*)
 function EnglishLoCase(Ch:char):char;
 {}
 begin
   if Ch in ['A'..'Z'] then
      EnglishLoCase := chr(ord(Ch) + 32)
   else
      EnglishLoCase := Ch;
 end; {EnglishLoCase}
 (*
 inline($58/$3C/$41/$72/$39/$3C/$5A/$76/$33/$3C/$8E/$75/$02/$B0/$B4
 /$3C/$99/$75/$02/$B0/$94/$3C/$9A/$75/$02/$B0/$81
 /$3C/$8D/$75/$02/$B0/$87/$3C/$8F/$75/$02/$B0/$86
 /$3C/$9D/$75/$02/$B0/$82/$3C/$92/$75/$02/$B0/$91
 /$3C/$A5/$75/$02/$B0/$A4/$EB/03/90/$04/$20);
 *)
{$F-}

function Altkey(K: word): word;
{returns the Alt keycode equivalent of a number or letter}
var AK: word;
begin
   Case K of
      65:AK:=286; 66:AK:=304; 67:AK:=302; 68:AK:=288; 69:AK:=274; 70:AK:=289;
      71:AK:=290; 72:AK:=291; 73:AK:=279; 74:AK:=292; 75:AK:=293; 76:AK:=294;
      77:AK:=306; 78:AK:=305; 79:AK:=280; 80:AK:=281; 81:AK:=272; 82:AK:=275;
      83:AK:=287; 84:AK:=276; 85:AK:=278; 86:AK:=303; 87:AK:=273; 88:AK:=301;
      89:AK:=277; 90:AK:=300; 48:AK:=385;
   else if (K >= 49) and (K <= 57) then
           AK := K + 327
        else 
           AK := 0;
   end; {case}
   AltKey := AK;
end; {AltKey}
{|||||||||||||||||||||||||||||||||||||||||||||||||}
{                                                 }
{     A l p h a b e t O B J    M E T H O D S      }
{                                                 }
{|||||||||||||||||||||||||||||||||||||||||||||||||}
constructor AlphabetOBJ.Init;
{}
begin
   vUpper := ['A'..'Z'];
   vLower := ['a'..'z'];
   vPunctuation := [',',';',':','.',' '];
   AssignUpcaseFunc(EnglishUpcase);
   AssignLocaseFunc(EnglishLocase);
end; {AlphabetOBJ.Init}

procedure AlphabetOBJ.AssignUpCaseFunc(Func:caseFunc);
{}
begin
   vUpCaseFunc := Func;
end; {AlphabetOBJ.AssignUpCaseFunc}

procedure AlphabetOBJ.AssignLoCaseFunc(Func:caseFunc);
{}
begin
   vLoCaseFunc := Func;
end; {AlphabetOBJ.AssignLoCaseFunc}

procedure AlphabetOBJ.SetUpper(Letters:CharSet);
{}
begin
   vUpper := Letters;
end; {AlphabetOBJ.SetUpper}

procedure AlphabetOBJ.SetLower(Letters:CharSet);
{}
begin
   vLower := Letters;
end; {AlphabetOBJ.SetLower}

procedure AlphabetOBJ.SetPunctuation(Letters:CharSet);
{}
begin
   vPunctuation := Letters;
end; {AlphabetOBJ.SetPunctuation}

function AlphabetOBJ.IsUpper(K:word): boolean;
{}
begin
   if K > 255 then
     IsUpper := false
   else
     IsUpper := chr(K) in vUpper;
end; {AlphabetOBJ.IsUpper}

function AlphabetOBJ.IsLower(K:word): boolean;
{}
begin
   if K > 255 then
     IsLower := false
   else
     IsLower := chr(K) in vLower;
end; {AlphabetOBJ.IsLower}

function AlphabetOBJ.IsLetter(K:word): boolean;
{}
begin
   if K > 255 then
     IsLetter := false
   else
     IsLetter := (chr(K) in vUpper) or (chr(K) in vLower);
end; {AlphabetOBJ.IsLetter}

function AlphabetOBJ.IsPunctuation(K:word): boolean;
{}
begin
   if K > 255 then
     IsPunctuation := false
   else
   IsPunctuation := chr(K) in vPunctuation;
end; {AlphabetOBJ.IsPunctuation}

function AlphabetOBJ.GetUpCase(Ch:char):char;
{}
begin
   GetUpCase := vUpCaseFunc(Ch);
end; {AlphabetOBJ.GetUpCase}

function AlphabetOBJ.GetLoCase(Ch:char):char;
{}
begin
   GetLoCase := vLoCaseFunc(Ch);
end;{AlphabetOBJ.GetLoCase}

destructor AlphabetOBJ.Done;
{}
begin
end; {AlphabetOBJ.Done}
{|||||||||||||||||||||||||||||||||||||||||||}
{                                           }
{     M o u s e O B J    M E T H O D S      }
{                                           }
{|||||||||||||||||||||||||||||||||||||||||||}
constructor MouseOBJ.Init;
{}
begin
  CheckInstalled;
  If vInstalled then
  begin
     vIntr := $33;
     vVisible := false;
     Reset;
  end
  else
     vVisible := false;
end; {MouseOBJ.Init}

procedure MouseOBJ.CheckInstalled;
{}
var
  MouseInterruptPtr : pointer absolute $0000:$00CC;

    Function InterruptLoaded:boolean;
    var
      Reg: registers;
    begin
       Reg.Ax := 0;
       Intr($33,Reg);
       InterruptLoaded :=  Reg.Ax <> 0;
    end;

begin
   vButtons := 0;
   if (MouseInterruptPtr = nil)
   or (byte(MouseInterruptPtr) = $CF) then
      vInstalled := false          {don't call interrupt if vector is zero}
   else
      vInstalled := Interruptloaded;
end; {MouseOBJ.CheckInstalled}

procedure MouseOBJ.Reset;
{}
var Regs : registers;
begin
   if vInstalled then
   begin
      Regs.Ax := $00;
      Intr(vIntr,Regs);
      vButtons := Regs.Bx;
      vVisible := false;
   end;
end; {MouseOBJ.Reset}

function MouseOBJ.Installed:boolean;
{}
begin
    Installed := vInstalled;
end; {MouseOBJ.Installed}

procedure MouseOBJ.Show;
{}
var Regs : registers;
begin
   if (vInstalled) and (not vVisible) then
   begin
      Regs.Ax := $01;
      Intr(vIntr,Regs);
      vVisible := true;
   end;
end; {MouseOBJ.Show}

procedure MouseOBJ.Hide;
{}
var Regs : registers;
begin
   if vInstalled and vVisible then
   begin
      Regs.Ax := $02;
      Intr(vIntr,Regs);
      vVisible := false;
   end;
end; {MouseOBJ.Hide}

procedure MouseOBJ.Move(X,Y : integer);
{X and Y are character positions not pixel positions}
var Regs : registers;
begin
   if vInstalled then
   begin
      with Regs do
      begin
         Ax := $04;
         Cx := pred(X*8);   {8 pixels per character}
         Dx := pred(Y*8);   {         "-"          }
      end; {with}
      Intr(vIntr,Regs);
   end;
end; {MouseOBJ.Move}

procedure MouseOBJ.Confine(X1,Y1,X2,Y2:integer);
{}
var Regs : registers;
begin
   if vInstalled then
      with Regs do
      begin
         {horizontal}
         Ax := $07;
         Cx := pred(X1*8);
         Dx := pred(X2*8);
         intr(vIntr,Regs);
         {vertical}
         Ax := $08;
         Cx := pred(Y1*8);
         Dx := pred(Y2*8);
         intr(vIntr,Regs);
      end;
end; {MouseOBJ.Confine}

function MouseOBJ.Released(Button: integer; var X,Y: byte): byte;
{}
var Regs : registers;
begin
   if vInstalled then
      with Regs do
      begin
         Ax := 6;
         Bx := Button;
         intr(vIntr,Regs);
         Released := Bx;
         X := succ(Cx div 8);
         Y := succ(Dx div 8);
      end;
end; {MouseOBJ.Released}

function MouseOBJ.Pressed(Button: integer; var X,Y: byte): byte;
{}
var Regs : registers;
begin
   if vInstalled then
      with Regs do
      begin
         Ax := 5;
         Bx := Button;
         intr(vIntr,Regs);
         Pressed := Bx;
         X := succ(Cx div 8);
         Y := succ(Dx div 8);
      end;
end; {MouseOBJ.Pressed}

function MouseOBJ.InZone(X1,Y1,X2,Y2: byte):boolean;
{}
var X,Y: byte;
begin
   if vInstalled and vVisible then
   begin
      Location(X,Y);
      InZone := (X >= X1) and (X <= X2) and (Y >= Y1) and (Y <= Y2);
   end
   else
      InZone := false;
end; {MouseOBJ.InZone}

procedure MouseOBJ.Location(var X,Y : byte);
{}
var Regs : registers;
begin
   if vInstalled then
      with Regs do
      begin
         Ax := 3;
         intr(vIntr,Regs);
         X := succ(Cx div 8);
         Y := succ(Dx div 8);
      end; {with}
end; {MouseOBJ.Location}

procedure MouseOBJ.Status(var L,C,R:boolean; var X,Y : byte);
{}
var Regs : registers;
begin
   if vInstalled then
   begin
      with Regs do
      begin
         Ax := 3;
         intr(vIntr,Regs);
         X := succ(Cx div 8);
         Y := succ(Dx div 8);
         L := ((BX and $01) = $01);
         R := ((BX and $02) = $02);
         C := ((BX and $04) = $04);
      end; {with}
   end
   else
   begin
      L := false;
      C := false;
      R := false;
      X := 1;
      Y := 1;
   end;
end; {MouseOBJ.Status}

procedure MouseOBJ.SetMouseCursorStyle(OrdChar,Attr: byte);
var
  Reg: registers;
begin
   if vInstalled then
   begin
      Reg.Ax := 10;
      Reg.Bx := 0;        {software text cursor}
      if Attr = 0 then
         Reg.CX := $7700
      else
         Reg.Cx := $00;
      Reg.Dl := OrdChar;
      Reg.Dh := Attr;
      Intr($33,Reg);
   end;
end; {MouseOBJ.SetMouseCursorStyle}

function MouseOBJ.Visible:boolean;
{}
begin
   Visible := vVisible;
end; {MouseOBJ.Visible}

function MouseOBJ.GetButtons: byte;
{}
begin
   GetButtons := vButtons;
end; {MouseOBJ.GetButtons}

procedure MouseOBJ.SetLeft(On:boolean);
{}
begin
   vLeftHanded := On;
end; {MouseOBJ.SetLeft}

destructor MouseOBJ.Done;
{}
begin end;
{|||||||||||||||||||||||||||||||||||||||}
{                                       }
{     K e y O B J    M e t h o d s      }
{                                       }
{|||||||||||||||||||||||||||||||||||||||}
constructor KeyOBJ.Init;
{}
var
   ExtStatus: byte absolute $0000:$0496;
begin
   vExtended := (ExtStatus <> 0);
   vIdleHook := NoInputIdleHook;
   vPressedHook := NoInputPressedHook;
   vBufferHead := 1;
   vBufferTail := 1;
   vHorizSensitivity := 1;
   vVertSensitivity := 1;
   vClick := false;
   vLastKey := 0;
   vWaitForDouble := false;
   vButtons := 0;
   SetMouseMethod(2);
end; {KeyOBJ.Init}

procedure KeyOBJ.AssignIdleHook(PassedProc: InputIdleProc);
{}
begin
   vIdleHook := PassedProc;
end; {KeyOBJ.AssignIdleHook}

procedure KeyOBJ.AssignPressedHook(PassedProc: InputPressedProc);
{}
begin
   vPressedHook := PassedProc;
end; {KeyOBJ.AssignPressedHook}

function KeyOBJ.Extended:boolean;
{}
begin
    Extended := vExtended;
end; {KeyOBJ.Extended}

procedure KeyOBJ.SetCaps(On:boolean);
{}
begin
   If On then
      KeyStatusBits := (KeyStatusBits or $40)
   else
      KeyStatusBits := (KeyStatusBits and $BF);
end; {KeyOBJ.SetCaps}

procedure KeyOBJ.SetNum(On:boolean);
{}
begin
   If On then
      KeyStatusBits := (KeyStatusBits or $20)
   else
      KeyStatusBits := (KeyStatusBits and $DF);
end; {KeyOBJ.SetNum}

procedure KeyOBJ.SetScroll(On:boolean);
{}
begin
   If On then
      KeyStatusBits := (KeyStatusBits or $10)
   else
      KeyStatusBits := (KeyStatusBits and $EF);
end; {KeyOBJ.SetScroll}

function KeyOBJ.GetCaps:boolean;
{}
var CapsOnW : word;
begin
   CapsOnW := swap(KeyStatusBits);
   GetCaps := (CapsOnW and $4000) <> 0;
end; {KeyOBJ.GetCaps}

function KeyOBJ.GetNum:boolean;
{}
var NumOnW : word;
begin
   NumOnW := swap(KeyStatusBits);
   GetNum := (NumOnW and $2000) <> 0;
end; {KeyOBJ.GetNum}

function KeyOBJ.GetScroll:boolean;
{}
var ScrollOnW : word;
begin
   ScrollOnW := swap(KeyStatusBits);
   GetScroll := (ScrollOnW and $1000) <> 0;
end; {KeyOBJ.GetScroll}

procedure KeyOBJ.SetRepeatRate(Delay,Rate:byte);
{}
var Regs : registers;
begin
  with Regs do
  begin
     Ah := 3;
     Al := 5;
     Bl := Rate;
     Bh := pred(Delay);
     Intr($16,Regs);
  end;
end; {KeyOBJ.SetRepeatRate}

procedure KeyOBJ.SetFast;
{}
begin
   SetRepeatRate(1,0);
end; {KeyOBJ.SetFast}

procedure KeyOBJ.SetSlow;
{}
begin
   SetRepeatRate(2,$14);
end; {KeyOBJ.SetSlow}

procedure KeyOBJ.SetMouseMethod(Method:byte);
{}
begin
   if (Method in [1,2]) and Mouse.Installed then
   begin
      vMouseMethod := Method;
      vButtons := Mouse.GetButtons;
   end
   else
      vMouseMethod := 0;
end; {KeyOBJ.SetMouseMethod}

procedure KeyOBJ.SetHoriz(Sensitivity:byte);
{}
begin
   vHorizSensitivity := Sensitivity;
end; {KeyOBJ.SetHoriz}

procedure KeyOBJ.SetVert(Sensitivity:byte);
{}
begin
   vVertSensitivity := Sensitivity;
end; {KeyOBJ.SetHoriz}

procedure KeyOBJ.SetClick(On: boolean);
{}
begin
   vClick := On;
end; {KeyOBJ.SetClick}

procedure KeyOBJ.SetDouble(On:boolean);
{}
begin
   vWaitForDouble := On;
end; {KeyOBJ.SetDouble}

function KeyOBJ.GetDouble:boolean;
{}
begin
   GetDouble := vWaitForDouble;
end; {KeyOBJ.GetDouble}

procedure KeyOBJ.Click;
{}
begin
   Sound(1000);
   Sound(50);
   delay(5);
   nosound;
end; {KeyOBJ.Click}

procedure KeyOBJ.GetInput;
{waits for a keypress or mouse activity}
Const
   H = 40;
   V = 13;
   SlowDelay = 350;    {was 200}
   QwikDelay = 20;
   LastPress: longint = 0;
   ClockTicks = 18.2;
Var
   L,C,R : boolean;
   Action: boolean;
   Finished: boolean;
   ThisPress: Longint;
   Temp, TempX,TempY,X,Y: byte;
   Ch : char;
   KeyWord : word;
   InitDelay:word;
   LeftPresses, RightPresses, CenterPresses: word;
   ButtonCombinations: byte;

begin
   if vWaitForDouble then
      InitDelay := SlowDelay
   else
      InitDelay := 100;
   if vBufferHead <> vBufferTail then  {read from object buffer}
   begin
      Keyword := vBuffer[vBufferHead];
      if vBufferHead < StuffBufferSize then
         Inc(vBufferHead)
      else
         vBufferHead := 1;
   end
   else       {wait for keypress or mouse action}
   begin
      if vMouseMethod = 1 then
         Mouse.Move(H,V);
      Action := false;
      Finished := false;
      repeat
         vIdleHook;   {call the users idle hook procedure}
         if vMouseMethod > 0 then
         begin
            ThisPress := MemL[$40:$6C];   {get time}
            Keyword := 0;
            Mouse.Status(L,C,R,X,Y);
            if L or R or C then {a button is being depressed}
            begin
               Finished := true;
               { Next is the mouse speed up effect }
               if ((ThisPress - LastPress) / ClockTicks)*1000 > InitDelay+200 then
               begin
                  delay(InitDelay);          {check for double click}
                  LeftPresses := Mouse.Released(0,TempX,TempY);
                  RightPresses := Mouse.Released(1,TempX,TempY);
                  if vButtons > 2 then
                     CenterPresses := Mouse.Released(2,TempX,TempY)
                  else
                     CenterPresses := 0;
                  {Check for mouse combinations}
                  ButtonCombinations :=   ord(LeftPresses > 0)
                                        + 2*ord(RightPresses > 0)
                                        + 4*ord(CenterPresses > 0);
                  case ButtonCombinations of
                     1: Keyword := 513;  {left button}
                     2: Keyword := 514;  {right button}
                     3: Keyword := 516;  {left+right}
                     4: Keyword := 515;  {center button}
                     5: Keyword := 517;  {left+center}
                     6: Keyword := 518;  {center+right}
                     7: Keyword := 519;  {all three buttons}
                  end;
                  if LeftPresses > 1 then
                     Keyword := 523      {double left}
                  else if RightPresses > 1 then
                     Keyword := 524      {double right}
                  else if CenterPresses > 1 then
                     Keyword := 525;     {double center}
               end
               else
                  delay(QwikDelay);
               LastPress := ThisPress;
               If Keyword = 0 then
               begin
                  if L then
                     Keyword := 513
                  else
                    if R then
                       Keyword := 514
                    else
                       Keyword := 515;
               end;
            end;
            Temp := Mouse.Pressed(0,TempX,TempY);   {clear the mouse buffers}
            Temp := Mouse.Pressed(1,TempX,TempY);
            Temp := Mouse.Pressed(2,TempX,TempY);
            Temp := Mouse.Released(0,TempX,TempY);
            Temp := Mouse.Released(1,TempX,TempY);
            Temp := Mouse.Released(2,TempX,TempY);
            if vMouseMethod = 1 then
            begin
               Mouse.Location(X,Y);
               if Y - V > vVertSensitivity then
               begin
                  Keyword :=  584;   {mouse up}
                  Finished := true;
               end
               else if V - Y > vVertSensitivity then
               begin
                  Keyword :=  592;   {mouse down}
                  Finished := true;
               end
               else if X - H > vHorizSensitivity then
               begin
                  Keyword :=  589;   {mouse right}
                  Finished := true;
               end
               else if H - X > vHorizSensitivity then
               begin
                  Keyword :=  587;   {mouse left}
                  Finished := true;
               end
            end;
         end; {if}
         If KeyPressed or Finished then
            Action := true;
      until Action;
      if not finished then
      begin
        Ch := ReadKey;
        if Ch = #0 then
        begin
            Ch := Readkey;
            Keyword := 256+ord(Ch);
            if (KeyWord >= 327) and (Keyword <= 339) then
            begin
               if AltPressed then
                  inc(Keyword,80)
               else if ShiftPressed then
                  inc(Keyword,100)
               else if CtrlPressed then
                  inc(Keyword,120);
            end;
        end
        else
           KeyWord := ord(Ch);
      end;

   end;
   vPressedHook(Keyword);
   vLastKey := Keyword;
   vLastX := X;
   vLastY := Y;
   if vClick then
      Click;
end; {KeyOBJ.GetInput}

function KeyOBJ.Lastkey: word;
{}
begin
   LastKey := vLastKey;
end; {KeyOBJ.Lastkey}

function KeyOBJ.GetKey: word;
{}
begin
   GetInput;
   GetKey := vLastKey;
end; {KeyOBJ.GetKey}

function KeyOBJ.LastChar: char;
{}
begin
   if vLastKey < 256 then
      LastChar := chr(LastKey)
   else
      LastChar := #0;
end; {KeyOBJ.LastChar}

function KeyOBJ.LastX: byte;
{}
begin
   LastX := vLastX;
end; {KeyOBJ.LastX}

function KeyOBJ.LastY: byte;
{}
begin
   LastY := vLastY;
end; {KeyOBJ.LastY}

procedure KeyOBJ.FlushBuffer;
{}
var Regs: registers;
begin
   vBufferTail := VBufferHead; {empty program buffer}
   with Regs do
   begin
      Ax := ($0c shl 8) or 6;
      Dx := $00ff;
   end;
   Intr($21,Regs);
end; {KeyOBJ.FlushBuffer}

procedure KeyOBJ.StuffBuffer(W:word);
{adds word to program keyboard buffer}
begin
   if (vBufferTail + 1 = vBufferHead) 
   or ((vBufferTail = StuffBufferSize) and (vBufferHead = 1)) then
      exit; {buffer full}     
   vBuffer[vBufferTail] := W;
   if vBufferTail < StuffBufferSize then
      inc(vBufferTail)
   else
      vBufferTail := 1;
end; {KeyOBJ.StuffBuffer}

procedure KeyOBJ.StuffBufferStr(Str:string);
{}
var I,L : byte;
begin
   if Str <> '' then
   begin
      I := 1;
      L := length(Str);
      if L > StuffBufferSize then
         L := StuffBufferSize;
      while I <= L do
      begin
         StuffBuffer(ord(Str[I]));
         inc(I);
      end;
   end; 
end; {KeyOBJ.StuffBufferStr}

function KeyOBJ.Keypressed: boolean;
{}
begin
   KeyPressed := (CRT.Keypressed) or (vBufferTail <> vBufferHead);
end; {KeyOBJ.KeyPressed}

procedure KeyOBJ.DelayKey(Mills:longint);
{}
var
  EndTime: longint;
  Now: longint;

   procedure SetNull;
   begin
      vLastKey := 0;
      vLastX := 0;
      vLastY := 0;
   end;

begin
   if Mills <= 0 then
      SetNull
   else
   begin
      EndTime := MemL[$40:$6C] + trunc( (Mills/1000)*18.2);
      Repeat
         Now := MemL[$40:$6C];
      until Keypressed or (Now >= EndTime);
      if KeyPressed then
         GetInput
      else
         SetNull;
   end;
end; {KeyOBJ.DelayKey}

function KeyOBJ.AltPressed:boolean;
var
  AltW : word;
begin
   AltW := swap(KeyStatusBits);
   AltPressed := (AltW and $0800) <> 0;
end; {KeyOBJ.AltPressed}

function KeyOBJ.CtrlPressed:boolean;
var
  CtrlW : word;
begin
   CtrlW := swap(KeyStatusBits);
   CtrlPressed := (CtrlW and $0400) <> 0;
end; {KeyOBJ.CtrlPressed}

function KeyOBJ.LeftShiftPressed: boolean;
{}
var LSW : word;
begin
   LSW := swap(KeyStatusBits);
   LeftShiftPressed := (LSW and $0200) <> 0;
end; {LeftShiftPressed}

function KeyOBJ.RightShiftPressed: boolean;
{}
var RSW : word;
begin
   RSW := swap(KeyStatusBits);
   RightShiftPressed := (RSW and $0100) <> 0;
end; {RightShiftPressed}

function KeyOBJ.ShiftPressed: boolean;
{}
var SW : word;
begin
   SW := swap(KeyStatusBits);
   ShiftPressed := ((SW and $0200) <> 0) or ((SW and $0100) <> 0);
end; {ShiftPressed}

destructor KeyOBJ.Done;
{}
begin end; {of desc KeyOBJ.Done}
{|||||||||||||||||||||||||||||||||||||||||||||||}
{                                               }
{     U N I T   I N I T I A L I Z A T I O N     }
{                                               }
{|||||||||||||||||||||||||||||||||||||||||||||||}
procedure InputInit;
{initilizes objects and global variables}
begin
   new(AlphabetTOT,Init);
   Mouse.Init;
   Key.Init;
end;

{end of unit - add intialization routines below}
{$IFNDEF OVERLAY}
begin
   InputInit;
{$ENDIF}
end.
