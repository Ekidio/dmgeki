import Foundation

public struct AppleScriptGenerator {
    
    /// Generates AppleScript to configure Finder icon layout, background, window size, and view options
    public static func generateScript(for project: DMGProject, volumeName: String, backgroundFileName: String?) -> String {
        let win = project.window
        
        let left = Int(win.spawnPositionX)
        let top = Int(win.spawnPositionY)
        let right = left + Int(win.width)
        // In macOS Finder, window bounds specify the outer window frame including title bar (32 pt)
        // and tab bar (28 pt). Adding 60 pt compensation guarantees the icon view content area
        // matches the exact 540x350 pt canvas, ensuring the entire background and bottom watermark are visible.
        let chromeCompensation = 60
        let bottom = top + Int(win.height) + chromeCompensation
        
        var script = """
        tell application "Finder"
            tell disk "\(escapeQuotes(volumeName))"
                -- Open the disk image window
                open
                delay 1
                
                -- Configure window presentation
                tell container window
                    set current view to icon view
                    set toolbar visible to \(win.showToolbar ? "true" : "false")
                    set statusbar visible to \(win.showStatusbar ? "true" : "false")
                    set pathbar visible to \(win.showPathbar ? "true" : "false")
                    set bounds to {\(left), \(top), \(right), \(bottom)}
                    set statusbar visible to \(win.showStatusbar ? "true" : "false")
                end tell
                
                -- Configure icon view options
                set theViewOptions to the icon view options of container window
                set arrangement of theViewOptions to not arranged
                set icon size of theViewOptions to \(Int(win.iconSize))
                set text size of theViewOptions to \(Int(win.textSize))
                set label position of theViewOptions to \(win.labelOnBottom ? "bottom" : "right")
                
                -- Set background picture (Strictly .background:background.png)
                try
                    set background picture of current view of container window to file ".background:background.png"
                on error
                    try
                        set background picture of theViewOptions to file ".background:background.png"
                    end try
                end try
                
                update without registering applications
                delay 1
                
                -- Position items
        """
        
        for item in project.items {
            let itemName = item.destinationName
            let posX = Int(item.positionX)
            let posY = Int(item.positionY)
            
            script += """
            
                try
                    set position of item "\(escapeQuotes(itemName))" of container window to {\(posX), \(posY)}
                on error errMsg
                    log "Could not position \(escapeQuotes(itemName)): " & errMsg
                end try
            """
        }
        
        script += """
        
                
                -- Force Finder to update and flush window view options
                update without registering applications
                delay 1
                close
            end tell
        end tell
        """
        
        return script
    }
    
    private static func escapeQuotes(_ text: String) -> String {
        return text.replacingOccurrences(of: "\\", with: "\\\\")
                   .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
