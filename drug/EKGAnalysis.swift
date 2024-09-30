//
//  EKGAnalysis.swift
//  drug
//
//  Created by Zoe 郑 on 9/29/24.
//

import SwiftUI


struct EKGAnalysis: View {
    @State private var ekgImage: UIImage? = nil
    
    let base64string: String = "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"
    
    var body: some View {
        VStack(spacing: 30) {
            Image(uiImage: UIImage(data: Data(base64Encoded: base64string, options: .ignoreUnknownCharacters)!)!)
                .resizable()
                .scaledToFit()
            
            Text("TODO")
        }
    }
}
