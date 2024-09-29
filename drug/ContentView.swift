//
//  ContentView.swift
//  drug
//
//  Created by Zoe 郑 on 8/13/24.
//

import SwiftUI
import PhotosUI
import OpenAI


let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? "OpenAI key unset"
let openAI = OpenAI(apiToken: apiKey)


struct GradientButton: ButtonStyle {
    var left: Color
    var right: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [left, right]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}


struct ContentView: View {
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var useCamera = false // State to choose between camera or photo library
    
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 2))
                } else {
                    Image(systemName: "pills.fill")
                        .resizable()
                        .padding(40)
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundStyle(.cyan)
                        .symbolEffect(.bounce.up, value: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.1))
                                .shadow(radius: 10)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 2))
                }
            }

            Text("Medical AI: Get to know your meds.")
                .multilineTextAlignment(.center)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.top, 20)

            Button(action: {
                // Present an alert to choose between camera and photo library
                let alert = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                    useCamera = true
                    isImagePickerPresented = true
                }))
                
                alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
                    useCamera = false
                    isImagePickerPresented = true
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                // Present the alert in SwiftUI by using the root view controller
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first
                else { return }
                window.rootViewController?.present(alert, animated: true, completion: nil)
            }) {
                Text("Select or Capture Image")
            }
            .buttonStyle(GradientButton(left:Color.blue, right:Color.cyan))

            if selectedImage != nil {
                Button(action: {
                    // Convert image to PNG data and send it to OpenAI for editing
                    if let imageData = selectedImage?.jpegData(compressionQuality: 1.0) {
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
                .buttonStyle(GradientButton(left:Color.green, right:Color.teal))
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            // Present the ImagePicker with either camera or photo library option
            ImagePicker(selectedImage: $selectedImage, useCamera: $useCamera)
        }
    }
}

// ImagePicker View for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var useCamera: Bool // Whether to use camera or photo library
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = useCamera && UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
