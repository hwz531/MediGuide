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

//public struct ImageEditsQuery: Codable {
//    /// The image to edit, in PNG format (less than 4MB and square).
//    public let image: Data
//    public let fileName: String
//    /// Optional mask image that indicates which parts of the image should be edited.
//    public let mask: Data?
//    public let maskFileName: String?
//    /// A description of the desired image(s).
//    public let prompt: String
//    /// Number of images to generate (1-10).
//    public let n: Int?
//    /// The size of the generated image (e.g., 256x256, 512x512, 1024x1024).
//    public let size: String?
//
//    public init(image: Data, fileName: String, prompt: String, n: Int? = 1, size: String? = "1024x1024", mask: Data? = nil, maskFileName: String? = nil) {
//        self.image = image
//        self.fileName = fileName
//        self.prompt = prompt
//        self.n = n
//        self.size = size
//        self.mask = mask
//        self.maskFileName = maskFileName
//    }
//}


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
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
            }) {
                Text("Select or Capture Image")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }

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
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
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
