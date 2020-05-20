#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Map Capslock to Hyper
; Map press & release of Capslock with no other key to Esc

*Capslock::
    SetKeyDelay -1
    Send {Blind}{Ctrl DownTemp}
    return

*Capslock up::
    SetKeyDelay -1
    Send {Blind}{Ctrl Up}
    if A_PRIORKEY = CapsLock
    {
        	Send {Esc}
    }
    return


;  Move window to next monitor
Insert::Send #+{Left}

; fullscreen
#^+!f::WinMaximize A

; snap left/right
#^+!Left::SendEvent {LWin down}{Left down}{LWin up}{Left up}
#^+!Right::SendEvent {LWin down}{Right down}{LWin up}{Right up}

; For internal Surface Book keyboard
; Having trouble reliably mapping CapsLock to a modifier, so this works instead
CapsLock & Left::SendEvent {LWin down}{Left down}{LWin up}{Left up}
CapsLock & Right::SendEvent {LWin down}{Right down}{LWin up}{Right up}
CapsLock & f::WinMaximize A


; Approximate macOS window closing
!w::WinClose A
!q::WinClose A

!h::WinMinimize A

; macOS screenshots
!+4::Send {PrintScreen}

^!r::
    TrayTip, Reloading Config.ask, Config.ask is reloading
    Sleep 3000
    Reload

; Outlook
#IfWinActive, ahk_class rctrl_renwnd32
^f::Send {F3}

