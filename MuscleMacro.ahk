#Persistent

; Global variables to store hotkeys and other settings
global startHotkey := ""
global stopHotkey := ""
global debugHotkey := "^d"  ; Ctrl + D for debug
global startTime := 0
global clicking := false
global restartDelay := 10 ; Default 10 seconds
global clickDuration := 5 ; Default 5 seconds
global checkInterval := 10 ; Default 10 minutes
global foodImages := []
global foodPriorities := []
global clickOnce := false
global exerciseType := "PushUp" ; Default to "PushUp"

; Create the GUI
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

; Populate foodImages and create priority controls
Loop, Files, bin/foods\*.png
{
    foodImages.Push(A_LoopFileFullPath)
    fileName := SubStr(A_LoopFileName, 1, -4) ; Remove the .png extension
    Gui, Add, Text,, % "Priority for " fileName ":"
    Gui, Add, Edit, vFoodPriority%fileName% w50, 1 ; Default priority is 1
}

; Show the GUI with priority controls
Gui, Show

; Variables to control the script state
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
restartDelay := RestartDelayEdit * 1000 ; Convert to milliseconds
clickDuration := ClickDurationEdit
checkInterval := CheckIntervalEdit * 60000 ; Convert to milliseconds

; Store food priorities
foodPriorities := []
Loop, % foodImages.MaxIndex()
{
    fileName := SubStr(foodImages[A_Index], InStr(foodImages[A_Index], "\", 0, 0) + 1)
    fileName := SubStr(fileName, 1, -4) ; Remove the .png extension
    Gui, Submit, NoHide
    foodPriorities.Push({name: foodImages[A_Index], priority: FoodPriority%fileName%})
}

; Sort food priorities based on the priority value
foodPriorities.Sort("SortByPriority")

Hotkey, %startHotkey%, StartScript
Hotkey, %stopHotkey%, StopScript
Hotkey, %debugHotkey%, DebugFunction  ; Register debug hotkey
MsgBox, Settings saved! Start: %startHotkey% Stop: %stopHotkey% Restart Delay: %restartDelay% ms Click Duration: %clickDuration% s Check Interval: %checkInterval% min Exercise: %exerciseType%
return

StartScript:
if (scriptRunning)
    return
scriptRunning := true
clickOnce := false
SetTimer, CheckFoodImages, %checkInterval% ; Set timer to check food images based on user input
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

ToolTip, Checking food images...  ; Show a tooltip as a debug message

for index, food in foodPriorities {
    foodImage := food.name
    ToolTip, Searching for: %foodImage%
    Sleep, 500 ; Allow time to see the search message
    ImageSearch, foodX, foodY, 0, 0, A_ScreenWidth, A_ScreenHeight, *0 %foodImage%
    if (!ErrorLevel) {
        ; Debugging step: Show the coordinates where the food image was found
        ToolTip, Food found at %foodX%, %foodY%
        Sleep, 1000  ; Pause to see the debug message

        Click, %foodX%, %foodY%
        Click, A_ScreenWidth // 2, A_ScreenHeight // 2

        clickOnce := true

        ; Wait 1 second before searching for exercise image (PushUp or Situp)
        Sleep, 1000

        ImageSearch, exerciseX, exerciseY, 0, 0, A_ScreenWidth, A_ScreenHeight, *0 bin\%exerciseType%.png
        if (!ErrorLevel) {
            ; Debugging step: Show the coordinates where the exercise image was found
            ToolTip, %exerciseType% found at %exerciseX%, %exerciseY%
            Sleep, 1000  ; Pause to see the debug message
            ; Click on exercise image and move mouse to center
            Click, %exerciseX%, %exerciseY%
            MouseMove, A_ScreenWidth // 2, A_ScreenHeight // 2 ; Move mouse to center of the screen
            Click
            if (!clicking) {
                clicking := true
                startTime := A_TickCount
            }
        } else {
            ToolTip, %exerciseType%.png not found
            Sleep, 1000 ; Pause to see the debug message
        }
        break
    } else {
        ; Debugging step: Indicate that the image was not found
        ToolTip, Food image not found: %foodImage%
        Sleep, 1000  ; Pause to see the debug message
    }
}

ToolTip  ; Clear the tooltip after processing

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
    Sleep, 1000 ; Pause for 1 second to see the debug message
    clicking := false
    clickOnce := false
    SetTimer, Clicker, Off ; Turn off the timer after click duration
    SetTimer, StartClicker, %restartDelay% ; Schedule to start clicking again after delay
    return
}

ToolTip, Clicking... ; Show a tooltip as a debug message

elapsedTime := (A_TickCount - startTime) / 1000
if (elapsedTime >= clickDuration) ; Stop clicking after click duration
{
    ToolTip, Clicking stopped. Duration reached.
    Sleep, 1000 ; Pause for 1 second to see the debug message
    clicking := false
    clickOnce := false
    SetTimer, Clicker, Off ; Turn off the timer after click duration
    SetTimer, StartClicker, %restartDelay% ; Schedule to start clicking again after delay
    return
}

MouseMove, A_ScreenWidth // 2, A_ScreenHeight // 2 ; Move mouse to center of the screen
Click

return

StartClicker:
if (!scriptRunning)
    return
clicking := true
startTime := A_TickCount
SetTimer, Clicker, 10
SetTimer, StartClicker, Off ; Turn off the timer to avoid multiple instances
return

DebugFunction:
GoSub, CheckFoodImages  ; Execute the CheckFoodImages subroutine
return

GuiClose:
ExitApp

SortByPriority(a, b)
{
    return a.priority < b.priority ? -1 : a.priority > b.priority ? 1 : 0
}
