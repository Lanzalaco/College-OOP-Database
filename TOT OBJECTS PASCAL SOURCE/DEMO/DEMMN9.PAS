program DemoMenuNine;
{DEMMN9 - using a EZPull object with sub menus and hotkeys}
USES  DOS, CRT,
      totMENU, totFAST;

var
  Env,Watch: MenuOBJ;
  Menu: EZPullArrayOBJ;
  Choice: word;

procedure CreateSubMenus;
{}
begin
   with Env do 
   begin
      Init;
      SetForPull;
      AddFullItem(' ~P~references... ',8061,80,'Specify desktop settings',nil);
      AddFullItem(' ~E~ditor...      ',8062,69,'Specify editor settings',nil);
      AddFullItem(' ~M~ouse...       ',8063,77,'Specify mouse settings',nil);
      AddFullItem(' ~S~tartup...     ',8064,83,'Permanently change default startup options',nil);
      AddFullItem(' ~C~olors...      ',8065,67,'Customize IDE colors for windows, menus, etc.',nil);
   end;
   with Watch do
   begin
      Init;
      SetForPull;
      AddFullItem(' ~A~dd watch...       ',7021,65,'Insert a watch expression into the Watch window',nil);
      AddFullItem(' ~D~elete watch       ',7022,68,'Remove the current watch expression from the Watch window',nil);
      AddFullItem(' ~E~dit watch...      ',7023,69,'Edit the current watch expression in the Watch window',nil);
      AddFullItem(' ~R~emove all watches ',7024,82,'Delete all watch expressions from the Watch window',nil);
   end;
end; {CreateSubMenus}

procedure CreateMenu;
{}
var
  Mtxt: Array[1..84] of string[100];
begin
   MTxt[1] := '\ � "System Commands';
   MTxt[2] := ' ~A~bout...        "Show version and copyright information"100';
   MTxt[3] := ' ~R~efresh display "Redraw the screen"101';
   MTxt[4] := ' ~C~lear desktop   "Close all windows on the desktop, clear history lists"102';
   MTxt[5] := '\ ~F~ile "File management commands (Open, New, Save, etc.)';
   MTxt[6] := ' ~O~pen...   F3  "Locate and open a file in an edit window"201"317';
   MTxt[7] := ' ~N~ew           "Create a new file in a new Edit window"202';
   MTxt[8] := ' ~S~ave      F2  "Save the file in the active Edit window"203"316';
   MTxt[9] := ' S~a~ve as...    "Save the current file under a different name"204';
   MTxt[10] := ' Save a~l~l      "Save all modified files"205';
   MTxt[11] := '-';
   MTxt[12] := ' ~C~hange dir... "Choose a new default directory"206';
   MTxt[13] := ' ~P~rint         "Print the contents of the active Edit window"207';
   MTxt[14] := ' ~G~et info...   "Show status information"208';
   MTxt[15] := ' ~D~OS shell     "Temporarily exit to DOS"209';
   MTxt[16] := ' E~x~it          "Exit Turbo Pascal"9999';
   MTxt[17] := '\ ~E~dit "Cut-and-paste editing commands"';
   MTxt[18] := '_ ~R~estore line     "Cancel edits to the current line in active Edit window"301';
   MTxt[19] := '-';
   MTxt[20] := '_ Cu~t~    Shift-Del "Remove the selected text and put it in the Clipboard"302';
   MTxt[21] := '_ ~C~opy    Ctrl-Ins "Copy the selected text into the Clipboard"303"9999';
   MTxt[22] := '_ ~P~aste  Shift-Ins "Insert selected text from the Clipboard"304"291';
   MTxt[23] := '_ Copy e~x~ample     "Copy example from the Help window into the ClipBoard"305';
   MTxt[24] := ' ~S~how clipboard   "Open the Clipboard window"306';
   MTxt[25] := '-';
   MTxt[26] := '_ C~l~ear   Ctrl-Del "Delete the selected text"307"262';
   MTxt[27] := '\ ~S~earch "Text and error search commands';
   MTxt[28] := ' ~F~ind...             "Search for text"401';
   MTxt[29] := ' ~R~eplace...          "Search for text and replace it with new text"402';
   MTxt[30] := ' ~S~earch again        "Repeat the last Find or Replace command"403';
   MTxt[31] := ' ~G~oto line number... "Move the cursor to a specified line number"404';
   MTxt[32] := ' ~F~ind procedure...   "Search for a procedure or function while debugging"405';
   MTxt[33] := ' Find e~r~ror...       "Move the cursor to the position of a runtime error"406';
   MTxt[34] := '\ ~R~un "Execute or single-step through a program';
   MTxt[35] := ' ~R~un            Ctrl-F9 "Run the current program"501"358';
   MTxt[36] := '_ ~P~rogram reset  Ctrl-F2 "Halt debugging session and release memory"502"351';
   MTxt[37] := ' ~G~o to cursor        F4 "Run program from the run bar to the cursor position"503"318';
   MTxt[38] := ' ~T~race into          F7 "Execute next statement, stopping within the current proc"504"321';
   MTxt[39] := ' ~S~tep over           F8 "Execute next statement, skipping over the current proc"505"322';
   MTxt[40] := ' P~a~rameters...          "Set command line parameters to be passed to the program"506';
   MTxt[41] := '\ ~C~ompile "Compile to disk or memory';
   MTxt[42] := ' ~C~ompile  Alt-F9 "Compile source file"601"368';
   MTxt[43] := ' ~M~ake         F9 "Rebuild source file and all modified files"602"323';
   MTxt[44] := ' ~B~uild           "Rebuild source file and all files"603';
   MTxt[45] := ' ~D~estination     "Specify whether file is compiled to memory or disk"604';
   MTxt[46] := ' ~P~rimary file... "Define the file that is the focus of make and Build"605';
   MTxt[47] := '\ ~D~ebug "Evaluate expressions, modify data, set breakpoints and watches';
   MTxt[48] := ' ~E~valute/modify...  Ctrl-F4 "Evaluate a variable or expression and display or modify the value"701"353';
   MTxt[49] := ' ~W~atches                   "Add, delete and edit expressions in the watch window"702';
   MTxt[50] := ' ~T~oggle breakpoint  Ctrl-F8 "Set or clear an unconditional breakpoint at the cursor position"703"357';
   MTxt[51] := ' ~B~reakpoints...    "Set conditional breakpoints, view and edit breakpoints"704';
   MTxt[52] := '\ ~O~ptions "Set defaults for compiler, editor, mouse, debugger, etc.';
   MTxt[53] := ' ~C~ompiler            "Set default compiler directives and condl. defines"801';
   MTxt[54] := ' ~M~emory sizes...     "Set default stack and heap sizes for generated programs"802';
   MTxt[55] := ' ~L~inker...           "Set linker options"803';
   MTxt[56] := ' De~b~ugger...         "Set debugger options"804';
   MTxt[57] := ' ~D~irectories...      "Set paths for units, include files, OBJs anfd generated files"805';
   MTxt[58] := '-';
   MTxt[59] := ' ~E~nvironment        "Specify environment settings"806';
   MTxt[60] := '-';
   MTxt[61] := ' ~S~ave options...     "Save all the settings you''ve made in the Options menu"807';
   MTxt[62] := ' ~R~etrieve options... "Load options file previously created with Save Options"808';
   MTxt[63] := '\ ~W~indow "Open, arrange, and list windows';
   MTxt[64] := ' ~S~ize/Move   Ctrl-F5 "Change the size or position of the active window"901"354';  
   MTxt[65] := ' ~Z~oom             F5 "Enlarge or restore the size of the active window"902"319';
   MTxt[66] := ' ~T~ile                "Arrange windows on desktop by tiling"903';
   MTxt[67] := ' C~a~scade             "Arrange windows on desktop by cascading"904';
   MTxt[68] := ' ~N~ext             F6 "Make the next window active"905"320';
   MTxt[69] := ' ~P~revious   Shift-F6 "Make the previous window active"906"345';
   MTxt[70] := ' ~C~lose        Alt-F3 "Close the active window"907"362';
   MTxt[71] := '-';
   MTxt[72] := ' ~W~atch               "Open the watch window"908';
   MTxt[73] := ' ~R~egister            "Open the Register window"909';
   MTxt[74] := ' ~O~utput              "Open the Output window"910';
   MTxt[75] := ' Call stac~k~  Ctrl-F3 "Show the procedures the program called to reach this point"911"352';
   MTxt[76] := ' ~U~ser screen  Alt-F5 "Switch to the full-screen user output"912"364';
   MTxt[77] := '-';
   MTxt[78] := ' ~L~ist...       Alt-0 "Show a list of all open windows"913"385';
   MTxt[79] := '\ ~H~elp "Get online help';
   MTxt[80] := ' ~C~ontents               "Show table of contents of online Help"1001';
   MTxt[81] := ' ~I~ndex         Shift-F1 "Show index for online Help"1002"340';
   MTxt[82] := ' ~T~opic Search   Ctrl-F1 "Display help on the word at the cursor"1003"350';
   MTxt[83] := ' ~P~revious Topic  Alt-F1 "Redisplay the last-viewed online Help screen"1004"360';
   MTxt[84] := ' ~H~elp on Help           "How to use online Help"1005';
   with Menu do
   begin
      Init;
      AssignList(MTxt,84,100);
   end;
end; {CreateMenu}

begin
   Screen.PartClear(1,2,80,24,white,'�'); {paint the screen}
   Screen.PartClear(1,1,80,1,31,' ');
   Screen.PartClear(1,25,80,25,31,' ');
   Screen.WritePlain(9,25,'�');
   CreateMenu;
   CreateSubMenus;
   with Menu do
   begin
      SubMenu(7)^.SetSubMenu(2,@Watch);
      SubMenu(8)^.SetSubMenu(7,@Env);
      Choice := Push(289,0,0);   {Pass Alt-F to make menu pull down on File}
      Done;
      Env.Done;
      Watch.Done;
   end;
   GotoXY(25,15);
   if Choice = 0 then
      Writeln('You escaped')
   else
      Writeln('You selected menu item ',Choice);
end.