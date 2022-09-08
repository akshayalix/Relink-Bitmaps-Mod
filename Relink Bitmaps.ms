/*
	Relink Bitmaps written by Colin Senner
	Complete Rewrite of version 1.15
	June 12th, 2009
	v2.01

	Changelog 2.01
	- Fixed a bug where m.filename comes back undefined and causes an error
	Changelog 2.02
	- Added a requested option to delete all missing maps
	- Fixed a bug with "Find" material
	Changelog 2.03
	- Changing the scripts directory to the *user scripts directory to avoid problems with 3dsmax administrator permissions
	- Changed the behavior of single clicking on a missing map to require a double click
	- Added the option to ignore the file's extension allowing you to relink .jpg to .tif of the same filename
	Changelog 2.04
	- Allows pasting in the file open field
	- Global license key
	- Allows for a valid license to be found based only on the first 10 digits of the user's network card's MAC id
	Changelog 2.08
	- Lost this source due to RAID fuckup
	Changelog 2.09
		- Added support for Read-Only drive shares
		- Added support for Corona Renderer  (CoronaBitmap, CProxy, CoronaLight)
		- Fixed Install_Count database on my server
		- Added Run_Count variable db on my server
	Changelog 2.10
		- FStorm Render Support Added
		- Fixed $directory not recognized
		- [NEW] Search max file path added
	Changelog 2.11
		- Fixed small bug with SearchMaxFilePath
		- Resizable missing bitmaps window
		- Changed the banner to use a jpg and an xml for the link instead of an old web browser
		- Fixed bug where Relink Bitmaps would not launch visibly
	Changelog 2.12
		- Fix script error for run_count_2_08.php
		- Arnold Renderer support added
		- Removed all mandatory callbacks to colinsenner.com
		- Moved auto-update feature from running automatically to a button
		- When checking for an update the WebRequest is sent using https instead of http
	Changelog 2.13
		- Max 2022 support added
		- Fix script error that occurred when the user doesn't have a "Relink Bitmaps.ini" file, this error was likely very old
		- Added support for OSL Maps
	Changelog 2.131
		- VRayBitmap maps are now supported
	Changelog 2.14
		- Add support for VRayBitmap
		- Fix it so VRayBitmaps and VRayHDRI don't show both since they're the same map type now
	Chagelog 2.15
		- Redshift support added
	Chagelog 2.16
		- Relink Bitmaps now respects the project and external directories and won't return missing maps from themixer
		- Fix crash with .width on a button
		- Fix "Delete All missing bitmaps" functionality
		- Support for Substance files
*/

-- Global Defs
global rlt_RelinkBitmaps
global rlt_QuickPathsAdd
global rlt_MissingBitmaps
global rlt_Configure
global rlt_donate
global rlt_donateRequest

-- Global Variables
global iniFile = (getDir #userScripts + "\\Relink Bitmaps.ini")

global colinsennerWebpage = "https://colinsenner.com/#"
global relinkBitmapsWebpage = "https://colinsenner.com/relink-bitmaps/"
global versionXmlFile = "https://colinsenner.com/relinkbitmaps/version_data.xml"

global banner_image_path = getDir #userscripts + "\\Relink Bitmaps\\banner.jpg"
global banner_image_url = "https://www.greattalksaboutphotorealism.com/relink-bitmaps-discount-page"

-- Version
global currentVersion = 2.16

-- Donate button link
global donateURL = "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=colin%2esenner%40gmail%2ecom&lc=US&item_name=Relink%20Bitmaps%20Script&item_number=1002&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"
global debugOn = false

global relinkBitmapsWindowWidth = 400
global relinkBitmapsWindowHeight = 545
global missingMapsWindowWidth = 750
global missingMapsWindowHeight = 545
global configureWindowWidth = 210
global configureWindowHeight = 210

-- Global Variables editable
global uev_recursiveSubfolders = true
global uev_ignoreCase = false
global uev_defaultSearchDirectory = "C:\\"
global uev_lowMemory = false
global uev_ignoreExtension = false
global uev_readOnlySupport = false
global uev_searchMaxFilePath = false

-- Uncomment the first two for release
fileIn "C_Lib.mse"
fileIn "Relink_Lib.mse"
--fileIn "C_Lib.ms"
--fileIn "Relink_Lib.ms"

-- Close all rollouts
closeRelinkBitmapsDialogs()

-- Init Default Variables
initDefaultVariables iniFile

-- Rollout Main

rollout rlt_RelinkBitmaps ("Relink Bitmaps v" + (formattedPrint currentVersion format:".2f")) (
	imgTag img_bg "bg" width:(rlt_RelinkBitmaps.width + 20) height:68 tooltip:colinsennerWebpage bitmap:(bitmap 50 50 color:(color 26 170 245)) offset:[-15,-5] align:#left
	imgTag img_header "Header" width:306 height:68 tooltip:colinsennerWebpage bitmap:(openBitmap "$userScripts/Relink Bitmaps/header.png") offset:[-17,-75]

	-- Saved Paths
	groupBox grp_saved_paths "Saved Paths Directory"  height:240 offset:[-9,0] width:(rlt_RelinkBitmaps.width - 10)
	multiListBox lst_QuickPaths "" height:14 width:275 offset:[0,-(grp_saved_paths.height - 15)]
	button btn_QuickPathsAll "All" width:35 height:17 align:#left
	button btn_QuickPathsNone "None" width:35 height:17 align:#left offset:[50,-22]
	button btn_QuickPathsAdd "+" width:35 height:17 align:#right offset:[-50,-22]
	button btn_QuickPathsDel "-" width:35 height:17 align:#right offset:[0,-22]

	label lbl_space1 offset:[0,-8]

	-- Search Directory
	groupBox grp_search_directory "Search Directory"  height:55 offset:[-9,0] width:(rlt_RelinkBitmaps.width - 10)
	edittext edt_Browse "" text:"Select a directory to search" height:26 readOnly:true width:(rlt_RelinkBitmaps.width - 90) offset:[0,-(grp_search_directory.height - 15)]
	button btn_Browse "Browse" width:50 align:#right offset:[-5,-28]

	label lbl_space2 offset:[0,-8]

	-- Options
	groupBox grp_options "Options"  height:100 offset:[-9,0] width:(rlt_RelinkBitmaps.width - 10)
	checkbox chk_recursive "Search Subfolders" checked:uev_recursiveSubfolders offset:[0,-(grp_options.height - 15)]
	checkbox chk_ignoreExtension "Ignore Extension" checked:uev_ignoreExtension offset:[130,-20]
	checkbox chk_ignoreCase "Ignore case" checked:uev_ignoreCase offset:[0,-2]
	checkbox chk_lowMemory "Low Memory" checked:uev_lowMemory offset:[130,-20]

	checkbox chk_searchMaxFilePath "Search Max File Path" checked:uev_searchMaxFilePath offset:[0,-3]
	checkbox chk_readOnlySupport "Read-only support" checked:uev_readOnlySupport offset:[130, -20]

	checkbox chk_allMaps "All Bitmaps" checked:false offset:[0,-3]

	button btn_configure "Configure" height:16 align:#right offset:[0,-20]

	label lbl_space3 offset:[0,0]
	button btn_Relink "Relink" width:(rlt_RelinkBitmaps.width - 15) height:25 align:#center offset:[0,0]
	progressBar pb_relinkPB offset:[0,5] width:(rlt_RelinkBitmaps.width - 25)

	fn resize_ui size = (
		-- The blue image behind the banner image
		img_bg.width = size.x

		-- Saved Paths
		grp_saved_paths.width = size.x - 9
		lst_QuickPaths.width = size.x - 27
		btn_QuickPathsAdd.pos.x = size.x - 100
		btn_QuickPathsDel.pos.x = size.x - 50

		-- Search Directory
		grp_search_directory.width = size.x - 9
		btn_Browse.pos.x = size.x - 65
		edt_Browse.width = size.x - 27 - 65 -- btn_Browse.width - 15

		-- Options
		grp_options.width = size.x - 9
		btn_configure.pos.x = size.x - 80

		-- Move the missing maps window into the right place
		rlt_RelinkBitmaps.moved (GetDialogPos rlt_RelinkBitmaps)
	)

	on rlt_RelinkBitmaps resized size do
	(
		resize_ui size
	)

	on rlt_RelinkBitmaps close do ( closeRelinkBitmapsDialogs() )
	on btn_QuickPathsAdd pressed do ( openDialog rlt_QuickPathsAdd width:370 height:40 )
	on btn_QuickPathsDel pressed do (	deleteQuickPath iniFile lst_QuickPaths.selection )
	on btn_QuickPathsAll pressed do ( lst_QuickPaths.selection = #{1..(lst_QuickPaths.items.count)} )
	on btn_QuickPathsNone pressed do ( lst_QuickPaths.selection = #{} )
	on btn_configure pressed do ( openRolloutNextTo rlt_RelinkBitmaps rlt_Configure width:configureWindowWidth height:configureWindowHeight )
	on img_header mouseup do ( shellLaunch colinsennerWebpage "" )
	on img_bg mouseup do ( shellLaunch colinsennerWebpage "" )

	on chk_allMaps changed state do (
		rlt_MissingBitmaps.updateMissingMaps()
	)

	on btn_Relink pressed do (
		sceneRelinkBitmaps (returnAllSearchDirectories iniFile) ignoreCase:(chk_ignoreCase.checked) ignoreExtension:(chk_ignoreExtension.checked) undoOn:true lowMemory:(chk_lowMemory.checked) recursive:(chk_recursive.checked) allMaps:(chk_allMaps.checked) searchMaxFilePath:(chk_searchMaxFilePath.checked) progress:pb_relinkPB
		rlt_MissingBitmaps.updateMissingMaps()
	)

	on btn_Browse pressed do (
		-- Open the directory file dialog
		if (edt_Browse.text != "Select a directory to search") and (edt_Browse.text != "") then (
			if not(rlt_RelinkBitmaps.chk_readOnlySupport.checked) then (
				if (f = getSavePath caption:"Select the folder to locate bitmaps" initialDir:edt_Browse.text) != undefined then
					edt_Browse.text = (f as string)
			) else (
				-- Read-Only support enabled - 2.08 change
				if (f = getOpenFilename caption:"[Read-Only Support] Select the folder to locate bitmaps" filename:(edt_Browse.text + @"\" + "Select the Path")) != undefined then
					edt_Browse.text = getFilenamePath (f as string)
			)
		) else (
			if not(rlt_RelinkBitmaps.chk_readOnlySupport.checked) then (
				if (f = getSavePath caption:"Select the folder to locate bitmaps" initialDir:uev_defaultSearchDirectory) != undefined then
					edt_Browse.text = (f as string)
			) else (
				-- Read-Only support enabled - 2.08 change
				if (f = getOpenFilename caption:"[Read-Only Support] Select the folder to locate bitmaps" filename:(uev_defaultSearchDirectory + @"\" + "Select the Path")) != undefined then
					edt_Browse.text = getFilenamePath (f as string)
			)
		)
	)

	on rlt_RelinkBitmaps open do (
		resize_ui (point2 rlt_RelinkBitmaps.width rlt_RelinkBitmaps.height)

		-- Loads the quickpaths in the listbox
		updateQuickPaths iniFile rlt_RelinkBitmaps.lst_QuickPaths

		-- Opens the missing bitmaps dialog next to it
		openRolloutNextTo rlt_RelinkBitmaps rlt_MissingBitmaps width:missingMapsWindowWidth height:missingMapsWindowHeight style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)

		if validateLicFile (returnLicenseFile "Relink Bitmaps.lic") == false then (
			-- If  the file isn't valid
			openDialog rlt_donate width:260 height:200 posX:((GetDialogPos rlt_RelinkBitmaps).x + 200) posY:((GetDialogPos rlt_RelinkBitmaps).y + 100) modal:false
		)
	)

	on rlt_RelinkBitmaps moved xy do (
		local x = (rlt_RelinkBitmaps.width+0) + ((GetDialogPos rlt_RelinkBitmaps).x)
		SetDialogPos rlt_MissingBitmaps (point2 x xy.y)
	)

	on rlt_RelinkBitmaps close do (
		saveCurrentPosition rlt_RelinkBitmaps iniFile
		closeRelinkBitmapsDialogs()
	)

	-- restores the checkboxes to the user saved settings
	fn updateDefaultOptions = (
		chk_recursive.checked = uev_recursiveSubfolders
		chk_ignoreCase.checked = uev_ignoreCase
		chk_lowMemory.checked = uev_lowMemory
		chk_ignoreExtension.checked = uev_ignoreExtension
		chk_readOnlySupport.checked = uev_readOnlySupport
		chk_searchMaxFilePath.checked = uev_searchMaxFilePath
	)
)

-- Rollout the user gets when they click "Donate!"
rollout rlt_donateRequest "Request Code" (
	label lbl_one "Thank you for taking the time to donate"
	label lbl_two "Please copy the below request code and email it "
	label lbl_three "using the same PayPal email address you used to donate"
	label lbl_four "     colin.senner@gmail.com" offset:[0,5]
	edittext edt_requestCode "Request Code:" fieldWidth:190 height:20 offset:[0,8]

	on rlt_donateRequest open do (
		edt_requestCode.text = (requestLicense() as string)
	)
)

-- Rollout for Adding Quick Paths
rollout rlt_QuickPathsAdd "" (
	edittext edt_QuickPathsBrowse height:20 width:265 offset:[0,4] readOnly:true
	button btn_QuickPathsBrowse "..." width:25 align:#right offset:[-45,-24]
	button btn_QuickPathsAdd "Add" width:35 align:#right offset:[0,-26]

	on btn_QuickPathsBrowse pressed do (
		-- Open the directory file dialog
		if (f = getSavePath initialDir:uev_defaultSearchDirectory) != undefined then
			edt_QuickPathsBrowse.text = (f as string)
	)

	on btn_QuickPathsAdd pressed do (
		-- Add the Quickpath
		if (addQuickPath iniFile (edt_QuickPathsBrowse.text)) then (
			closeDialog rlt_QuickPathsAdd
			updateQuickPaths iniFile rlt_RelinkBitmaps.lst_QuickPaths
		) else (
			messageBox "Couldn't set the Quick Path" beep:false
			closeDialog rlt_QuickPathsAdd
			updateQuickPaths iniFile rlt_RelinkBitmaps.lst_QuickPaths
		)
	)
)

-- Rollout for Configuration
rollout rlt_Configure "Configuration Options" (
	group "Default Options" (
		checkbox chk_default_recursiveSubfolders "Search Subfolders" checked:uev_recursiveSubfolders
		checkbox chk_default_ignoreCase "Ignore Case" checked:uev_ignoreCase
		checkbox chk_default_ignoreExtension "Ignore Extension" checked:uev_ignoreExtension
		checkbox chk_default_lowMemory "Low Memory" checked:uev_lowMemory
		checkbox chk_default_searchMaxFilePath "Search Max File Path" checked:uev_searchMaxFilePath
		checkbox chk_default_readOnlySupport "Read-only support" checked:uev_readOnlySupport
		edittext edt_default_browse "" text:"Default Search Directory" width:132 readOnly:true offset:[-5,0]
		button btn_browse "Browse" width:45 height:18 align:#right offset:[0,-22]
	)
	button btn_saveConfiguration "Save" width:60 align:#center offset:[0,0]
	button btn_resetConfiguration "Reset" width:60 align:#right offset:[4,-26]

	on btn_resetConfiguration pressed do ( resetConfig() )
	on rlt_Configure close do (
		initDefaultVariables iniFile
		rlt_RelinkBitmaps.updateDefaultOptions()
	)

	on btn_browse pressed do (
		if (f = getSavePath()) != undefined then
			edt_default_browse.text = (f as string)
	)

	on rlt_Configure open do (
		chk_default_recursiveSubfolders.checked = uev_recursiveSubfolders
		chk_default_ignoreCase.checked = uev_ignoreCase
		chk_default_ignoreExtension.checked = uev_ignoreExtension
		chk_default_lowMemory.checked = uev_lowMemory
		chk_default_searchMaxFilePath.checked = uev_searchMaxFilePath
		chk_default_readOnlySupport.checked = uev_readOnlySupport
		edt_default_browse.text = uev_defaultSearchDirectory
	)

	on btn_saveConfiguration pressed do (
		saveDefaultVariables iniFile
		closeDialog rlt_Configure
	)
)

-- Rollout for Missing Maps
rollout rlt_MissingBitmaps "Missing Bitmaps" (
	edittext edt_filePath "" offset:[0,5] height:22

	listBox lst_MissingBitmaps "Missing Files:" items:#() height:30 offset:[0,5]
	edittext edt_find "Find in Material: " width:250 height:20
	button btn_find "Find" offset:[-75,-24] height:19 width:50
	button btn_findHelp "?" offset:[-35,-24] height:19
	button btn_refresh "Refresh" offset:[10,-24] height:19

	label lbl_space1 "" offset:[0,-15]

	-- Tools
	groupBox grp_tools "Tools"  height:50 offset:[-9,0] width:(rlt_MissingBitmaps.width - 10)
	button btn_stripPaths "Strip Missing Paths" align:#left offset:[0,-(grp_tools.height - 15)] height:18
	button btn_OutputList "Output List" align:#left offset:[110,-23] height:18
	button btn_ClearAllMissingBitmaps "Delete All missing bitmaps" align:#left offset:[183,-23] height:18
	button btn_CheckForUpdate "Check for Update" align:#left offset:[325, -23] height:18

	on btn_refresh pressed do ( rlt_MissingBitmaps.updateMissingMaps() )
	on rlt_MissingBitmaps close do ( closeRelinkBitmapsDialogs() )
	on rlt_MissingBitmaps open do (	rlt_MissingBitmaps.updateMissingMaps() )

	on rlt_MissingBitmaps resized size do (
		edt_filePath.width = size.x - 30
		lst_MissingBitmaps.width = size.x - 30

		grp_tools.width = size.x - 9
	)

	on btn_CheckForUpdate pressed do (
		-- Check for an updated version
		if (needUpdate versionXmlFile "version_data") then (
			-- User needs an update
			if queryBox "There's a newer version of Relink Bitmaps, would you like to go to the site now?" title:"Update available" then (
				ShellLaunch relinkBitmapsWebpage ""
			)
		) else (
			-- User doesn't need an update
			MessageBox "No newer version found."
		)
	)

	on btn_stripPaths pressed do (
		if (queryBox "Strip paths from missing bitmaps?" beep:false) == true then (
			undo "Strip Paths" on (
				bmaps = returnMissingBitmaps allMaps:(rlt_RelinkBitmaps.chk_allMaps.checked)
				for b in bmaps do setProperty b.asset (b.filenameFieldPropertyName) (newFilenameFrompath b.filenameProp)
			)
			rlt_MissingBitmaps.updateMissingMaps()
		)
	)

	on btn_ClearAllMissingBitmaps pressed do (
		-- User clicked "Delete All missing bitmaps"
		if (queryBox "Are you sure you want to permanently delete all missing bitmaps? (Does not work with the \"All Maps\" option)") then (
			local missingMaps = returnMissingBitmaps allMaps:(rlt_RelinkBitmaps.chk_allMaps.checked)

			for i = 1 to missingMaps.count do (
				try (
					setProperty (missingMaps[i].asset) (missingMaps[i].filenameFieldPropertyName) ""
				) catch (
					format "Relink Bitmaps:: Problem setting the map [%] property [%] to \"\"" (missingMaps[i].asset as string) (missingMaps[i].filenameFieldPropertyName as string)
				)
			)
			rlt_MissingBitmaps.updateMissingMaps()
		)
	)

	on btn_find pressed do (
		if edt_find.text != "" then (
			findBitmap edt_find.text
		) else
			messageBox "Please type in all or part of the filename you wish to search for, or click the '?' for more information"
	)

	on btn_OutputList pressed do (
		if (f = getSaveFileName caption:"Save as" filename:("C:\\_MissingBitmaps.txt") types:"Text(*.txt)") != undefined then (
			if (fs = openFile f mode:"wt" encoding:#utf8) != undefined then (
				for s in lst_MissingBitmaps.items do
					format "%\n" s to:fs
				close fs
			)
		)
	)

	on btn_findHelp pressed do (
		local message = ""
		message += "Find Bitmaps by Name or Path\n"
		message += "\n"
		message += "   Allows the user to type in any part of the filename or path (case-insensitive)\n"
		message += "   and populates the material editor with the materials dependent on the string.\n"
		message += "\n"
		message += "Instructions:\n"
		message += "1. Type all or part of a filename or path and press find\n"
		message += "2. Check the material editor for all materials that are dependent on your search string\n"
		message += "\n"
		message += "For example:  typing \"Brick.jpg\" will populate the material editor\n"
		message += "                       with all materials with \"Brick.jpg\" in the filename\n"
		message += "\n"
		message += "For example:  typing \"bri\" will populate the material editor with all bitmaps\n"
		message += "                       with a file or pathname containing \"bri\" including \"brick.jpg\",\"redbrick.jpg\",\"brick_bump.jpg\", etc.\n"
		message += "\n"
		message += "For example:  typing \"c:\\\" will populate the material editor with all bitmaps\n"
		message += "                       that have \"c:\\\" in their path allowing you to change them manually."
		messageBox message beep:false
	)

	on lst_MissingBitmaps selected i do (
		edt_filePath.text = lst_MissingBitmaps.items[i]
	)

	on lst_MissingBitmaps doubleClicked i do (
		map = (returnMissingBitmaps allMaps:rlt_RelinkBitmaps.chk_allMaps.checked)[i]
		obj = for d in (refs.dependents map.asset) where (isKindOf d GeometryClass) collect d
		clearSelection()
		try ( select obj ) catch ()
		edt_filePath.text = lst_MissingBitmaps.items[i]
		edt_find.text = (newFilenameFromPath map.filenameProp)
	)

	-- Updates the list of Bitmaps
	fn updateMissingMaps = (
		-- filenameArr is the full filenames
		filenameArr = for b in returnMissingBitmaps allMaps:(rlt_relinkBitmaps.chk_allMaps.checked) collect (b.filenameProp + "      [" + b.asset as string + "]")
		lst_MissingBitmaps.items = filenameArr
	)
)

rollout rlt_donate "Donate" (
	button img_donate width:255 height:152 offset:[0,0]
	button btn_donate "Donate" width:80 offset:[22,5] align:#left
	button btn_close "Close" width:80 offset:[-21,-26] align:#right

	on img_donate pressed do (
		if (banner_image_url != undefined) then (
			ShellLaunch banner_image_url ""
		)
	)

	on rlt_donate open do (
		if doesFileExist banner_image_path then (
			local bmap = openBitmap banner_image_path
			img_donate.images = #(bmap, undefined, 1,1,1,1,1 )
		)
	)

	on btn_donate pressed do (
		createDialog rlt_donateRequest 310 140
		shellLaunch donateURL ""
	)

	on btn_close pressed do (
		closeDialog rlt_donate
	)
)

createDialog rlt_RelinkBitmaps relinkBitmapsWindowWidth relinkBitmapsWindowHeight style:#(#style_resizing,#style_titlebar, #style_border, #style_sysmenu)