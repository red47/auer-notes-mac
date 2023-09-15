# Auer Notes for macOS

This is the source code for Auer Notes for macOS, a note-taking application designed to be fast, easy to use, and stay out of the way until you need it.

Simple and clear, Auer Notes is intentional, focusing on less, instead of more. It does one thing, the simplest possible way. For more information check the website: https://auernotes.com

## Why releasing it as open source?

I wrote Auer Notes for myself, to [scratch my own itch](https://auernotes.com/why). Since I'm finding less and less time to finish it I decided to release it as open source in the hope that someone will help me finish version 1. The current beta is pretty much done, but there are a few things missing.

## What's missing?

* Load content of file as user select note: right now all the notes are loaded at once, when the app first open or when you force the reload. Over time this can create too much memory use which is something I'm trying to keep at a minimum, so, the need to load each file when selected needs to be finished.
* Need to move the use of `NavigationLink` to the new Apple way of doing thing
* Need to figure out how to print notes
* Potentially highlight words in the notes when you search
* Add URL highlighting to the notes

## Extra note and a request

I use this everyday, it's my note taking app. If you change it and make it better, please let me know so I can also benefit from the changes.

And, also, I have a special request: let's keep it minimal and clean. That's the whole point of this app.

## License

**Released under the MIT License**

Copyright (c) 2021 Uri Fridman
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
