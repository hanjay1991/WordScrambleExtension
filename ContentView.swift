//
//  ContentView.swift
//  WordScramble
//
//  Created by Jay Hanley on 5/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var totalScore: Int = 0
    @State private var highScore: Int = 0
    
    @State private var rulesTitle: String = ""
    @State private var rulesMessage: String = ""
    @State private var showingRules: Bool = false
    
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                        ForEach(usedWords, id: \.self) { word in
                            HStack {
                                Image(systemName: "\(word.count).circle.fill")
                                Text(word)
                            }
                        }
                    }
                Section {
                    Text("Your current score is \(totalScore)")
                    Text("Your high score is \(highScore)! Can you beat it??")
                }
                }
            .navigationTitle(rootWord)
            .toolbar {
                Button("Restart",action: startGame)
                Button("Rules",action: {
                    rules(title:rulesTitle,message:rulesMessage)
                })
            }
            .onSubmit {
                addNewWord()
            }
            .onAppear {
                highScore = UserDefaults.standard.integer(forKey: "highScore")
                startGame()
            }
            .alert(rulesTitle, isPresented: $showingRules) {
                Button("OK") {}
            } message: {
                Text("""
           Make up words from the starting word!
           - Minimum word length of 3 letters.
           - You cannot write the starting word.
           - No repeating words.
           POINT BREAKDOWN:
           - 1 point for each 3 or 4 letter word.
           - 2 points for each 5 letter word.
           - 3 points for each 6 letter word.
           - 5 points for each 7 letter word.
           - 10 points for each 8 letter word!!
          """)
            }
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    func startGame() {
        //1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            //2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL, encoding: .utf8) {
                //3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                
                //4. Pick one random word or use "silkworm" as a sensible default
                usedWords = []
                if totalScore > highScore {
                    highScore = totalScore
                    UserDefaults.standard.set(totalScore, forKey: "highScore")
                }
                totalScore = 0
                rootWord = allWords.randomElement() ?? "silkworm"
                //If we are here everything has worked so we can exit
                return
            }
        }
        
        //if we are here there was a problem, trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    func addNewWord() {
        //lowercase and trim the word to avoid duplicates with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        //exit if the string is empty
        guard answer.count > 0 else {
            wordError(title: "No word entered", message: "Please write a valid word")
            return
        }
        guard isLongEnough(word: answer) else {
            wordError(title: "Word too short", message: "please enter a word longer than 2 letters")
            return
        }
        guard isUnique(word: answer) else {
            wordError(title: "Word twin", message: "You can't use the same word as the given word")
            return
        }
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "try something else")
            return
        }
        guard isReal(word: answer) else {
            wordError(title: "Word not real", message: "it may not be spelled correctly")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "that's not part of the word up top")
            return
        }
        
        
        withAnimation {
            usedWords.insert(answer,at: 0)
        }
        switch answer.count {
        case 3...4 : totalScore += 1
        case 5: totalScore += 2
        case 6: totalScore += 3
        case 7: totalScore += 5
        default: totalScore += 10
        }
        newWord = ""
    }
    func rules(title: String, message: String) {
        rulesTitle = title
        rulesMessage = message
        showingRules = true
        rulesMessage = """
           **Make up words from the starting word!**
           - Minimum word length of 3 letters.
           - You cannot write the starting word.
           - No repeating words.
           **Point breakdown:**
           - 1 point for each 3 or 4 letter word.
           - 2 points for each 5 letter word.
           - 3 points for each 6 letter word.
           - 5 points for each 7 letter word.
           - 10 points for each 8 letter word!!
          """
    }
    func isLongEnough(word: String) -> Bool {
        if word.count < 3 {
            return false
        }
        return true
    }
    func isUnique(word:String) -> Bool {
        if newWord == rootWord {
            return false
        }
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}


#Preview {
    ContentView()
}
