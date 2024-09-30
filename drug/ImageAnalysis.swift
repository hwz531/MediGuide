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
    @State private var AIresponse: String = "Analyzing image..."
    
    init(image: UIImage) {
        self.selectedImage = image
    }
    
    var body: some View {
        ScrollView {
           Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .cornerRadius(15)
                .shadow(radius: 10)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 2))
            
            Text(AIresponse)
                .font(.system(size: 20))
        }
        .task {
            // Send image to OpenAI for analyzing
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
                        if let response = result.choices[0].message.content {
                            AIresponse = response.string!
                        } else {
                            AIresponse = "Failed to get a response from the AI model. Please try again later."
                        }
                    } catch {
                        print("Error parsing image: \(error)")
                    }
                }
            } else {
                print("Error getting data from image")
            }
        }
    }
}
