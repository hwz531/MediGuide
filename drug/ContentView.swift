//
//  ContentView.swift
//  drug
//
//  Created by Zoe 郑 on 8/13/24.
//

import SwiftUI
import PhotosUI
import OpenAI


// Add API key to Info.plist
let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String ?? "key unset"
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
    @State var showImageAnalysis: Bool = false
    @State var showEKGAnalysis: Bool = false
    
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var useCamera = false // State to choose between camera or photo library

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
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
                
                Text("Medical AI: Get to know your meds.")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Button("Select or Capture Image") {
                    // Present an alert to choose between camera and photo library
                    let alert = UIAlertController(
                        title: "Select Source",
                        message: nil,
                        preferredStyle: .actionSheet
                    )
                    
                    alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                        useCamera = true
                        isImagePickerPresented = true
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
                        useCamera = false
                        isImagePickerPresented = true
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first
                    else {
                        print("Unable to obtain window")
                        return
                    }
                    
                    // For iPad
                    if let popoverController = alert.popoverPresentationController {
                        popoverController.sourceView = window
                        popoverController.sourceRect = window.bounds
                        popoverController.permittedArrowDirections = []
                    }
                    
                    // Present the alert in SwiftUI by using the root view controller
                    window.rootViewController?.present(alert, animated: true, completion: nil)
                }
                .buttonStyle(GradientButton(left:Color.blue, right:Color.cyan))
                
                Button("Connect to Wearable Device") {
                    showEKGAnalysis.toggle()
                }
                .navigationDestination(isPresented: $showEKGAnalysis) {
                    EKGAnalysis()
                }
                .buttonStyle(GradientButton(left:Color.blue, right:Color.cyan))
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                // Present the ImagePicker with either camera or photo library option
                ImagePicker(selectedImage: $selectedImage, useCamera: $useCamera)
            }
            .onChange(of: selectedImage) {
                showImageAnalysis.toggle()
            }
            .navigationDestination(isPresented: $showImageAnalysis) {
                if selectedImage != nil {
                    ImageAnalysis(image: selectedImage!)
                }
            }
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
            picker.dismiss(animated: false)
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
