#SingleInstance Force
CoordMode, Mouse, Screen

Gui +Resize +AlwaysOnTop
Gui, Add, Pic, vMyPic x0 y0 w500 h500 Center hwndPicHwnd
Gui, Add, Button, x+1 y0 gToggleBorder vToggleBtn hwndToggleBtnHwnd, Toggle Border

buttonDragging := false
buttonStartX := 0
buttonStartY := 0
initialBtnX := 0
initialBtnY := 0
currentImage := ""
scale := 1.0
imageWidth := 0
imageHeight := 0
borderlessMode := true
imgX := 0
imgY := 0
dragging := false
dragStartX := 0
dragStartY := 0
initialImgX := 0
initialImgY := 0

Gui +E0x00000010L  ; Accept files
Gui -Border
Gui Show, w600 h600, Image Viewer

OnMessage(0x201, "WM_LBUTTONDOWN")  ; Enable drag on borderless title

return

GuiDropFiles:
Loop, parse, A_GuiEvent, `n
{
    If FileExist(A_LoopField)
    {
        currentImage := A_LoopField
        LoadImage(currentImage)
        break
    }
}
return

LoadImage(path) {
    global PicHwnd, imageWidth, imageHeight, scale, imgX, imgY
    GuiControl,, MyPic, *w0 *h0
    GuiControl,, MyPic, % "*" path
    hBmp := LoadPicture(path, "GDI+")
    if (hBmp)
    {
        DllCall("GetObject", "Ptr", hBmp, "Int", VarSetCapacity(obj, 24, 0), "Ptr", &obj)
        imageWidth := NumGet(obj, 4, "Int")
        imageHeight := NumGet(obj, 8, "Int")
        DllCall("DeleteObject", "Ptr", hBmp)
    }
    scale := 1.0
    imgX := 0
    imgY := 0
    ResizeImage()
}

ResizeImage() {
    global imageWidth, imageHeight, scale, currentImage, imgX, imgY
    if (imageWidth = 0 or imageHeight = 0 or currentImage = "")
        return
    newW := Round(imageWidth * scale)
    newH := Round(imageHeight * scale)
    GuiControl, Move, MyPic, x%imgX% y%imgY% w%newW% h%newH%
    GuiControl,, MyPic, *w%newW% *h%newH% %currentImage%
}

GuiSize:
    ResizeImage()
return

GuiEscape:
GuiClose:
ExitApp

ToggleBorder:
    global borderlessMode
    if borderlessMode {
        Gui +Border +SysMenu
        borderlessMode := false
    } else {
        Gui -Border -SysMenu
        borderlessMode := true
    }
    Gui, Show, AutoSize
return

ResetImagePosition:
    global imgX, imgY
    imgX := 0
    imgY := 0
    ResizeImage()
return

WM_LBUTTONDOWN() {
    global borderlessMode
    if borderlessMode
        PostMessage, 0xA1, 2  ; Drag window itself when borderless
}

; -------------------------------
; 🎯 HOTKEYS (Active only in GUI)
; -------------------------------
#IfWinActive Image Viewer

^WheelUp::
    scale := Min(scale * 1.1, 5.0)
    ResizeImage()
return

^WheelDown::
    scale := Max(scale / 1.1, 0.1)
    ResizeImage()
return

^Up::
    imgY -= 5
    ResizeImage()
return

^Down::
    imgY += 5
    ResizeImage()
return

^Left::
    imgX -= 5
    ResizeImage()
return

^Right::
    imgX += 5
    ResizeImage()
return

^LButton::
    MouseGetPos, mx, my, winId, ctrlHwnd, 2
    if (ctrlHwnd = ToggleBtnHwnd) {
        buttonDragging := true
        buttonStartX := mx
        buttonStartY := my
        GuiControlGet, btnPos, Pos, ToggleBtn
        initialBtnX := btnPosX
        initialBtnY := btnPosY
    } else {
        dragging := true
        dragStartX := mx
        dragStartY := my
        initialImgX := imgX
        initialImgY := imgY
    }
    SetTimer, UnifiedDragHandler, 10
return

^LButton Up::
    dragging := false
	buttonDragging := false
    SetTimer, DragImage, Off
return

DragImage:
if (!dragging)
    return
MouseGetPos, mx, my
dx := mx - dragStartX
dy := my - dragStartY
imgX := initialImgX + dx
imgY := initialImgY + dy
ResizeImage()
return

UnifiedDragHandler:
MouseGetPos, mx, my
if (buttonDragging) {
    dx := mx - buttonStartX
    dy := my - buttonStartY
    newX := initialBtnX + dx
    newY := initialBtnY + dy
    GuiControl, Move, ToggleBtn, x%newX% y%newY%
} else if (dragging) {
    dx := mx - dragStartX
    dy := my - dragStartY
    imgX := initialImgX + dx
    imgY := initialImgY + dy
    ResizeImage()
}
return

#IfWinActive
