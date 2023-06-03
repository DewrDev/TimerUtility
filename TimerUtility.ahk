#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent  
#SingleInstance off
SetBatchLines -1

global scriptver=1.2
formattime, Year,, yyyy ;
formattime, Date,, dd-MM-%year%
global LogDir:= A_appdata "\DewrDev\TimerUtility\" Date " TimerUtility.log"
if !(FileExist(logdir)){
    formattime, Date,, dd/MM/%year%
    FileAppend,
    (
    [Starting Log File for %Date%.]
    Welcome, Agent. 
    ),%logdir%
}
WriteLog("[TIMERUTILITY] - TimerUtility v" scriptVer " has been initialised")


FileCreateDir, %A_appdata%\DewrDev\TimerUtility
global AutoSaveFile:= A_appdata "\DewrDev\TimerUtility\Autosave.txt"
global DeletedResults:= A_appdata "\DewrDev\TimerUtility\deleted.txt"
; msgbox, %logdir%
global LoadType=Cold Load
global ColdLoadsBox
global SubLoadsBox
LoadType=Cold Load

Gui, Main:New,
Gui, add, groupbox, w65 h90 vCLoadsGroupBox, Cold Loads (0/3)
Gui, Add, Edit, wp-20 hp-30 xp+10 yp+20 -VScroll readonly 0x800000 vColdLoadsBox,

Gui, add, groupbox, w65 h170 xp-10 yp+70 vSLoadsGroupBox, Sub Loads (0/10)
Gui, Add, Edit, wp-20 hp-30 xp+10 yp+20 -VScroll readonly 0x800000 vSubLoadsBox,

Gui, add, Button,x+25 y+-25 gTime vtimingbutton default, Start timing `n(%LoadType%)
Gui, add, Button,x+25 y+-25 gSave vSaveBtn disabled, Save!
Gui, add, Button,x+25 y+-25 gClearTimes vCLEARBtn disabled, Clear
Gui, add, Button,x+25 y+-25 gDelLast vDelLastBtn disabled, Delete Last Result
Gui, add, Button,xp yp-25 gRestoreLast vRestoreLastBtn hidden, Restore Last Result

Gui, Font, s15
Gui, Add, Text,center y- x+-250, Current Load Time:
Gui, Font, s10
Gui, Add, Text,center  w150 yp+25 x+-160 vCurrentLoadTime, 0.00
Gui, Font, s9
gui, add, button,center w35 h35 y+-35 x+60 gHelp,?


global minutes1=
global updown1=
global updown2=
global seconds1=
global CntDownTxt = "Start"
global Cnttimertgl = 0

; ~~~~~~~ CUSTOM TIMER ~~~~~~~
Gui, add, groupbox, yp+100 xp-100 h80 w125,Countdown Timer
Gui, Add, Edit, w50 xp+13 yp+20 center vMinutes1 gUpdateCountdown,
IniRead, CustomTimerMinutes, %A_AppData%\DewrDev\TimerUtility\Default.ini, CustomTimer, TimerMinutes,5
IniRead, CustomTimerSeconds, %A_AppData%\DewrDev\TimerUtility\Default.ini, CustomTimer, TimerSeconds,0
Gui, add, UpDown,range0-60 vupdown1, % (CustomTimerMinutes+CustomTimerSeconds) ? CustomTimerMinutes : 5
Gui, Add, Edit, w50 xp+50 center vSeconds1 gUpdateCountdown,
Gui, add, UpDown,range0-60 vupdown2, % (CustomTimerMinutes+CustomTimerSeconds) ? CustomTimerSeconds : 0
Gui, Add, Button,yp+25 xp-50 gRunCustomTimer vCountdownBtn, Start 5 minute Timer
gui, font, s20, bold
Gui, Add, text, yp-30 xp+0 w100 center hidden vTimerText,
gui, font
; ~~~~~~~ other shit mate ~~~~~~~

gui, show,,
Control, style,^0x800000,Edit2,%A_ScriptName%
WinSet, redraw,,%A_ScriptName%

global Timing=0
global start=0
global Ticks=0
Global Seconds=0
Global Milliseconds=0
Global ColdLoads
Global ColdLoadsCount=0
Global SubLoadsCount=0
Global SubLoads
Global Mode=1
global TimeString=
global minutesRaw=
global secondsraw=
global LoadType="Cold Load"
global ColdArr := Array()
global SubArr := Array()
global lastMode
global UnsavedTimes=0
global help=0
global timersecs
global TimerMins
global ModeHistory:= Array()
global flipit=1
global flipem=0
global imported=0
global ImportLocation
global importmode = 0
global Retries=0
global StartMins, StartSecs
; help()

OnExit("CheckChanges")
OnExit(ObjBindMethod(MyObject, "Exiting"))

IniRead, IniUnsavedTimes, %A_AppData%\DewrDev\TimerUtility\Default.ini, Default, UnsavedTimes
if (IniUnsavedTimes = 1) {
    import(1)
}

if !(FileExist(A_appdata "\Microsoft\Windows\Start Menu\Programs\DewrDev\TimerUtility.lnk")){
    WriteLog("[SCRIPT] - Start Menu Shortcut not present. Creating one in dir " A_appdata "\Microsoft\Windows\Start Menu\Programs\DewrDev\")
    FileCreateDir, %A_appdata%\Microsoft\Windows\Start Menu\Programs\DewrDev\
    FileCreateShortcut, %A_ScriptFullPath%, %A_appdata%\Microsoft\Windows\Start Menu\Programs\DewrDev\TimerUtility.lnk, %A_Scriptdir%,,TimerUtility,,,
}

Hotkey, $Space , SpaceBar, Options

WriteLog("[TIMERUTILITY] - TimerUtility v" scriptVer " load complete")
return

Spacebar() {
    writelog("[BUTTON] - Spacebar pressed")
    WinGetActiveTitle, hello
    if (hello = A_ScriptName){
        writelog("Spacebar Pressed, running timer")
        Time()
        GuiControl, main:Text, ColdLoadsBox, %ColdLoads%
        GuiControl, main:Text, SubLoadsBox, %Subloads%
        Guicontrol, main:Text, SLoadsGroupBox, Sub Loads (%SubLoadsCount%/10)
        Guicontrol, main:Text, CLoadsGroupBox, Cold Loads (%ColdLoadsCount%/3)
    }else {
        writelog("Spacebar pressed but window not active. Sending Space input instead.")
        send, {space}
        return
    }
return
}

UpdateCountdown(reset){
    if (reset != 1){
        GuiControlGet, TimerMins,, Minutes1
        GuiControlGet, TimerSecs,, Seconds1
    }
    if (TimerSecs != 0){
        GuiControl, Text, CountdownBtn , %CntDownTxt% %TimerMins%m  %TimerSecs%s timer

    }else {
        GuiControl, Text, CountdownBtn , %CntDownTxt% %TimerMins% minute timer
    }
return
}

$~^c::
; writelog("[HOTKEY] - CTRL-C PRESSED")
; copyall()
return

CopyAll(){
    WinGetActiveTitle,oOoTitle
    if (oOoTitle = A_ScriptName){
        writelog("[COPY] - Window Title = " oOoTitle)
        Thread, Priority, critical
        SetTimer, ChangeMsgBox, 100
        msgbox, 1,Copy Results, 
        ifmsgbox, Cancel 
        {
            return
        }

        ControlGetText, Colds, Edit1,%A_ScriptName%
        ControlGetText, Subs, Edit2,%A_ScriptName%
        AllTimes:= Colds "`n`n" Subs
        Clipboard := AllTimes
        writelog("[COPY] - New Clipboard Contents: " Clipboard)
    }
}

ChangeMsgBox:
    winwait, Copy Results
    ; WinMove,,, , , 300,,
    ControlSetText, Button1, Copy ALL, Copy Results
    ControlSetText, Button2, Copy Selected, Copy Results
    ; Guicontrol, moveDraw, ahk_class %class%,


    SetTimer, ChangeMsgBox, off
return



Time(){
    writelog("Timer button pressed")
    Guicontrol,hide,RestoreLastBtn
    if (%Timing%=0){
        ToggleButtons("disable")
        if (ColdLoadsCount + SubLoadsCount = 13){
            Suspend, toggle
            writelog("Cold Loads + Sub Loads fully populated. Doing nothing.")
            SoundPlay, %A_WinDir%\Media\Windows Background.wav
            msgbox,,, Cold & Sub Loads complete!
            Suspend, toggle
            return
        }
        UnsavedTimes=1
        writelog("[VAR] - UnsavedTimes="UnsavedTimes)
        timing = 1
        GuiControl, main:Text, timingbutton, Stop timing `n(%LoadType%)
        start:=A_TickCount
        SetTimer,Ting, 1
        writelog("starting tickcount: " start)
        return
    }else {
        SetTimer,Ting, off
        Timing=0
        ToggleButtons("enable")
        writelog("TickCount at the time of thing: " ticks)
        if (Mode = 1) {
            ColdLoads()
            Autosave()
        }else if (Mode = 0) {
            SubLoads()
            Autosave()
                }
        GuiControl, main:Text, timingbutton, Start timing `n(%LoadType%)
    }
Return
}

ColdLoads() {
    writelog("Cold Load ting")
    if (ColdLoadsCount=0) {
            ColdLoads = %TimeString%
            ColdLoadsCount:= ++ColdLoadsCount
            Guicontrol, main:Text, CLoadsGroupBox, Cold Loads (%ColdLoadsCount%/3)
            GuiControl, main:Text, ColdLoadsBox,%ColdLoads%
    }else if (ColdLoadsCount <= 2 ) {
        ColdLoads = %ColdLoads%`n%TimeString%
        GuiControl, main:Text,ColdLoadsBox, %ColdLoads%
        ColdLoadsCount:= ++ColdLoadsCount
        Guicontrol, main:Text, CLoadsGroupBox, Cold Loads (%ColdLoadsCount%/3)
        if (ColdLoadsCount = 3) {
            LoadType=Sub Load
            GuiControl, main:Text, timingbutton, Start timing `n(%LoadType%)
        }
    }else {
        SubLoads()
        Mode = 0
        LoadType=Sub Load
        return
    }
    ColdArr.Push(Timestring)
    ModeHistory.Push(1)
    CheckLoadCount()
    ToggleButtons("enable")
}

SubLoads(){
    writelog("Sub Load ting")
    if (SubLoadsCount=0){
        SubLoads = %TimeString%
        GuiControl, main:Text,SubLoadsBox,%SubLoads%
        SubLoadsCount:= ++SubLoadsCount
        Guicontrol, main:Text, SLoadsGroupBox, Sub Loads (%SubLoadsCount%/10)
    }else if !(SubLoadsCount = 10) {
        SubLoads = %SubLoads%`n%TimeString%
        GuiControl, main:Text,SubLoadsBox,%SubLoads%
        SubLoadsCount:= ++SubLoadsCount
        Guicontrol, main:Text, SLoadsGroupBox, Sub Loads (%SubLoadsCount%/10)
     }
     SubArr.Push(Timestring)
     ModeHistory.Push(0)
     CheckLoadCount()
     ToggleButtons("enable")
}

CheckLoadCount(){
    if (ColdLoadsCount + SubLoadsCount = 13){
    Guicontrol,main:disable,timingbutton
    return
    }else {
        Guicontrol,main:enable,timingbutton
    }
}

Ting:
    Ticks:=A_TickCount - start
    Seconds = % ticks / 1000
    Milliseconds = % Ticks / 1000000
    StringTrimRight, Seconds, Seconds, 7
    StringTrimLeft, Milliseconds, Milliseconds, 5
    StringTrimRight, Milliseconds, Milliseconds, 1

    TimeString = %Seconds%.%Milliseconds%

    ; INSERT MATH SHIT HERE!!
    GuiControl, main:Text, CurrentLoadTime, %TimeString%
return

~^Numpad2::
if !(A_IsCompiled = 1){
    reload
}
return

Autosave() {
    ; FileRead, MyContents, %autosavefile%
    file := FileOpen(autosavefile, "w") 
    file.close() 
    ControlGetText, Colds, Edit1,%A_ScriptName%
    ; StringTrimRight, Colds, Colds, 1
    ControlGetText, Subs, Edit2,%A_ScriptName%
    if (strlen(subs)=0){
        timestring:= Colds
    }else {
        Timestring:= Colds "`n`n" Subs
    }
    ; if (Mode = 1 && coldloadscount = 3){
    ;     Timestring:= Timestring "`n"
    ; }
    FileAppend,
    (
        %TimeString%
    ), %AutoSaveFile%
    if (errorlevel = 1){
        if (retries=3 & errorlevel=1){
            writelog("[ERROR] - The Autosave error has occurred 3 times!!!")
            return
        }
        Retries:= ++Retries
        writelog("[ERROR] - There has been an error with the Autosave. Attempting again.")
        Autosave()
    }
    return
}

Save(){
    DialogueDir:= A_Desktop "\Load Times.txt"
    suspend, toggle
    if (imported = 1){
        DialogueDir:= ImportLocation
    }

    FileSelectFile, SaveLocation , S, %DialogueDir%, Save Load Times!, *.txt
    FileAppend, 
    (
%ColdLoads%

%SubLoads%
    ), %SaveLocation%

    UnsavedTimes=0
    writelog("[VAR] - UnsavedTimes="UnsavedTimes)
    FileDelete, %Autosavefile%
    suspend, toggle
    ; hotkey, Space, on
    return
}

RunCustomTimer(){
    writelog("[BUTTON] - Custom Timer button pressed.")
    if (Cnttimertgl = 0){
        Cnttimertgl = 1
        ToggleTimerBtns()
        GuiControlGet, TimerMins,, Minutes1
        GuiControlGet, TimerSecs,, Seconds1
        writelog("[TIMER] - Minutes: " TimerMins ", Seconds: " TimerSecs)
        global StartMins:= TimerMins, StartSecs:= TimerSecs
        if (StrLen(TimerSecs) != 2){
            Timersecs:= 0 Timersecs
        }
        global CntDownTxt = "Stop"
        Guicontrol, main:text, TimerText, % timermins ":" Timersecs 
        SetTimer, CustomTimer, 1000, on
    }else{
        Cnttimertgl = 0
        global CntDownTxt = "Start"
        SetTimer, CustomTimer,Delete
        global TimerMins = StartMins
        global TimerSecs = StartSecs
        guicontrol, main:text, minutes1, %StartMins%
        guicontrol, main:text, seconds1, %StartSecs%
        ToggleTimerBtns()
        UpdateCountdown(1)
    }
return
}

ToggleTimerBtns(){
    gui, main:default
    flipfloop := {1: "Hide", 0: "Show"}
        GuiControl, % flipfloop[flipit], minutes1
        GuiControl, % flipfloop[flipit], seconds1
        GuiControl, % flipfloop[flipit], updown1
        GuiControl, % flipfloop[flipit], updown2
        Guicontrol, % flipfloop[flipem], TimerText
        flipit:= !flipit
        flipem:= !flipem
}

CustomTimer:
    if (TimerSecs != 0){
        --TimerSecs
    }else if (TimerMins != 0){
        --TimerMins
        TimerSecs = 59
    }else {
        SetTimer, CustomTimer, delete ;Stop the timer
        SoundPlay, %A_WinDir%\Media\Alarm09.wav
        TrayTip , Timer Custom Timer, Your %StartMins% minute timer is complete,, 0x10
        ; ToggleTimerBtns()
        ; RunCustomTimer()
        return
    }
    if (StrLen(TimerSecs) != 2){
        Timersecs:= 0 Timersecs
    }
GuiControl, main:Text, Minutes1, %TimerMins%
GuiControl, main:Text, Seconds1, %TimerSecs%
Guicontrol, main:text, TimerText, % Timermins ":" Timersecs
return

ShowLogs:
; Run %ComSpec% /c explorer.exe %A_appdata%"\Dewrdev\Timerutility",,hide
run, %A_WinDir%\explorer.exe %A_appdata%"\Dewrdev\Timerutility"
return

Cleartimes(){
    ClearMsg:= {1:"You have unsaved Load Times`nAre you sure you wish to Clear them?" , 0: "Load Times have been saved.`nClear Load Times?"}
    writelog("[BUTTON] - Clear Button pressed")
        writelog("[ClearTimes] - Offering ")
        Suspend, toggle
        MsgBox, 4,Clear Confirmation,% ClearMsg[UnsavedTimes],
        ifmsgbox, no 
            {
                Suspend, toggle
                ; hotkey, space, on
                return
            }
        ColdLoadsCount=0
        SubLoadsCount=0
        ColdArr:= array()
        subarr:= array()
        coldloads=
        subloads=
        mode=1
        imported=0
        LoadType=Cold Load
        GuiControl, main:Text, timingbutton, Start timing `n(%LoadType%)
        GuiControl,, ColdLoadsBox,
        GuiControl,, SubLoadsBox,
        Guicontrol, Text, CLoadsGroupBox, Cold Loads (%ColdLoadsCount%/3)
        Guicontrol, Text, SLoadsGroupBox, Sub Loads (%SubLoadsCount%/10)
        Guicontrol, Text, CurrentLoadTime, 0.00
        Guicontrol,enable,timingbutton
        ToggleButtons("disable")
        FileDelete, %Autosavefile%
        FileDelete, %DeletedResults%
        suspend, toggle
        hotkey, space, on
        UnsavedTimes=0
        return
}

ToggleSpace(){
    Suspend, toggle 
    return
}

DelLast:
    Modes := {1: "cold", 0: "sub"}
    ModeArrs := {1: Coldarr, 0: Subarr}
    ModeHistoryLen:= Modehistory.length()
    LastMode:= ModeHistory[ModeHistoryLen]
    txt= % Modes[Lastmode]
    lastLoadarr:= % ModeArrs[LastMode] ; REMEMBER THIS IS WORKING CORRECTLY, STOP LOOKING AT IT!!
    LastLoad:= LastLoadArr[%txt%LoadsCount]
    Suspend, toggle
    msgbox, 4, Delete Last Result?, Are you sure you want to delete last %txt% load: %LastLoad% ?
    ifmsgbox, no 
        {
            Suspend, toggle 
            return
        }
    if (LastMode=1){
        len := ColdArr.pop()
        DeletedResult:=Len
        DeletedMode=1
        len := strlen(len)
        ++len
        StringTrimRight, ColdLoads, ColdLoads, %len%
        GuiControl, main:Text, Edit1, %ColdLoads%
        --ColdLoadsCount
        Guicontrol, Text, CLoadsGroupBox, Cold Loads (%ColdLoadsCount%/3)
    }else{
        len := SubArr.pop()
        DeletedResult:=Len
        DeletedMode=0
        len := strlen(len)
        ++len
        StringTrimRight, SubLoads, SubLoads, %len%
        ; msgbox, %SubLoads%
        GuiControl, main:Text, Edit2, %SubLoads%
        --SubLoadsCount
        Guicontrol, Text, SLoadsGroupBox, Sub Loads (%SubLoadsCount%/10)
    }
    Modehistory.pop()
    Guicontrol,enable,timingbutton
    GuiControl, Text, CurrentLoadTime, 0.00
    Suspend, toggle
    if (ColdLoadsCount + SubLoadsCount = 0){
        ToggleButtons("disable")
    }
    writelog("[DELETE] - " txt " load deleted: " LastLoad)
    FileAppend,
    (
        %txt% load: %LastLoad%

    ), %DeletedResults%
    Autosave()
    Guicontrol,show,RestoreLastBtn
return

RestoreLast:
TimeString:=DeletedResult
if (DeletedMode=1)
{
    writelog("Restoring result " TimeString " Into the Cold Loads box" )
    ColdLoads()
    ; ColdArr.push(DeletedResult)
}Else
{
    writelog("Restoring result " TimeString " Into the Sub Loads box" )
    SubLoads()
}
Guicontrol,hide,RestoreLastBtn
return

ToggleButtons(mode){
    Guicontrol,main:%mode%,DelLastBtn
    Guicontrol,main:%mode%,SaveBtn
    Guicontrol,main:%mode%,CLEARBtn
}

WriteLog(LogText){
    formattime, TimeNow,, HH:mm:ss:%A_msec% ;
    FileAppend,`n[%TimeNow%] - %LogText%, %LogDir%
}

~LButton::
    MouseGetPos,,, MouseWinID, MouseHover, 1
    WinGetTitle, winName, ahk_id %MouseWinID%
    if (WinName = A_ScriptName) {
            ; msgbox, %MouseHover%
        if (MouseHover = "Edit1" AND mode NOT = 1){
            Control, style,^0x800000,Edit1,%A_ScriptName%
            Control, style,^0x800000,Edit2,%A_ScriptName%
            WinSet, redraw,,%A_ScriptName%
            LoadType=Cold Load
            GuiControl, main:Text, timingbutton, Start timing `n(%LoadType%)
            mode=1
        }else if (MouseHover = "Edit2" AND mode NOT = 0){
            Control, style,^0x800000,Edit1,%A_ScriptName%
            Control, style,^0x800000,Edit2,%A_ScriptName%
            WinSet, redraw,,%A_ScriptName%
            LoadType=Sub Load

            GuiControl, main:Text, timingbutton, Start timing `n(%LoadType%)
            mode=0
        }
    }
return

~^S::
WinGetActiveTitle,oOoTitle
    if (oOoTitle = A_ScriptName){
        save()
    }
return

checkchanges(ExitReason, ExitCode){
    writelog("[EXIT] - Exit signal received")
    writelog("[EXIT] - Are there un-saved results=" UnsavedTimes ? "true" : "false")
    if (Timing = 1 OR Cnttimertgl=1){
        return 1
    }
    if ExitReason not in logoff, Shutdown
        if (UnsavedTimes=1){
            suspend, toggle
            MsgBox, 4,EXIT Confirmation, You have unsaved Load Times`nAre you sure you wish to exit?
            ifmsgbox, No
                {
                    writelog("[EXIT] - User pressed NO on Msgbox")
                    Suspend, toggle
                    return 1
                }
            }
        }

class MyObject
{
    Exiting(){
        formattime, Year,, yyyy ;
        formattime, Date,, dd-MM-%year%
        IniWrite, %UnsavedTimes%, %A_AppData%\DewrDev\TimerUtility\Default.ini, Default, UnsavedTimes
        GuiControlGet, CustomTimerMinutes ,Main:, updown1
        IniWrite, %CustomTimerMinutes%, %A_AppData%\DewrDev\TimerUtility\Default.ini, CustomTimer, TimerMinutes
        GuiControlGet, CustomTimerSeconds ,Main:, updown2
        IniWrite, %CustomTimerSeconds%, %A_AppData%\DewrDev\TimerUtility\Default.ini, CustomTimer, TimerSeconds
        writelog("[SCRIPT] - EXITING")
    }
}
return

mainguiClose:
ExitApp

help(){
    if (help=0){
        global width
        WinGetPos, , , Width, Height, %A_ScriptName%
        ; msgbox, "width before" %width%
        width2:= width + 180
        height:= height - 50
        height2:= height-15
        gui, main:show,W%width2%,
        help=1
        gui, Help: new,MinimizeBox -border -disabled -Maximizebox +parentmain,
        gui, add, GroupBox,h%Height2% w160, Help Pages - TimerUtility v%scriptver%
        gui, add, text,xp+5 yp+25, >Click the boxes on the left to `nselect your Load Type
        gui, add, text,xp+0 yp+35, >CTRL+S to Save
        gui, add, text,xp+0 yp+25, >Press CLEAR to clear results
        gui, add, text,xp+0 yp+25, >Press SPACE on this window `nto start/stop timing
        gui, add, text,xp+0 yp+35, >CTRL+C to copy results to `nclipboard.
        gui, add, button, x+-23 y+42 gShowLogs, Debug
        gui, add, button, xp-115 yp0 gImport, Import
        gui, show,NoActivate h%height% w180 x+425 y+5, Help
    return
    }
    help=0
    gui, Help:destroy
    ReturnWidth:= width-6
    gui, main:show,W%ReturnWidth%,
    ; msgbox, "width after" %width%
    return
}

import(importmode=0){
    suspend, toggle
    if (ColdLoadsCount + SubLoadsCount != 0 OR UnsavedTimes=1){
        msgbox, 1, Import Confirmation, You already have load times. Are you sure you wisht overwrite them?
        ifmsgbox, Cancel 
        {
            suspend, toggle
            return 
        }
    }
    ToggleButtons("disable")
    ColdArr:= Array()
    ColdLoadsCount=0
    subarr:= Array()
    SubLoadsCount=0
    guicontrol, main:text, coldloadsbox, 
    guicontrol, main:text, subloadsbox, 
    guicontrol, main:text, CLoadsGroupBox, Cold Loads (0/3)
    guicontrol, main:text, SLoadsGroupBox, Sub Loads (0/10)
    ImportLocation=0
    writelog(importmode)
    if !(Importmode = 1){
        FileSelectFile, ImportLocation ,, %A_Desktop%\, Import Load Times
    }else{
        ImportLocation:= AutoSaveFile
        importmode = 0
    }
    FileRead, ImportedTimes, %ImportLocation%
    loop, parse,ImportedTimes,`n,
    {
        Timestring:= A_LoopField
        if (strlen(A_LoopField) != 0){
            ColdLoads()
        }
    }
    UnsavedTimes=0
    writelog("[VAR] - UnsavedTimes="UnsavedTimes)
    global imported=0
    suspend, toggle
}
return