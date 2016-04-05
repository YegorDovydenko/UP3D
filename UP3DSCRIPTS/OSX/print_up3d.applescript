#! /usr/bin/osascript

-- property extension_list : {"gcode", "gc", "g", "go"}

on launch (arguments)
	--display notification "app got launched" with title "print_up3d"
end launch

on open (arguments)
	--display notification "open"
	if number of items in arguments > 0 then
		set fn to first item of arguments as string
		process(fn)
	else
		--display notification "nothing to do" with title "print_up3d"
	end if
end open

on run (arguments)
	--display notification "my_run" with title "print_up3d"
	try
		set argc to number of items in arguments
	on error
		set argc to 0
	end try
	
	-- if no arguments are present we show a ask for a file
	if argc = 0 then
		set fname to (choose file with prompt Â
			"UP3D select G-Code file to transcode and print" of type {"gcode", "g", "gco", "gc"})
	else
		set fname to (first item of arguments)
	end if
	
	process(fname)
end run

on process(gcode)
	set transcoderResult to transcode(gcode)
	if number of items in transcoderResult > 0 then
		display dialog (status of transcoderResult) with title Â
			"UP3D transcoding result" buttons {"Cancel", "Send To Printer"} default button 2
		if button returned of result = "Send To Printer" then
			upload(tmpFile of transcoderResult)
		end if
		-- clean up tmp file
		try
			do shell script ("rm -rf " & quoted form of tmpFile of transocerResult)
		end try
	end if
end process

on getHeight()
	try
		set height to do shell script "defaults read com.up3d.transcode nozzle_height"
	on error
		set height to 123.45
	end try
	return height
end getHeight

on getTranscoder()
	try
		set transcoder to do shell script "defaults read com.up3d.transcode transcoder_path"
	on error
		set transcoder to POSIX path of Â
			(choose file with prompt Â
				"Can't find transcoder executable. Please select UP3D Transcoder." of type {"public.executable"})
		do shell script ("defaults write com.up3d.transcode transcoder_path " & quoted form of transcoder)
	end try
	return transcoder
end getTranscoder

on getUploader()
	try
		set uploader to do shell script "defaults read com.up3d.transcode uploader_path"
	on error
		set uploader to POSIX path of (choose file with prompt Â
			"Can't find uploader executeable. Please Select UP3D uploader" of type {"public.executable"})
		do shell script ("defaults write com.up3d.transcode uploader_path " & quoted form of uploader)
	end try
	return uploader
end getUploader

on transcode(filename)
	set ptmpTranscode to POSIX path of (path to temporary items from user domain) & "transcode.umc"
	set height to getHeight()
	-- ask user for nozzle height
	repeat
		set DlogResult to display dialog ("Printing: " & POSIX path of filename & linefeed & "Set Nozzle Height:") Â
			default answer height Â
			buttons {"Cancel", "Transcode"} default button 2 Â
			with title "UP3D Transcoding from G-Code"
		set height to text returned of DlogResult as real
		set answer to button returned of DlogResult
		if answer is equal to "Cancel" then
			return {}
		end if
		if height < 120 or height > 130 then
			display dialog "Nozzle Height must be set between 120 and 130 mm."
		else
			exit repeat
		end if
	end repeat
	set transcoder to getTranscoder()
	-- save nozzle height to defaults
	do shell script ("defaults write com.up3d.transcode nozzle_height " & height)
	set nozzle_height to height as text
	-- replace comma to point in nozzle height string
	set o to offset of "," in nozzle_height
	if o is not 0 then set nozzle_height to text 1 thru (o - 1) of nozzle_height & "." & text (o + 1) thru -1 of nozzle_height
	do shell script (quoted form of transcoder & "  " & quoted form of POSIX path of filename & Â
		" " & quoted form of ptmpTranscode & " " & nozzle_height)
	return {tmpFile:ptmpTranscode, status:result}
end transcode

on upload(pfilename)
	set ptmpUpload to POSIX path of (path to temporary items from user domain) & "upload.out"
	set uploader to getUploader()
	set retry to false
	repeat
		do shell script (quoted form of uploader & " " & quoted form of pfilename & Â
			" > " & quoted form of ptmpUpload & " 2>&1 &")
		log ("upload launched...")
		set progress description to "Sending data to printer"
		set progress additional description to "UploadingÉ"
		set progress total steps to 100
		repeat
			--delay 0.2
			try
				-- now we get the last line of the uploader output
				-- first we strip newlines from the file
				-- then we translate carriage returns to newlines
				-- finally we can get the last line with tail
				do shell script ("tr -d '\\n' < " & quoted form of ptmpUpload & " | tr '\\r' '\\n' | tail -n 1")
				set status_line to result
				log (status_line)
				if status_line contains "ERROR" then
					display dialog status_line with title Â
						"UP3D upload" buttons {"Cancel", "Retry"} default button 2
					if button returned of result = "Retry" then
						set retry to true
					else
						set retry to false
					end if
					exit repeat
				else if (count of words of status_line) > 5 then
					try
						set p to item 5 of words of status_line as number
						--set progress additional description to status_line
						set progress completed steps to p
						log (p)
						if p is equal to 100 then
							retry = false
							exit repeat
						end if
					on error thisErr
						log ("fail: " & (words of status_line) & " | " & thisErr)
					end try
				end if
			on error thisErr
				display alert thisErr
				return
			end try
		end repeat
		if retry = false then exit repeat
	end repeat
	-- clean up tmp file
	try
		do shell script ("rm -rf " & quoted form of ptmpUpload)
	end try
end upload
