//
//  StepperHelperViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import StepperView

struct StepTextView: View {
    var text:String
    var body: some View {
        VStack {
            TextView(text: text, font: Font.system(size: 16, weight: Font.Weight.medium))
                .foregroundColor(Colors.blue(.teal).rawValue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
        }
    }
}

struct StepperContentView: View {
    var body: some View {
        return rectangleContent()
    }
    
    fileprivate func roundedRectangle() -> some View {
        return rectangleContent()
            .overlay(RoundedRectangle(cornerRadius: 8)
                .frame(width: 300)
                .foregroundColor(Color.clear)
                .shadow(color: Color(UIColor.black).opacity(0.03), radius: 8, x: 5, y: -5)
                .shadow(color: Color(UIColor.black).opacity(0.03), radius: 8, y: 5)
                .border(Color.gray))
    }
    
    fileprivate func textContent(text: String) -> some View {
        return HStack {
            Text(text)
                .padding(.vertical, 10)
                .padding(.horizontal, 5)
                .foregroundColor(Color.gray)
            Spacer()
        }
    }
    
    fileprivate func rectangleContent() -> some View {
        return
            VStack(alignment: .leading) {
                ForEach([StepperAlignment.top.rawValue,
                         StepperAlignment.center.rawValue,
                         StepperAlignment.bottom.rawValue], id:\.self) { value in
                            self.textContent(text: value)
                }
        }
    }
}

// MARK: - Image View to host Image
struct ImageView: View {
    var name:String
    var body: some View {
        Image(systemName: name)
            .resizable()
            .frame(width: 12, height: 12)
    }
}

struct ImageTextRowView: View {
    var text:String
    var imageName:String?
    var body: some View {
        VStack {
            HStack {
                if imageName != nil {
                    Image(imageName!)
                    .resizable()
                    .padding(.leading, 7)
                    .frame(width: 30, height: 30)
                    .aspectRatio(contentMode: .fit)
                } else {
                    EmptyView()
                }
                Text(text)
                    .foregroundColor(Colors.blue(.teal).rawValue)
                    .font(.system(size: 16, weight: Font.Weight.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 10,
                                        leading: imageName != nil ? 2 : 10,
                                        bottom: 10,
                                        trailing: 10))
                
            }.padding(.horizontal, 5)
                .offset(x: -5)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(Color.gray, lineWidth: 0.5)
                        .foregroundColor(Color.white)
                        .shadow(color: Color(UIColor.black).opacity(0.03), radius: 8, x: 5, y: -5)
                        .shadow(color: Color(UIColor.black).opacity(0.03), radius: 8, y: 5))
            
        }
    }
}
