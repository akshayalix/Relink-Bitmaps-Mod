/**************************************************/
/*  C_LIBRARY                                                     */
/**************************************************/ 

global VRayEnabled
global MREnabled
global returnAllDirectories
global returnAllFiles
global getDirsRecursive
global newFilenameFromPath
global debug 
global fdebug
global returnSavedPosition
global saveCurrentPosition
global openDialog
global openRolloutNextTo
global closeDialog
global lowercase
global trim_dups
global printAllProperties
global returnXmlValue
global getDependentsOfType
global stripExtension
global TryGetFilenameFile

-- returns true if vray is the current renderer
fn VRayEnabled = if (matchPattern (renderers.current as string) pattern:"*V_Ray*" ignoreCase:true) then true else false

-- returns true if mental ray is the current renderer
fn MREnabled = if (matchPattern (renderers.current as string) pattern:"*mental_ray*" ignoreCase:true) then true else false

-- Returns the full array of directories from root (d)
fn returnAllDirectories d = (
	a = #()
	for b in d do
		join a (getDirsRecursive b)
	join a d
	a
) 

--------------------------------
-- FUNCTION: 
-- NAME: getDependentsOfType
-- PURPOSE: Takes an array (arr) of objects and finds the dependents of a certain type (type)
-- RETURNS: array of dependents of the specified type
--------------------------------
fn getDependentsOfType arr type = (
	local returnArray = #()
	for a in arr do (
		for d in (refs.dependents a) where (isKindOf d type) do (
			append returnArray d
		)
	)
	returnArray
)

-- Returns the full array of files from directory
fn returnAllFiles d = (
	f = #()
	for a in d do
		join f (getFiles (a + "\\*.*"))	
	f
)

-- Function for getting each directory
fn getDirsRecursive root = (
	if root != "" then (
		dir_array = GetDirectories (root+"/*")

		for d in dir_array do 
			join dir_array (GetDirectories (d+"/*"))
		
		return dir_array
	)
	return undefined
)

fn stripExtension f =
(
	local index = 0
	local bFound = false
	
	for i = f.count to 1 by -1 do
	(
		if (f[i] == ".") and (bFound == false) then
		(
			bFound = true
			index = i
		)
	)
	
	-- No extension found, return original string
	if (bFound == false) then
	(
		return f
	)
	
	return (substring f 1 (index - 1))
)

-- 3dsmax's getfilenamefile throws an error if the filename begins with a '$', this is a workaround
fn TryGetFilenameFile s = 
(
	local result = ""
	try (
		result = (getFilenameFile s)
	)
	catch 
	(
		-- filename begins with a '$'
		result = (stripExtension s)
	)
	
	return result
)

-- filenameFromPath - my version compatible with max 2010 
fn newFilenameFromPath s = (
	f = (filterString (s as string) "\\/")
	f[f.count]	
)

-- debug - this function writes to the listener if the global variable "DebugOn" == true 
fn debug msg = ( 
	if debugOn then (
		format "_debug: \"%\"\n" (msg as string)
	) 
)

-- fdebug - this function writes to the listener if the global variable "DebugOn" == true, using an argument
--	msg: message to write 
--	a: argument to print as string
fn fdebug msg a = (	
	if debugOn then (
		format ("_debug: \"" + (msg as string) + "\"\n") (a as string) 
	)
)

-- returnSavedPosition - gets the saved position from file (f) 
--	returns a point2 value of the saved setting, [0,0] if not found
fn returnSavedPosition f = (
	savedPosition = undefined
	
	if not(doesFileExist f) then (
		-- Create and close the ini file
		if (n = createFile f) != undefined then close n
		savedPosition = (point2 0 0)
	) else (
		if (GetINISetting f "Position" "x") != "" and (GetINISetting f "Position" "y") != "" then
			savedPosition = point2 ((GetINISetting f "Position" "x") as integer) ((GetINISetting f "Position" "y") as integer)
		else 
			savedPosition = (point2 0 0)
	)
	savedPosition
)

-- saveCurrentPosition - writes the rollout's (r) position to the ini file (f) 
fn saveCurrentPosition r f = (
	setINISetting f "Position" "x" ((GetDialogPos r).x as string)
	setINISetting f "Position" "y" ((GetDialogPos r).y as string)
)

-- openDialog - checks to see if a rollout (r) is open, and if not opens it with width (w) and height (h)
fn openDialog r width: height: posX: posY: modal: = (
	if not(r.open) then (
		if (width == unsupplied) or (height == unsupplied) then createDialog r modal:modal
		else if (posX == unsupplied) or (height == unsupplied) then createDialog r width height modal:modal
		else createDialog r width height posX posY modal:modal
	)
)

--	openRolloutNextTo 
--	sRlt: source rollout
--	dRlt: destination rollout 
--	width: optional width
--	height: optional height
fn openRolloutNextTo sRlt dRlt width: height: style: modal: = (
	if not(dRlt.open) then (
		local thePos = (getDialogPos sRlt)
		local nx = (sRlt.width+0) + (thePos.x)
		
		if (width == unsupplied) or (height == unsupplied) then createDialog dRlt pos:[nx,thePos.y] modal:modal
		else createDialog dRlt width height pos:[nx,thePos.y] modal:modal style:style
	)
)

--	closeDialog closes an open rollout floater
--	r: rollout to close
fn closeDialog r = (	try ( destroyDialog r ) catch () )

-- BlurScripts by Neil Blevins
-- BSLib.ms
-- By Neil Blevins (neil@soulburn3d.com)
fn lowercase instring = (
	upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	lower="abcdefghijklmnopqrstuvwxyz" 
	outstring=copy instring 
	for i = 1 to outstring.count do (
		j=findString upper outstring[i]
		if (j != undefined) do outstring[i]=lower[j]
	)
	outstring
)

fn trim_dups a = (
	for i in a.count to 1 by -1 do (
		idx = findItem a a[i]
		if (idx != 0) AND (idx != i) do deleteItem a i
	)
	a
)

-- prints all of the properties and their values for a given object (o)
fn printAllProperties o = (
	for p in (getPropNames o) do
		format "%: %\n" p (getProperty o p)
)

fn returnXmlValue url s timeout:10000 = (
	local request = (dotnetclass "System.Net.WebRequest").Create url
	local credentials = (dotnetclass "System.Net.CredentialCache")
	local spManager = (dotnetclass "System.Net.ServicePointManager")
	
	spManager.Expect100Continue = true
	spManager.SecurityProtocol = (dotnetclass "System.Net.SecurityProtocolType").Tls12
	
	request.Credentials = credentials.DefaultCredentials
	
	request.Proxy = (dotnetclass "System.Net.WebProxy").GetDefaultProxy()
	request.Timeout = timeout
	
	try (
		local response = request.GetResponse()
		local stream = response.GetResponseStream()
	)
	catch (
		print "Relink Bitmaps: Error loading xml file."
		return undefined
	)

	local doc = dotNetObject "System.Xml.XmlDocument"
	doc.Load stream
	
	stream.Close()

	elementList = (doc.GetElementsByTagName s)
	xmlElement = elementList.ItemOf[0]
	XmlElement.innerText
)
