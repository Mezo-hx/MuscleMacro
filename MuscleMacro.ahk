#Persistent

; Global variables
global startHotkey := ""
global stopHotkey := ""
global debugHotkey := "^d"  ; Ctrl + D for debug
global startTime := 0
global clicking := false
global restartDelay := 10 ; 10 seconds
global clickDuration := 5 ; 5 seconds
global checkInterval := 10 ; 10 minutes
global foodImages := []
global foodPriorities := []
global clickOnce := false
global exerciseType := "PushUp" ; Default to "PushUp"

; GUI
Gui, Add, Text,, Activation Key:
Gui, Add, Hotkey, vStartHotkey w100
Gui, Add, Text,, Stop Key:
Gui, Add, Hotkey, vStopHotkey w100
Gui, Add, Text,, Rest Duration (s):
Gui, Add, Edit, vRestartDelayEdit w50, %restartDelay%
Gui, Add, Text,, Click Duration (s):
Gui, Add, Edit, vClickDurationEdit w50, %clickDuration%
Gui, Add, Text,, FoodCheck Interval (min):
Gui, Add, Edit, vCheckIntervalEdit w50, %checkInterval%
Gui, Add, Text,, Select Exercise Type:
Gui, Add, Radio, vExerciseTypePushUp gSelectPushUp, PushUp
Gui, Add, Radio, vExerciseTypeSitUp gSelectSitUp, Situp
Gui, Add, Button, gSaveHotkeys, Save Settings
Gui, Show,, GD - Muscle Macro

Loop, Files, bin/foods\*.png
{
    foodImages.Push(A_LoopFileFullPath)
    fileName := SubStr(A_LoopFileName, 1, -4)
    Gui, Add, Text,, % "Priority for " fileName ":"
    Gui, Add, Edit, vFoodPriority%fileName% w50, 1
}

Gui, Show

scriptRunning := false

return

SelectPushUp:
GuiControl,, ExerciseTypePushUp, 1
exerciseType := "PushUp"
return

SelectSitUp:
GuiControl,, ExerciseTypeSitUp, 1
exerciseType := "Situp"
return

SaveHotkeys:
Gui, Submit, NoHide
startHotkey := StartHotkey
stopHotkey := StopHotkey
restartDelay := RestartDelayEdit * 1000
clickDuration := ClickDurationEdit
checkInterval := CheckIntervalEdit * 60000

foodPriorities := []
Loop, % foodImages.MaxIndex()
{
    fileName := SubStr(foodImages[A_Index], InStr(foodImages[A_Index], "\", 0, 0) + 1)
    fileName := SubStr(fileName, 1, -4)
    Gui, Submit, NoHide
    foodPriorities.Push({name: foodImages[A_Index], priority: FoodPriority%fileName%})
}

foodPriorities.Sort("SortByPriority")

Hotkey, %startHotkey%, StartScript
Hotkey, %stopHotkey%, StopScript
Hotkey, %debugHotkey%, DebugFunction
MsgBox, Settings saved! Start: %startHotkey% Stop: %stopHotkey% Restart Delay: %restartDelay% ms Click Duration: %clickDuration% s Check Interval: %checkInterval% min Exercise: %exerciseType%
return

StartScript:
if (scriptRunning)
    return
scriptRunning := true
clickOnce := false
SetTimer, CheckFoodImages, %checkInterval%
SetTimer, Clicker, 10

ImageSearch, xPosition, yPosition, 0, 0, A_ScreenWidth, A_ScreenHeight, *0 %exerciseType%.png
if (!ErrorLevel) {
    Click, %xPosition%, %yPosition%
    clicking := true
    startTime := A_TickCount
}

return

StopScript:
if (!scriptRunning)
    return
scriptRunning := false
SetTimer, Clicker, Off
SetTimer, CheckFoodImages, Off
SetTimer, StartClicker, Off
return

CheckFoodImages:
if (!scriptRunning)
    return

ToolTip, Checking food images...

for index, food in foodPriorities {
    foodImage := food.name
    ToolTip, Searching for: %foodImage%
    Sleep, 500
    ImageSearch, foodX, foodY, 0, 0, A_ScreenWidth, A_ScreenHeight, *0 %foodImage%
    if (!ErrorLevel) {
        ToolTip, Food found at %foodX%, %foodY%
        Sleep, 1000

        Click, %foodX%, %foodY%
        Click, A_ScreenWidth // 2, A_ScreenHeight // 2

        clickOnce := true

        Sleep, 1000

        ImageSearch, exerciseX, exerciseY, 0, 0, A_ScreenWidth, A_ScreenHeight, *0 bin\%exerciseType%.png
        if (!ErrorLevel) {
            ToolTip, %exerciseType% found at %exerciseX%, %exerciseY%
            Sleep, 1000

            Click, %exerciseX%, %exerciseY%
            MouseMove, A_ScreenWidth // 2, A_ScreenHeight // 2
            Click
            if (!clicking) {
                clicking := true
                startTime := A_TickCount
            }
        } else {
            ToolTip, %exerciseType%.png not found
            Sleep, 1000
        }
        break
    } else {
        ToolTip, Food image not found: %foodImage%
        Sleep, 1000
    }
}

ToolTip

ElapsedMinutes := (A_TickCount - startTime) / 60000
if (ElapsedMinutes >= 10) {
    startTime := A_TickCount
}

return

Clicker:
if (!clicking)
    return

if (clickOnce) {
    ToolTip, Clicking stopped. Duration reached.
    Sleep, 1000
    clicking := false
    clickOnce := false
    SetTimer, Clicker, Off
    SetTimer, StartClicker, %restartDelay%
    return
}

ToolTip, Clicking...

elapsedTime := (A_TickCount - startTime) / 1000
if (elapsedTime >= clickDuration)
{
    ToolTip, Clicking stopped. Duration reached.
    Sleep, 1000
    clicking := false
    clickOnce := false
    SetTimer, Clicker, Off
    SetTimer, StartClicker, %restartDelay%
    return
}

MouseMove, A_ScreenWidth // 2, A_ScreenHeight // 2
Click

return

StartClicker:
if (!scriptRunning)
    return
clicking := true
startTime := A_TickCount
SetTimer, Clicker, 10
SetTimer, StartClicker, Off
return

DebugFunction:
GoSub, CheckFoodImages
return

GuiClose:
ExitApp

SortByPriority(a, b)
{
    return a.priority < b.priority ? -1 : a.priority > b.priority ? 1 : 0
}
