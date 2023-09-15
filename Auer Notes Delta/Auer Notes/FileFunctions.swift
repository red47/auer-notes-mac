//
//  FileFunctions.swift
//  Auer Notes
//
//  Created by Uri Fridman on 8/12/21.
//
//  Released under MIT License
//
//  Copyright (c) 2021 Uri Fridman
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import SwiftUI
import os


func getCurrentSaveDirectory(for key: String) -> String {
    print("Getting dir... ")
    if let data = UserDefaults.standard.data(forKey: key)
    {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, options:[.withSecurityScope], bookmarkDataIsStale: &isStale)
            print("Current save dir is: ", url.path)
            return url.path
        } catch {
            print("Error getting current directory")
            return ""
        }
    }
    print("nothing to do ")
    return ""
}

func resolveURL(for key: String) throws -> URL {
    if let data = UserDefaults.standard.data(forKey: key) {
        var isStale = false
        let url = try URL(resolvingBookmarkData: data, options:[.withSecurityScope], bookmarkDataIsStale: &isStale)
        if isStale {
            let newData = try url.bookmarkData(options: [.withSecurityScope])
            UserDefaults.standard.set(newData, forKey: key)
        }
        return url
    } else {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select a folder"
        panel.message = "Choose a folder to store your notes"
        if panel.runModal() == .OK,
           let url = panel.url {
            let newData = try url.bookmarkData(options: [.withSecurityScope])
            UserDefaults.standard.set(newData, forKey: key)
            return url
        } else {
            throw ResolveError.cancelled
        }
    }
}

private func delaySave(filename: String, contents: String) {
    // Delay of 5 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        saveFile(filename: filename, contents: contents)
    }
}


func saveFile(filename: String, contents: String) {
    let customLog = Logger(subsystem: "com.auernotes.auernotes", category: "Debug")
    do {
        let directoryURL = try resolveURL(for: "savedDirectory")
        let documentURL = directoryURL.appendingPathComponent (filename + ".txt")
        print("saving " + documentURL.absoluteString)
        customLog.debug("saving \(documentURL.absoluteString)")
        try directoryURL.accessSecurityScopedResource(at: documentURL) { url in
            //print("checking" + url.absoluteString)
            //if fileExists(filename: url.absoluteString) {
            //    print("file exists...")
                try contents.write (to: url, atomically: false, encoding: .utf8)
           // }
        }
        
    } catch let error as ResolveError {
        customLog.debug("Resolve error: \(error.localizedDescription)")
        print("Resolve error:", error)
    } catch {
        customLog.debug("error: \(error.localizedDescription)")
        print(error)
    }
}

func deleteFile(filename: String) -> Bool {
    do {
        let directoryURL = try resolveURL(for: "savedDirectory")
        let documentURL = directoryURL.appendingPathComponent (filename + ".txt")
        print("Deleting \(documentURL.absoluteString)")
        let manager = FileManager.default
        try directoryURL.accessSecurityScopedResource(at: documentURL) { url in
            try manager.removeItem(at: url)
        }
        return true
    } catch let error as ResolveError {
        print("Resolve error:", error)
        return false
    } catch {
        print(error)
        return false
    }
}

// check if current title != filename in the struct
// struct has original filename w/out extension
func renameFile (origFilename: String, newFilename: String) -> Bool {
    do {
        let directoryURL = try resolveURL(for: "savedDirectory")
        let documentURL = directoryURL.appendingPathComponent (origFilename + ".txt")
        let documentURLNew = directoryURL.appendingPathComponent (newFilename + ".txt")
        print("renaming \(documentURL.path) to \(documentURLNew.path)")
        let manager = FileManager.default
        try directoryURL.accessSecurityScopedResource(at: documentURL) { url in
            try directoryURL.accessSecurityScopedResource(at: documentURLNew) { newurl in
                if fileExists(filename: documentURL.path) {
                    try manager.moveItem(at: url, to: newurl)
                } else {
                    print("file \(documentURL.path) does not exist")
                }
            }
        }
        return true
    } catch let error as ResolveError {
        print("Resolve error:", error)
        return false
    } catch {
        print(error)
        return false
    }
}


func isDirectoryEmpty() -> Bool {
    let customLog = Logger(subsystem: "com.auernotes.auernotes", category: "Debug")
    do {
        let directoryURL = try resolveURL(for: "savedDirectory")
        if directoryURL.startAccessingSecurityScopedResource() {
            let contents = try FileManager.default.contentsOfDirectory(at: directoryURL,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
            let textfile = contents.filter { $0.path.hasSuffix(".txt") }
            
            if textfile.count != 0 {
                print("found:", textfile.count)
                return false
            } else {
                customLog.debug("Auer: No files found to load")
                print("no files found")
                return true
            }
        } else {
            customLog.debug("Security access error")
            print("error: couldn't get set StartAccessingSecurity")
            return true
        }
    } catch let error as ResolveError {
        customLog.debug("Auer Resolve error while checking files: \(error.localizedDescription)")
        print("Resolve error:", error)
        return true
    } catch {
        customLog.debug("Auer error while checking files: \(error.localizedDescription)")
        print(error)
        return true
    }
}


func loadFiles(dataModel: DataModel) {
    var text: String = ""
    var title: String = ""
    var date: Date
    
    do {
        let directoryURL = try resolveURL(for: "savedDirectory")
        if directoryURL.startAccessingSecurityScopedResource() {
            let contents = try FileManager.default.contentsOfDirectory(at: directoryURL,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
            // load the files here
            for file in contents {
                //print(file.absoluteString)
                
                // 1. read file content -> .text
                // 2. get modified date -> .date
                // 3. extract filename/title from the path -> filename
                text = readFile(filename: file.path)
                date = getModifiedDate(filename: file.absoluteURL)
                title = text.components(separatedBy: NSCharacterSet.newlines).first!
                dataModel.notes.append(NoteItem(id: UUID(), text: text, date: date, tags: [], filename: title))
                dataModel.sortList()
                //print(date)
                //print("loading: " + title)
            }
            directoryURL.stopAccessingSecurityScopedResource()
        } else {
            Alert(title: Text("Couldn't load notes"),
                  message: Text("Make sure the directory where the notes are stored is accessible."),
                  dismissButton: .default(Text("OK")))
        }
        
        
    } catch let error as ResolveError {
        print("Resolve error:", error)
        return
    } catch {
        print(error)
        return
    }
}


func readFile(filename: String) -> String {
    //print("working on file: "+filename)
    do {
        let contents = try String(contentsOfFile: filename, encoding: .utf8)
        //print(contents)
        return contents
    } catch {
        print(error)
        return ""
    }
}

// get the modified date of the file
func getModifiedDate(filename: URL) -> Date {
    do {
        let fileURL: URL = filename
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let modificationDate = attributes[.modificationDate] as! Date
        return modificationDate
    } catch {
        print(error)
        return Date()
    }
}

func fileExists(filename: String) -> Bool {
    let manager = FileManager.default
    
    if manager.fileExists(atPath: filename) {
       return true
    }
    return false
}


/*func saveNewFile(filename: String) {
    let contents = "Some text..."
    @AppStorage("filesDirectory") var filesDirectory: String = ""

    print("saving in: \(filesDirectory)")

    do
    {
        /*let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
          filesDirectory = panel.url?.path ?? "<none>"
        }*/

        let directoryURL: URL = URL(fileURLWithPath: filesDirectory)

        let documentURL = directoryURL.appendingPathComponent (filename + ".txt")
        print(documentURL)

        try contents.write (to: documentURL, atomically: false, encoding: .utf8)
    }
    catch
    {
        print("An error occured: \(error)")
    }
}*/


func saveFileToAppSupportDir(filename: String, contents: String) {
    do
    {
        let fileManager = FileManager.default
        //  Find Application Support directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        //  Create subdirectory
        let directoryURL = appSupportURL.appendingPathComponent("auer.notes")
        try fileManager.createDirectory (at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        //  Create document
        let documentURL = directoryURL.appendingPathComponent (filename + ".txt")
        print(documentURL)
        try contents.write (to: documentURL, atomically: false, encoding: .utf8)
    }
    catch
    {
        print("An error occured")
    }
}

// get current directory where notes are being saved
func getDir() -> String {
    return "\(getCurrentSaveDirectory(for: "savedDirectory"))"
}

// open finder on the directory where the notes are saved
func showInFinder(url: URL?) -> Bool{
    guard let url = url else {
        print("returning... URL nil ")
        return false
    }
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    return true
}
