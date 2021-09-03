//
//  AppDelegate.swift
//  LocalSearchCompletion
//
//  Created by Nikhil Nigade on 03/09/21.
//

import Cocoa
import MapKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    @IBOutlet var textField: AutocompleteTextField!
    
    // setup local search completion
    private var searchCompleter = MKLocalSearchCompleter()
    private var completerResults = [MKLocalSearchCompletion]()
    
    private var timer: Timer?
    
    @objc dynamic
    var searchText: String? {
        didSet {
            
            guard let st = searchText,
                  st.isEmpty == false,
                  st.count > 2 else {
                      textField.matches = []
                return
            }
            
            // Use a timer. Typically, you'd use a Coalescing Queue type abtraction.
            // But for the purposes of a demo, this suffices.
            if let timer = timer {
                if timer.isValid {
                    timer.invalidate()
                    self.timer = nil
                }
            }
            
            timer = Timer(timeInterval: 0.2, target: self, selector: #selector(updateQueryFragment), userInfo: nil, repeats: false)
            
            RunLoop.current.add(timer!, forMode: .common)
            
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        textField.autocompleteDelegate = self
        textField.popoverPadding = .init(top: 4, leading: 0, bottom: 4, trailing: 0)
        searchCompleter.delegate = self
    }

    @objc private func updateQueryFragment() {
        searchCompleter.queryFragment = searchText!
    }
    
}

extension AppDelegate: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResults = completer.results
        textField.matches = completerResults.map { $0.title + " " + $0.subtitle }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
    }
    
}

extension AppDelegate: AutocompleteTextFieldDelegate {
    
    func didSelectItem(_ item: Any) {
        print(item)
    }
    
}
