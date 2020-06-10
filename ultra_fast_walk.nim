import winim/lean, os, nimpy, times, winim/winstr, strutils

include "system/inclrtl"

template    getFilename(f: untyped): untyped =
            $cast[WideCString](addr(f.cFileName[0]))

proc    skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
        # Skip "." and ".." directory entries
        # Note - takes advantage of null delimiter in the cstring
        const dot = ord('.')
        result =  f.cFileName[0].int == dot and 
                ( f.cFileName[1].int == 0   or 
                  f.cFileName[1].int == dot and 
                  f.cFileName[2].int == 0 )
    
proc    walker*(    folderpath: string, extensions: seq[string] = @[""],
                    followlinks : bool = false, yieldfiles: bool = true): seq[string]
                    {.tags: [ReadDirEffect], exportpy.} =

    const dot = ord('.')
    let extused = extensions != @[""] and extensions.len > 0 # Optimization.
    
    var yieldFilter = {pcFile}
    var followFilter = {pcDir}
    var DateiData: WIN32_FIND_DATA
    var stack = @[""]
    var FileOrDirOrLink = pcFile
                    
    if yieldfiles: yieldFilter = {pcFile} else: yieldFilter = {pcDir}
    if followlinks: followFilter = {pcLinkToDir} else: followFilter = {pcDir}
    
    while stack.len > 0:
  
        let SubDirectory = stack.pop()

        var FileHandle = FindFirstFile(folderpath / SubDirectory / "*", DateiData)

        if FileHandle == -1:
          
            discard 
          
        else:
        
            defer: FindClose(FileHandle)
            
            while true:
                
                    if not  ( DateiData.cFileName[0].int   == dot and 
                              ( DateiData.cFileName[1].int == 0 or 
                                ( DateiData.cFileName[1].int == dot and 
                                  DateiData.cFileName[2].int == 0 )
                              )
                            ):
                    
                        if (DateiData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
                            FileOrDirOrLink = pcDir
                            
                        if (DateiData.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
                            FileOrDirOrLink = succ(FileOrDirOrLink)

                        var PathOrDatei = extractFilename(getFilename(DateiData))
                        
                        let RelativePath = SubDirectory / PathOrDatei
                        
                        if FileOrDirOrLink in {pcDir, pcLinkToDir} and FileOrDirOrLink in followFilter:
                            stack.add RelativePath
                            
                        if FileOrDirOrLink in yieldFilter:
                            PathOrDatei = folderpath / RelativePath
                            
                            if unlikely(extused):
                                for ext in extensions:
                                    if PathOrDatei.normalize.endsWith(ext): result.add PathOrDatei
                            else: result.add PathOrDatei
                    
                    if FindNextFile(FileHandle, DateiData) == 0'i32:
                    
                        let errCode = GetLastError()
                        
                        if errCode == ERROR_NO_MORE_FILES: break
                        else: raiseOSError(errCode.OSErrorCode)