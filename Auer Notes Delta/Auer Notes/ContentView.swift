//
//  ContentView.swift
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

struct NoteItem: Codable, Hashable, Identifiable {
    let id: UUID
    var text: String
    var date = Date()
    var dateText: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d yyyy, h:mm a"
        return df.string(from: date)
    }
    var tags: [String] = []
    var filename: String = ""
    var changed: Bool = false
}


extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        /*guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result*/
        
        return "[]"
    }
}

extension View {
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}

enum ResolveError : Error { case cancelled  }

extension URL {
    func accessSecurityScopedResource<Value>(at url : URL, accessor: (URL) throws -> Value) rethrows -> Value {
        let didStartAccessing = startAccessingSecurityScopedResource()
        defer { if didStartAccessing { stopAccessingSecurityScopedResource() }}
        return try accessor(url)
    }
}


// we init the object by sorting it by date and
// we export a function that lets us sort it when needed
final class DataModel: ObservableObject {
    @AppStorage("auernotes") public var notes: [NoteItem] = []
    //public var notes: [NoteItem] = []
    init() {
        self.notes = self.notes.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
    }
    
    func sortList() {
        self.notes = self.notes.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
    }
    
    /*func checkFilesToSave() {
        for index in 0..<(self.notes.count-1) {
            print(">>> \(self.notes[index].filename)")
        }
    }*/
}


struct ContentView: View {
    @State var selection: Set<Int> = [0]
    @State var sideBarSate: Bool = true
    @Binding var isShowingSheet: Bool
    @EnvironmentObject private var data: DataModel
    @State var directoryText: String = "Folder not set yet."
    @State var showsAlert = false

    var body: some View {
        AllNotes()
        // show information
        .sheet(isPresented: $isShowingSheet) {
            VStack (alignment: .leading) {
                VStack (alignment: .leading) {
                    Text("Information")
                        .font(.title2)
                        .padding(.bottom)
                    
                    Text("Note count: " + String(data.notes.count) + " notes")
                        //.font(.body.bold())
                        .padding(.bottom)

                    Text("Saving notes in:")
                        //.font(.body.bold())

                    Text(directoryText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(0.5)
                        .onAppear(){
                            directoryText = getCurrentSaveDirectory(for: "savedDirectory")
                            if directoryText == "" {
                                directoryText = "Fodler not set yet, set it on the preferences window."
                            }
                        }
                
                }
                
                HStack {
                    Button("Open Notes Folder") {
                        if showInFinder(url: URL(string: getDir())) == false {
                            self.showsAlert = true
                        }
                        
                    }
                    .buttonStyle(DefaultButtonStyle())
                    .alert(isPresented: self.$showsAlert) {
                        Alert(title: Text("Auer Notes"), message: Text("Could not open directory."), dismissButton: nil)
                                            
                    }
                    
                    Spacer()
                    Button("Close") {
                        isShowingSheet.toggle()
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(DefaultButtonStyle())
                    
                }
            }
            .frame(width: 350, height: 200, alignment: .leading)
            .padding()
        }

    }
    
    /*func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        // save the sidebar state. Fixes a swiftui bug
        sideBarSate = !sideBarSate
        print("saving sidebar state: ", sideBarSate)
        if sideBarSate {
            UserDefaults.standard.set(true, forKey: "sideBarState")
        } else {
            UserDefaults.standard.set(false, forKey: "sideBarState")
        }
    }*/

}

struct AllNotes: View {
    
    @EnvironmentObject private var data: DataModel
    
    @State var noteText: String = ""
    @State var selection: Int?
    @State var selectedNoteId: UUID?
    @State var currentNoteId: UUID?
    @State private var selectedItem: NoteItem? = nil
    @State var searchText: String = ""
    @State var sideBarSate: Bool = true
    @State private var enableEmailShare = true // set to false to hide it
    
    //@Environment(\.dismissSearch) var dismissSearch

    @FocusState private var searchFieldIsFocused: Bool
    
    @State var showAlert = false
    var alert: Alert {
        Alert(title: Text("About to delete a note"),
              message: Text("Are you sure you want to delete this note? This can't be undone."),
              primaryButton: .destructive(Text("Delete"), action: removeNote),
              secondaryButton: .cancel())
    }
    
    @State private var query: String = ""
    
    var body: some View {
        NavigationView {
            // filter them by the search text
            List(filteredNotes) { note in
                NavigationLink(
                    destination: NoteView(note: note, text:note.text),
                    tag: note.id,
                    selection: $selectedNoteId
                ) {
                    VStack(alignment: .leading) {
                        Text(getTitle(noteText: note.text)).font(.body).fontWeight(.bold)
                        Text(note.dateText).font(.body).fontWeight(.light)
                    }
                    .padding(.vertical, 10)
                }
            }
            /*.searchable(
                text: $searchText,
                placement: .toolbar,
                prompt: "Search..."
            )*/
            //.listStyle(InsetListStyle())
            .frame(minWidth: 250, idealWidth: 250, maxWidth: .infinity)
            .alert(isPresented: $showAlert, content: {
                alert
            })
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                            Image(systemName: "sidebar.left") }).help("Toggle Sidebar")
                }

                ToolbarItem(placement: .principal) {
                    Button(action: {
                        searchText = ""
                        data.notes.append(NoteItem(id: UUID(), text: "", date: Date(), tags: [], filename: ""))
                        data.sortList()
                        //selectedNoteId = data.notes.first?.id
                        DispatchQueue.main.async {
                            selectedNoteId = data.notes.first?.id
                        }
                    }) {
                        Image(systemName: "square.and.pencil")
                    }.keyboardShortcut("n", modifiers: [.command]).help("New Note")
                }
                
                ToolbarItem(placement: .principal) {
                        Spacer()
                }
                
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        if !data.notes.isEmpty {
                            self.showAlert = true
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .keyboardShortcut(.delete, modifiers: []).help("Delete Note")
                    .onDeleteCommand(perform: { // This works when clicking in the menu
                        if !data.notes.isEmpty {
                            self.showAlert = true
                        }
                    })
                }
                
                
                // to trick the search field to get smaller... fucking swiftUI sucks
                /*ToolbarItemGroup {
                    Button("") {}
                    .frame(width: 200)
                    .buttonStyle(.plain)
                }*/

                ToolbarItem(placement: .navigation) {
                    Spacer()
                }

                // share with email button: TODO add option to show in the pref window
                /*ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: {
                            if let selection = selectedNoteId,
                                let selectionIndex = data.notes.firstIndex(where: { $0.id == selection }) {
                                
                                let email = ""
                                let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
                                sharingService?.recipients = [email]
                                sharingService?.subject = getTitle(noteText: data.notes[selectionIndex].text)
                                let items: [Any] = [data.notes[selectionIndex].text]
                                sharingService?.perform(withItems: items)
                            }
                        }) {
                            Label("Email Note", systemImage: "envelope")
                            /*Image(systemName: "envelope")
                            Text("Email Note")*/
                        }
                        .disabled(enableEmailShare == false) //to enable it or disable it when selecting in the config
                        .hidden(!enableEmailShare)
                        /*Button(action: {
                            if let selection = selectedNoteId,
                                let selectionIndex = data.notes.firstIndex(where: { $0.id == selection }) {
                                print("Printing...", data.notes[selectionIndex].text)
                                
                            }
                        }) {
                            Label("Print note", systemImage: "printer")
                        }*/
                    }
                    label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .menuIndicator(.hidden)
                    
                }*/
                
                /*ToolbarItem(placement: .navigation) {
                    Spacer()
                }*/

                
               /* ToolbarItem(placement: .automatic) {
                    Button(action: {
                        if let selection = selectedNoteId,
                           let selectionIndex = data.notes.firstIndex(where: { $0.id == selection }) {
                            
                            let email = ""
                            let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
                            sharingService?.recipients = [email]
                            sharingService?.subject = getTitle(noteText: data.notes[selectionIndex].text)
                            let items: [Any] = [data.notes[selectionIndex].text]
                            sharingService?.perform(withItems: items)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Share by email")
                    .disabled(enableEmailShare == false) //to enable it or disable it when selecting in the config
                    .hidden(!enableEmailShare)
                }*/

                /*ToolbarItem(placement: .automatic) {
                    Spacer()
                }*/
                
                // text will be used above to filter the list
                /*ToolbarItem(placement: .automatic) {
                    TextField("Search...", text: $searchText)   // also try SearchField declared above
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 200)
                        .focused($searchFieldIsFocused)
                        .keyboardShortcut("k", modifiers: [.command])
                }*/
                                            
            }

            Text("Select a note or create a new one.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        //.navigationTitle("")        
        //.navigationViewStyle(DoubleColumnNavigationViewStyle())
        //.searchable(text: $searchText)
        .searchable(
            text: $searchText,
            placement: .automatic,
            prompt: "Search..."
        )
        .onAppear {
            DispatchQueue.main.async {
                selectedNoteId = data.notes.first?.id
            }
        }
        .onChange(of: data.notes) { notes in
            if selectedNoteId == nil || !notes.contains(where: { $0.id == selectedNoteId }) {
                selectedNoteId = data.notes.first?.id
                print(">>>Note changed")
            }
        }
                
    }
            
    var filteredNotes: [NoteItem] {
        data.notes.filter {
            searchText.isEmpty ? true : $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        // save the sidebar state. Fixes a swiftui bug
        /*sideBarSate = !sideBarSate
        print("saving sidebar state: ", sideBarSate)
        UserDefaults.standard.set(sideBarSate, forKey: "sideBarState")*/
    }

    func removeNote() {
        if let selection = selectedNoteId,
           let selectionIndex = data.notes.firstIndex(where: { $0.id == selection }) {
            //print("DEBUG: delete item: \(selectionIndex)")
            let res = deleteFile(filename: data.notes[selectionIndex].filename)
            print(res)
            data.notes.remove(at: selectionIndex)
        }
    }
    
    // get the title (first line) of the note
    func getTitle(noteText: String) -> String {
        let title: String = noteText.components(separatedBy: NSCharacterSet.newlines).first!
        //debugPrint(">>> Title: " + title)
        if title.isEmpty {
            return "No Title"
        }
        return title
    }
}


struct NoteView: View {
    @EnvironmentObject private var data: DataModel
    var note: NoteItem
    @State var text: String
    
    enum FocusField: Hashable {
        case field
    }
    @FocusState private var focusedField: FocusField?
    
    @State private var hasTimeElapsed = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                TextEditor(text: $text)
                    .disableAutocorrection(false)
                    .font(.system(size: 14.0))
                    .lineSpacing(3)
                    .onDisappear() {
                        guard let index = data.notes.firstIndex(of: note) else { return }
                        if data.notes[index].changed {
                            data.notes[index].changed = false
                            saveFile(filename: data.notes[index].filename, contents: data.notes[index].text)
                        }
                    }
                    .onChange(of: text, perform: { value in
                        guard let index = data.notes.firstIndex(of: note) else { return }
                        let origTitle = getTitle(noteText: data.notes[index].filename)
                        print("### original title: ", origTitle)
                        print("### new title: ", getTitle(noteText: value))
                        // check if the tile changed.
                        // TODO: take this our of the .onChange, it renames the file with each key press
                        if origTitle != getTitle(noteText: value) {
                            print("### Title changed, renaming file")
                            if !renameFile(origFilename: origTitle, newFilename: getTitle(noteText: value)) {
                                print("## error renaming file")
                            }
                        }
                        data.notes[index].text = value
                        data.notes[index].date = Date()
                        data.notes[index].filename = value.components(separatedBy: NSCharacterSet.newlines).first!
                        data.notes[index].changed = true // so we can automatically save it
                        DispatchQueue.main.async {
                            data.sortList() // remove this when we are done, figure a way to make it better
                        }
                    })
                    // do something when the app goes to the background
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                        guard let index = data.notes.firstIndex(of: note) else { return }
                        if data.notes[index].changed {
                            data.notes[index].changed = false
                            saveFile(filename: data.notes[index].filename, contents: data.notes[index].text)
                        }
                        // Delay of 7.5 seconds (1 second = 1_000_000_000 nanoseconds)
                        // if we remain in the background wait x time and reload all, bringing any new file with it
                        /*Task {
                            // Delay the task by 7.5 seconds:
                            try await Task.sleep(nanoseconds: 7_500_000_000)
                            print("### done")
                        }*/
                    }
                    .onDebouncedChange( // wait 5 second and if idle save the file
                        of: $text,
                        debounceFor: 5 // TimeInterval, 5 sec
                    ) { value in
                        guard let index = data.notes.firstIndex(of: note) else { return }
                        data.notes[index].text = value
                        data.notes[index].date = Date()
                        data.notes[index].filename = value.components(separatedBy: NSCharacterSet.newlines).first!
                        data.notes[index].changed = false
                        print("Idle, trigerring save...")
                        saveFile(filename: data.notes[index].filename, contents: data.notes[index].text)
                    }
                    .focused($focusedField, equals: .field)
                    .task {
                        // only move focus on new notes - bad solution, fix later
                        if text == "" {
                            self.focusedField = .field
                        }
                    }                
            }
        }
        .padding(.top)
        .padding(.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor)) // to enanle color for dark and light more
        .hidden(data.notes.isEmpty) // remove left behind texteditor when all notes are deleted.
    }
    
    // get the title (first line) of the note
    func getTitle(noteText: String) -> String {
        let title: String = noteText.components(separatedBy: NSCharacterSet.newlines).first!
        //debugPrint(">>> Title: " + title)
        if title.isEmpty {
            return "No Title"
        }
        return title
    }
    
    // check if the title change, return true if it did
    func titleChanged(noteItem: NoteItem, currentTitle: String) -> Bool {
        if noteItem.filename != currentTitle {
            return true
        }
        
        return false
    }
    
    // get markdown so we can highlight urls
    func getMarkdownText(noteText: String) -> AttributedString {
        var myString: AttributedString = ""
        
        do {
            myString = try! AttributedString(markdown: noteText,
                                             options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                                                                         .inlineOnlyPreservingWhitespace))
        }
        
        return myString
    }
    
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isShowingSheet: .constant(false))
    }
}
