; Identify dust value of unique items in Path of Exile 1
; created by the_eisn 
; version 0.0.1




; enabled only while developing the script
;#If WinActive("ahk_exe sublime_text.exe")
;    ~^s::
;		Reload
;    Return
;#If




; apply only during the game
SetTitleMatchMode, 3
#IfWinActive Path of Exile
#include CSV.ahk
#include Maths.ahk


; get shorthand value of dust
; 2300000 -> 2.3M
; 125000 -> 125k

get_dust_value(str_dust) {
	

	million  := Floor(str_dust / 1000000)
	hundredk := Floor(str_dust / 100000)
	tensk    := Floor(str_dust / 10000)
	thousand := Floor(str_dust / 1000)
	hundred  := Floor(str_dust / 100)

	if (million > 0) {
		output = %million%
		if (hundredk > 0) {
			output = %output%.%hundredk% M
		}

		return output
	}


	if (hundredk > 0 OR tensk > 0) {
		output = %thousand% K

		return output
	}

	if (thousand > 0) {
		output = %thousand%.%hundred% K

		return output
	}

	
}

main_function() {
	; load dust values from csv file
	CSV_Load("de_dust.csv", "de_dust")

	; copy twice in case of issues
	Send, ^c
	Send, ^c
	item_full = %Clipboard%


	; at this point copied has the entire item description, but it's on one line
	item_lines := StrSplit(item_full, "`n")

	; unique name is at line 3 if the item is identified
	; TO-DO: exception process for unidentified
	item_name := item_lines[3]

	; find the line that has Requirements as it's not a fixed position like the item's name
	; next line /should/ be the required level
	max_lines := item_lines.MaxIndex()
	counter := 1
	lvl_found := 0

	While (item_lines[counter]) {
		if Instr(item_lines[counter], "Requirements:") {
			lvl_found := counter
		}
		counter++
	}	

	lvl_found++
	req_level := item_lines[lvl_found]

	; strip potential extra characters
	item_name := RegExReplace(item_name,"\.? *(\n|\r)+","")
	item_req_level := RegExReplace(req_level,"\.? *(\n|\r)+","")

	item_req_level := StrSplit(item_req_level, " ")[2]

	; if Foulborn then remove that from the name
	If InStr(item_name, "Foulborn") {
		item_name := StrReplace(item_name, "Foulborn ")
	}

	; when the csv file is loaded it's with 1 row per line
	; the cell matches the entire row
	result := CSV_MatchCell("de_dust", item_name)
	result := StrSplit(result, ",")



	; finds the row that has the cell containing the unique name
	; afterwards gets the values on the 3rd and 4th columns
	val := CSV_ReadCell("de_dust", result[1], 2)
	dustval_84 := CSV_ReadCell("de_dust", result[1], 3)
	dustval_84_20q := CSV_ReadCell("de_dust", result[1], 4)

	; get shorthand version
	dustval_84 := get_dust_value(dustval_84)
	dustval_84_20q := get_dust_value(dustval_84_20q)

	if (dustval_84 > 0) {

		; calculate the tier
		compare := item_req_level - 1
		tier_coefficient := round(val / SM_Pow("1.03", compare),2)

		
		Switch tier_coefficient {
			Case 1    : tier := "Tier 5"
			Case 1.25 : tier := "Tier 4"
			Case 2    : tier := "Tier 3"
			Case 6    : tier := "Tier 2"
			Case 25   : tier := "Tier 1"
			Case 100  : tier := "Tier 0"
			Case 200  : tier := "Fishing Tier 0"
		}

		if tier {
			title := " " . tier	
		} else {
			title := " Dust"
		}
		
		text =  ilvl 84: %dustval_84% `n ilvl 84 20q: %dustval_84_20q%
	}
	else {
		CSV_Load("de_uniques.csv", "de_uniques")
		TotalRows := CSV_TotalRows("de_uniques")
		

		row := 1

		output_all := 

		while (row <= TotalRows) {
			row_line := CSV_ReadRow("de_uniques", row)
			row_text := StrSplit(row_line, ",")

			row_class := row_text[1]
			row_name := row_text[2]

			if (InStr(row_class, item_name)) {
				result := CSV_MatchCell("de_dust", row_name)
				result := StrSplit(result, ",")
				
				dustval := CSV_ReadCell("de_dust", result[1], 3)
				dustval := get_dust_value(dustval)

				output_all := output_all "`n "  row_name ": " dustval
			}


			row++
		}

		title := " Dust"
		text = %output_all%
	}
	
	text := " " . text . " "

	hToolTip := CustomToolTip(text, , , title, 0, false, 0xFFFFFF, 0x6e3587, "Segoe UI bold", "s18", false, 3000)

	Timer := Func("UpdateText").Bind(hToolTip, [ StrReplace(text, "five seconds", "one second")
	                                              , StrReplace(text, "five", "two")
	                                              , StrReplace(text, "five", "three")
	                                              , StrReplace(text, "five", "four") ])
	SetTimer, % Timer, 1000


}

^+D::main_function()

CustomToolTip( text, x := "", y := "", title := ""
             , icon := 0  ; can be 1 — Info, 2 — Warning, 3 — Error, if greater than 3 — hIcon
             , closeButton := false, backColor := "", textColor := 0
             , fontName := "", fontOptions := ""  ; like in GUI
             , isBallon := false, timeout := "", maxWidth := 600 )
{
   static ttStyles := (TTS_NOPREFIX := 2) | (TTS_ALWAYSTIP := 1), TTS_BALLOON := 0x40, TTS_CLOSE := 0x80
        , TTF_TRACK := 0x20, TTF_ABSOLUTE := 0x80
        , TTM_SETMAXTIPWIDTH := 0x418, TTM_TRACKACTIVATE := 0x411, TTM_TRACKPOSITION := 0x412
        , TTM_SETTIPBKCOLOR := 0x413, TTM_SETTIPTEXTCOLOR := 0x414
        , TTM_ADDTOOL        := A_IsUnicode ? 0x432 : 0x404
        , TTM_SETTITLE       := A_IsUnicode ? 0x421 : 0x420
        , TTM_UPDATETIPTEXT  := A_IsUnicode ? 0x439 : 0x40C
        , exStyles := (WS_EX_TOPMOST := 0x00000008) | (WS_EX_COMPOSITED := 0x2000000) | (WS_EX_LAYERED := 0x80000)
        , WM_SETFONT := 0x30, WM_GETFONT := 0x31
   
   dhwPrev := A_DetectHiddenWindows, defGuiPrev := A_DefaultGui, lastFoundPrev := WinExist()
   DetectHiddenWindows, On
   hWnd := DllCall("CreateWindowEx", "UInt", exStyles, "Str", "tooltips_class32", "Str", ""
                                   , "UInt", ttStyles | TTS_CLOSE * !!CloseButton | TTS_BALLOON * !!isBallon
                                   , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr")
   WinExist("ahk_id" . hWnd)
   if (textColor != 0 || backColor != "") {
      DllCall("UxTheme\SetWindowTheme", "Ptr", hWnd, "Ptr", 0, "UShortP", empty := 0)
      ByteSwap := Func("DllCall").Bind("msvcr100\_byteswap_ulong", "UInt")
      SendMessage, TTM_SETTIPBKCOLOR  , ByteSwap.Call(backColor << 8)
      SendMessage, TTM_SETTIPTEXTCOLOR, ByteSwap.Call(textColor << 8)
   }
   if (fontName || fontOptions) {
      Gui, New
      Gui, Font, % fontOptions, % fontName
      Gui, Add, Text, hwndhText
      SendMessage, WM_GETFONT,,,, ahk_id %hText%
      SendMessage, WM_SETFONT, ErrorLevel
      Gui, Destroy
      Gui, %defGuiPrev%: Default
   }
   VarSetCapacity(TOOLINFO, sz := 24 + A_PtrSize*6, 0)
   NumPut(sz, TOOLINFO)
   NumPut(TTF_TRACK | TTF_ABSOLUTE * !isBallon, TOOLINFO, 4)
   NumPut(&text, TOOLINFO, 24 + A_PtrSize*3)
   
   if (x = "" || y = "")
      DllCall("GetCursorPos", "Int64P", pt)
   (x = "" && x := (pt & 0xFFFFFFFF) + 45), (y = "" && y := (pt >> 32) + 15)
   
   SendMessage, TTM_SETTITLE      , icon, &title
   SendMessage, TTM_TRACKPOSITION ,     , x | (y << 16)
   SendMessage, TTM_SETMAXTIPWIDTH,     , maxWidth
   SendMessage, TTM_ADDTOOL       ,     , &TOOLINFO
   SendMessage, TTM_UPDATETIPTEXT ,     , &TOOLINFO
   SendMessage, TTM_TRACKACTIVATE , true, &TOOLINFO
   
   if timeout {
      Timer := Func("DllCall").Bind("DestroyWindow", "Ptr", hWnd)
      SetTimer, % Timer, % "-" . timeout
   }
   DetectHiddenWindows, % dhwPrev
   WinExist("ahk_id" . lastFoundPrev)
   Return hWnd
}

UpdateText(hTooltip, TextArray) {
   static TTM_UPDATETIPTEXT := A_IsUnicode ? 0x439 : 0x40C
   text := TextArray.Pop()
   VarSetCapacity(TOOLINFO, sz := 24 + A_PtrSize*6, 0)
   NumPut(sz, TOOLINFO)
   NumPut(&text, TOOLINFO, 24 + A_PtrSize*3)
   SendMessage, TTM_UPDATETIPTEXT,, &TOOLINFO,, ahk_id %hTooltip%
   if (TextArray[1] = "")
      SetTimer,, Delete
}