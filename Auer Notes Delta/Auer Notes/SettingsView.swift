//
//  SettingsView.swift
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

struct SettingsView: View {
    @State var directoryText: String = "Folder not set yet."
    @State var showsAlert = false
    //private let dataModel = DataModel()
    //@StateObject private var dataModel = DataModel()
    @EnvironmentObject private var data: DataModel
    
    var body: some View {
        VStack (alignment: .leading) {
            VStack (alignment: .leading) {
                Text("Saving notes in:")
                    //.padding(3)
                    .font(.body.bold())
                
                HStack {
                    //Text("Saving notes in: \(getCurrentSaveDirectory(for: "savedDirectory"))")
                    Text(directoryText)
                        .font(.body)
                        .padding(0.5)
                        .onAppear(){
                            directoryText = getCurrentSaveDirectory(for: "savedDirectory")
                            if directoryText == "" {
                                directoryText = "Fodler not set yet."
                                print("!!! fist time running")
                            }
                        }
                    Spacer()
                }
            
            }
            .padding(.bottom, 20)
            
            Text("Auer Notes needs a folder to save the notes.")
                .font(.footnote)
                .padding(.top, 5)
                //.padding(.bottom, 5)
            Text("If none is yet set, please select one.")
                .font(.footnote)
                //.padding(.top, 5)
                .padding(.bottom, 15)
                        
            HStack {
                Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        panel.canChooseFiles = false
                        panel.title = "Select a folder"
                        panel.message = "Choose a folder to store your notes"
                        if panel.runModal() == .OK,
                           let url = panel.url {
                            do {
                                let newData = try url.bookmarkData(options: [.withSecurityScope])
                                debugPrint("Setting directory... \(url.absoluteString)")
                                UserDefaults.standard.set(newData, forKey: "savedDirectory")
                                directoryText = "\(getCurrentSaveDirectory(for: "savedDirectory"))"
                                if !isDirectoryEmpty() {
                                    debugPrint("Loading files found in directory...")
                                    data.notes.removeAll()
                                    loadFiles(dataModel: data)
                                }
                                if directoryText == "" {
                                    directoryText = "Not set yet."
                                    print("!!! some issues seeting a directory")
                                }
                            } catch {
                                print("error")
                            }
                        }
                        //directoryText = "\(getCurrentSaveDirectory(for: "savedDirectory"))"
                        
                    }) {
                        Text("Select a Folder")
                    }
                Spacer()
                
                Button("Open Notes Folder") {
                    if showInFinder(url: URL(string: getDir())) == false {
                        self.showsAlert = true
                    }
                    
                }
                .alert(isPresented: self.$showsAlert) {
                    Alert(title: Text("Auer Notes"), message: Text("Could not open directory."), dismissButton: nil)
                                        
                }
                //.buttonStyle(BorderlessButtonStyle())
            }
            
            Spacer()
            
            // for debugging only. Uncomment to add a button to reset the app
            /*Button("DEBUG: Reset UserDefault") {
                debugPrint("Removing all notes from data model")
                data.notes.removeAll()
                debugPrint("unsetting directory")
                UserDefaults.standard.removeObject(forKey: "savedDirectory")
            }*/

        }
        //.frame(width: 350, height: 250, alignment: .topLeading)
        .frame(width: 350, height: 150)
    }
    
    func getDir() -> String {
        return "\(getCurrentSaveDirectory(for: "savedDirectory"))"
    }
    
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
