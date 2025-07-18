//
//  GifLoadingView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 15/07/25.
//

import SwiftUI

struct GifLoadingView: View {
    var body: some View {
        WebGifView(gifName: "stepOn")
            .frame(height: 211)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
    }
}

#Preview {
    GifLoadingView()
}

import SwiftUI
import WebKit
struct GifImageView: UIViewRepresentable {
    private let name: String
    init(_ name: String) {
        self.name = name
    }
func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        let url = Bundle.main.url(forResource: name, withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        webview.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        return webview
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}



import SwiftUI
import WebKit

/// Alternative WebKit-based GIF view for better size control
struct WebGifView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        if let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifData = NSData(contentsOfFile: gifPath) {
            webView.load(gifData as Data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: Bundle.main.bundleURL)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

/// A view that displays an animated GIF from the app bundle
struct AnimatedGifView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // Important: Set these to allow SwiftUI to control the size
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        if let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifData = NSData(contentsOfFile: gifPath),
           let source = CGImageSourceCreateWithData(gifData, nil) {
            
            var images: [UIImage] = []
            var duration: TimeInterval = 0
            
            let imageCount = CGImageSourceGetCount(source)
            for i in 0..<imageCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    let image = UIImage(cgImage: cgImage)
                    images.append(image)
                    
                    // Get frame duration
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                       let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        duration += frameDuration
                    }
                }
            }
            
            if !images.isEmpty {
                let animatedImage = UIImage.animatedImage(with: images, duration: duration)
                imageView.image = animatedImage
            }
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No updates needed
    }
}
