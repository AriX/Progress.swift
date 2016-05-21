//
//  Progress.swift
//
//  Created by Justus Kandzi on 27/12/15.
//  Copyright © 2015 Justus Kandzi. All rights reserved.
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


// MARK: - ProgressBarDisplayer

public protocol ProgressBarPrinter {
    mutating func display(progressBar: ProgressBar)
}

struct ProgressBarTerminalPrinter: ProgressBarPrinter {
    var lastPrintedTime = 0.0

    init() {
        // the cursor is moved up before printing the progress bar.
        // have to move the cursor down one line initially.
        print("")
    }
    
    mutating func display(progressBar: ProgressBar) {
        let currentTime = getTimeOfDay()
        if (currentTime - lastPrintedTime > 0.1 || progressBar.index == progressBar.count) {
            print("\u{1B}[1A\u{1B}[K\(progressBar.value)")
            lastPrintedTime = currentTime
        }
    }
}


// MARK: - ProgressBar

public struct ProgressBar {
    var index = 0
    let startTime = getTimeOfDay()
    
    let count: Int
    let configuration: [ProgressElementType]?

    public static var defaultConfiguration: [ProgressElementType] = [ProgressIndex(), ProgressBarLine(), ProgressTimeEstimates()]

    var printer: ProgressBarPrinter
    
    public var value: String {
        let configuration = self.configuration ?? ProgressBar.defaultConfiguration
        let values = configuration.map { $0.value(self) }
        return values.joinWithSeparator(" ")
    }
    
    public init(count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.count = count
        self.configuration = configuration
        self.printer = printer ?? ProgressBarTerminalPrinter()
    }
    
    public mutating func next() {
        guard index <= count else { return }
        printer.display(self)
        index += 1
    }

    public mutating func setValue(index: Int) {
        guard index <= count && index >= 0 else { return }
        self.index = index
        printer.display(self)
    }

}


// MARK: - GeneratorType

public struct ProgressGenerator<G: GeneratorType>: GeneratorType {
    var source: G
    var progressBar: ProgressBar
    
    init(source: G, count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.source = source
        self.progressBar = ProgressBar(count: count, configuration: configuration, printer: printer)
    }
    
    public mutating func next() -> G.Element? {
        progressBar.next()
        return source.next()
    }
}


// MARK: - SequenceType

public struct Progress<G: SequenceType>: SequenceType {
    let generator: G
    let configuration: [ProgressElementType]?
    let printer: ProgressBarPrinter?
    
    public init(_ generator: G, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.generator = generator
        self.configuration = configuration
        self.printer = printer
    }
    
    public func generate() -> ProgressGenerator<G.Generator> {
        let count = generator.underestimateCount()
        return ProgressGenerator(source: generator.generate(), count: count, configuration: configuration, printer: printer)
    }
}
