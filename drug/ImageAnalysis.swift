//
//  ImageAnalysis.swift
//  drug
//
//  Created by Zoe 郑 on 9/29/24.
//

import SwiftUI
import OpenAI


struct ImageAnalysis: View {
    @State private var selectedImage: UIImage
    
    init(image: UIImage) {
        self.selectedImage = image
    }
    
    var body: some View {
        VStack(spacing: 30) {
           Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .cornerRadius(15)
                .shadow(radius: 10)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 2))
            
            Button(action: {
                // Convert image to PNG data and send it to OpenAI for editing
                if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                    let imgParam = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam(content: .vision([
                        .chatCompletionContentPartImageParam(.init(imageUrl: .init(url: imageData, detail: .high)))
                    ]))
                    let query = ChatQuery(messages: [
                        .user(imgParam),
                        .user(.init(content: .string("what is in this image?")))
                    ], model: .gpt4_o, maxTokens: 500)
                    Task {
                        do {
                            let result = try await openAI.chats(query: query)
                            // Handle OpenAI result here (e.g., display the edited image)
                            print("Image parsed successfully: \(result)")
                        } catch {
                            print("Error parsing image: \(error)")
                        }
                    }
                }
            }) {
                Text("Get Full Report")
            }
        }
    }
}
