//
//  Debounce.swift
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
//  functions to enable detection of idle on a TextEditor
//  When the user stops typing, for a period of time, save the text
//

import Foundation
import SwiftUI
import Combine

extension View {
    func onDebouncedChange<V>(
        of binding: Binding<V>,
        debounceFor dueTime: TimeInterval,
        perform action: @escaping (V) -> Void
    ) -> some View where V: Equatable {
        modifier(ListenDebounce(binding: binding, dueTime: dueTime, action: action))
    }
}

private struct ListenDebounce<Value: Equatable>: ViewModifier {
    @Binding
    var binding: Value
    @StateObject
    var debounceSubject: ObservableDebounceSubject<Value, Never>
    let action: (Value) -> Void

    init(binding: Binding<Value>, dueTime: TimeInterval, action: @escaping (Value) -> Void) {
        _binding = binding
        _debounceSubject = .init(wrappedValue: .init(dueTime: dueTime))
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: binding) { value in
                debounceSubject.send(value)
            }
            .onReceive(debounceSubject) { value in
                action(value)
            }
    }
}

private final class ObservableDebounceSubject<Output: Equatable, Failure>: Subject, ObservableObject where Failure: Error {
    private let passthroughSubject = PassthroughSubject<Output, Failure>()

    let dueTime: TimeInterval

    init(dueTime: TimeInterval) {
        self.dueTime = dueTime
    }

    func send(_ value: Output) {
        passthroughSubject.send(value)
    }

    func send(completion: Subscribers.Completion<Failure>) {
        passthroughSubject.send(completion: completion)
    }

    func send(subscription: Subscription) {
        passthroughSubject.send(subscription: subscription)
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        passthroughSubject
            .removeDuplicates()
            .debounce(for: .init(dueTime), scheduler: RunLoop.main)
            .receive(subscriber: subscriber)
    }
}
