//
//  Auer_NotesApp.swift
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

import SwiftUI

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    var dataModel: DataModel?
    
    // save data when the app is closed
    func applicationWillTerminate(_ aNotification: Notification) {        
        //print("app closing, going thru files...")
        for index in 0..<(dataModel?.notes.count)! {
            //print("index = \(index)", dataModel?.notes[index].filename ?? "no filename")
            if dataModel?.notes[index].changed == true {
                saveFile(filename: (dataModel?.notes[index].filename)!, contents: (dataModel?.notes[index].text)!)
                dataModel?.notes[index].changed = false
            }
            
        }
    }
    
    // close the app when user closes the window
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
    }
    
    // do we want this?
    /*func applicationDidFinishLaunching(_ notification: Notification) {
        var sideBarSate: Bool = true
        // hide the sidebar if the user had it hidden
        sideBarSate = UserDefaults.standard.bool(forKey: "sideBarState")
        print(">>Sidebar State: ", sideBarSate)
        if !sideBarSate {
            print(">>Setting Sidebar State to: ", sideBarSate )
            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        }
    }*/
}
#endif

@main
struct Auer_NotesApp: App {
    
    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    
    // injecting this here so we can loop thru it an save text
    // to files when .changed = true
    private let dataModel = DataModel()
    @State var showsAlert = false
    @State private var isShowingSheet = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(isShowingSheet: $isShowingSheet)
                //.environmentObject(DataModel())
                .environmentObject(self.dataModel)
                .frame(minWidth: 560, maxWidth: .infinity,
                           minHeight: 300, maxHeight: .infinity)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    #if os(macOS)
                    appDelegate.dataModel = self.dataModel  // << here !!
                    #endif
                    // check if there are files to load
                    // if there are none, do not try to load file
                    // this fixes a bug for first time running where the
                    // view would fail to be drawn correctly if no file
                    // were there. Simple hack
                    // if saveDirectory is not set get out
                    if getCurrentSaveDirectory(for: "savedDirectory") != "" {
                        if !isDirectoryEmpty() {
                            loadFiles(dataModel: self.dataModel)                        
                        }
                    } else {
                        print("first time running") // maybe ask where to save files here?                        
                    }
                }
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
        .windowStyle(HiddenTitleBarWindowStyle())
        //.windowStyle(DefaultWindowStyle())
        //.windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: true))
        .commands {
            SidebarCommands()
            ToolbarCommands()
            TextEditingCommands()
            //TextFormattingCommands()
            CommandGroup(replacing: CommandGroupPlacement.printItem){}
            CommandGroup(replacing: CommandGroupPlacement.help) {}
            CommandGroup(replacing: CommandGroupPlacement.toolbar) {}
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}

            CommandGroup(after: CommandGroupPlacement.newItem) {
                Button("Reload Notes") {
                    if getCurrentSaveDirectory(for: "savedDirectory") != "" {
                        if !isDirectoryEmpty() {
                            // make sure we remove the notes first from the list to prevent double listing
                            self.dataModel.notes.removeAll()
                            loadFiles(dataModel: self.dataModel)
                            print(">> Notes reloaded ")
                        }
                    }
                }
            }
                        
            CommandMenu("Info") {
                Button(action: {
                    //showInFinder(url: URL(string: getDir()))
                    if showInFinder(url: URL(string: getDir())) == false {
                        self.showsAlert = true
                    }
                }, label: {
                    Text("Open Notes Directory")
                })
                .alert(isPresented: self.$showsAlert) {
                    Alert(title: Text("Auer Notes"), message: Text("Could not open directory."), dismissButton: nil)
                }
                
                Button("Get Notes Info") { // add here a call to info()
                    print("getting info")
                    isShowingSheet.toggle()
                }
            }
            
            CommandMenu("Find") {
                Button("Find in notes") { // add here a call to info()
                    print("searching...")
                    //searchFieldIsFocused = true
                    if let toolbar = NSApp.keyWindow?.toolbar, let search = toolbar.items.first(where: {
                        $0.itemIdentifier.rawValue == "com.apple.SwiftUI.search"                        
                    }) as? NSSearchToolbarItem {
                        search.beginSearchInteraction()
                    }
                }.keyboardShortcut("l")
            }
        }
        //.windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
        
        Settings {
            SettingsView()
                .frame(width: 400, height: 200)
                .environmentObject(self.dataModel)
        }
        
    }
    
    /*class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            print("hello")
        }
    }*/
}
