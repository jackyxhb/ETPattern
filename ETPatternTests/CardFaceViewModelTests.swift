import Testing
import SwiftUI
@testable import ETPattern

@Suite("CardFaceViewModel Tests")
@MainActor
struct CardFaceViewModelTests {
    
    @Test("ViewModel successfully parses front text into sentences")
    func testFrontParsing() {
        let viewModel = CardFaceViewModel()
        let text = "Hello world. This is a test! Is it working?\nYes."
        
        viewModel.setup(text: text, isFront: true)
        
        #expect(viewModel.sentences.count == 4)
        #expect(viewModel.sentences[0] == "Hello world")
        #expect(viewModel.sentences[1] == "This is a test")
        #expect(viewModel.sentences[2] == "Is it working")
        #expect(viewModel.sentences[3] == "Yes")
    }
    
    @Test("ViewModel successfully parses back text into sentences by newline")
    func testBackParsing() {
        let viewModel = CardFaceViewModel()
        let text = "Example 1\nExample 2\n\nExample 3"
        
        viewModel.setup(text: text, isFront: false)
        
        #expect(viewModel.sentences.count == 3)
        #expect(viewModel.sentences[0] == "Example 1")
        #expect(viewModel.sentences[1] == "Example 2")
        #expect(viewModel.sentences[2] == "Example 3")
    }
    
    @Test("ViewModel updates translations correctly")
    func testUpdateTranslations() {
        let viewModel = CardFaceViewModel()
        let newTranslations = ["Hello": "你好"]
        
        viewModel.updateTranslations(newTranslations)
        
        #expect(viewModel.translations["Hello"] == "你好")
    }
}
