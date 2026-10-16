import SwiftUI
import AppKit

public struct LicenseEditorSheetView: View {
    @Binding var eulaContent: String
    @Binding var eulaLanguage: String
    @Binding var eulaEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    public init(
        eulaContent: Binding<String>,
        eulaLanguage: Binding<String>,
        eulaEnabled: Binding<Bool>
    ) {
        self._eulaContent = eulaContent
        self._eulaLanguage = eulaLanguage
        self._eulaEnabled = eulaEnabled
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Software License Agreement (EULA)", systemImage: "doc.text.fill")
                    .font(.headline)
                
                Spacer()
                
                Picker("Language", selection: $eulaLanguage) {
                    Text("English (en_US)").tag("en_US")
                    Text("German (de_DE)").tag("de_DE")
                    Text("French (fr_FR)").tag("fr_FR")
                    Text("Japanese (ja_JP)").tag("ja_JP")
                    Text("Spanish (es_ES)").tag("es_ES")
                    Text("Chinese (zh_CN)").tag("zh_CN")
                }
                .pickerStyle(.menu)
                .frame(width: 160)
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            
            Divider()
            
            // Templates Bar
            HStack {
                Text("Insert Template:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Standard EULA") {
                    eulaContent = standardEULATemplate
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("MIT License") {
                    eulaContent = mitLicenseTemplate
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Apache 2.0") {
                    eulaContent = apacheLicenseTemplate
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Import .txt/.rtf...") {
                    importLicenseFile()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content Editor
            TextEditor(text: $eulaContent)
                .font(.system(size: 12, design: .monospaced))
                .padding(10)
                .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            // Bottom Bar
            HStack {
                Text("Users will be prompted to accept this agreement before mounting the .dmg volume.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(eulaContent.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 640, height: 460)
    }
    
    private func importLicenseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                eulaContent = text
            }
        }
    }
    
    private var standardEULATemplate: String {
        """
        END USER LICENSE AGREEMENT
        
        PLEASE READ THIS SOFTWARE LICENSE AGREEMENT CAREFULLY BEFORE DOWNLOADING OR USING THE SOFTWARE.
        
        BY CLICKING 'AGREE' OR MOUNTING THIS DISK IMAGE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS LICENSE.
        
        1. License Grant: The Licensor grants you a non-exclusive, non-transferable license to install and use this application on macOS-compatible devices owned or controlled by you.
        2. Restrictions: You may not reverse engineer, decompile, or disassemble the Software, except to the extent express permitted by applicable law.
        3. Disclaimer of Warranties: The Software is provided 'AS IS', with all faults and without warranty of any kind.
        """
    }
    
    private var mitLicenseTemplate: String {
        """
        MIT License
        
        Copyright (c) 2026 Developer
        
        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:
        
        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.
        """
    }
    
    private var apacheLicenseTemplate: String {
        """
        Apache License, Version 2.0
        
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at
        
            http://www.apache.org/licenses/LICENSE-2.0
        
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        """
    }
}
