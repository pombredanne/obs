# list windows
set out to ""
tell application "Terminal"
	repeat with the_window in every window
		set out to out & "window "
		repeat with the_tab in every tab in the_window
			set out to out & "tab "
			#if (the_tab's busy = false) then
                        #    close (first window whose selected tab is the_tab) saving no
                        #end if
		end repeat
	end repeat
end tell
return out
