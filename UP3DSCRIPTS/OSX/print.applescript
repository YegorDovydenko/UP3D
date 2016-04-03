#! /usr/bin/osascript

on run (arguments)
	set myName to path to me as string
	if number of arguments > 1 then
		display dialog ("No single file for transcoding provided. You need to supply a single G-Code file.") Â
			buttons {"OK"} Â
			with icon 0 Â
			with title (path to me as string)
		error number -50
	end if
	if number of arguments = 0 then
		set fname to POSIX path of (choose file with prompt "UP3D select G-Code file to transcode and print" of type {"gcode", "g", "gco", "gc"})
	else
		set fname to (first item of arguments)
	end if
	
	set o to (length of fname) + 1 - (offset of "." in (reverse of text items of fname as string))
	if o < (length of fname) + 1 then
		set oname to text 1 thru o of fname & "umc"
	else
		set oname to fname & ".umc"
	end if
	if fname = oname then set oname to fname & ".umc"
	
	try
		set height to do shell script "defaults read com.up3d.transcode nozzle_height"
	on error
		set height to 123.45
	end try
	
	try
		set transcoder to do shell script "defaults read com.up3d.transcode transcoder_path"
	on error
		set transcoder to POSIX path of (choose file with prompt "Can't find transcoder executable. Please select UP3D Transcoder." of type {"public.executable"})
		do shell script ("defaults write com.up3d.transcode transcoder_path " & transcoder)
	end try
	
	try
		set uploader to do shell script "defaults read com.up3d.transcode uploader_path"
	on error
		set uploader to POSIX path of (choose file with prompt "Can't find uploader executeable. Please Select UP3D uploader" of type {"public.executable"})
		do shell script ("defaults write com.up3d.transcode uploader_path " & uploader)
	end try
	
	repeat
		set DlogResult to display dialog ("Printing:		" & fname & "
Output file:	" & oname & "
Nozzle Height:") Â
			default answer height Â
			buttons {"Cancel", "Transcode"} default button 2 Â
			with title "UP3D Transcoding from G-Code"
		set height to text returned of DlogResult as real
		set answer to button returned of DlogResult
		if height < 120 or height > 130 then
			display dialog "Nozzle Height must be set between 120 and 130 mm."
		else
			exit repeat
		end if
	end repeat
	
	set ret to "Cancel"
	
	if answer = "Transcode" then
		do shell script ("defaults write com.up3d.transcode nozzle_height " & height)
		set nozzle_height to height as text
		set o to offset of "," in nozzle_height
		if o is not 0 then set nozzle_height to text 1 thru (o - 1) of nozzle_height & "." & text (o + 1) thru -1 of nozzle_height
		do shell script (transcoder & "  " & fname & " " & oname & " " & nozzle_height)
		set ret to result
		display dialog (result as text) with title "UP3D transcoding result" buttons {"Cancel", "To Printer"} default button 2
		set answer to button returned of result
		if answer = "To Printer" then
			repeat
				try
					do shell script (uploader & " " & oname)
					display dialog result with title "UP3D upload" buttons {"OK"} default button 1
					exit repeat
				on error eString
					display dialog eString with title "UP3D upload error" with icon 2 buttons {"Cancel", "Retry"} default button 2
					if button returned of result = "Cancel" then exit repeat
				end try
			end repeat
		end if
	end if
	return ret
end run
