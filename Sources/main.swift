import Cocoa

// vdisplay — menubar app that owns a CGVirtualDisplay.
// Creates a real "extra monitor" (no hardware) that stays alive while the app
// runs; quit from the status item or Cmd-Q removes it. Private API — local
// tooling, not App Store-safe. Modeled on Chromium's
// virtual_display_util_mac.mm (BSD-3).

func makeVirtualDisplay(width W: Int, height H: Int) -> AnyObject? {
    guard let descC = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
          let modeC = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type,
          let setC  = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
          let dispC = NSClassFromString("CGVirtualDisplay") as? NSObject.Type else { return nil }

    let desc = descC.init()
    let q = DispatchQueue.global(qos: .userInteractive)
    for key in ["dispatchQueue", "queue"] {
        let sel = NSSelectorFromString("set\(key.prefix(1).uppercased())\(key.dropFirst()):")
        if desc.responds(to: sel) { desc.setValue(q, forKey: key); break }
    }
    desc.setValue("vdisplay", forKey: "name")
    desc.setValue(W, forKey: "maxPixelsWide")
    desc.setValue(H, forKey: "maxPixelsHigh")
    let ppi = 72.0
    desc.setValue(CGSize(width: 25.4 * Double(W) / ppi, height: 25.4 * Double(H) / ppi),
                  forKey: "sizeInMillimeters")
    desc.setValue(CGPoint(x: 0.3125, y: 0.3291), forKey: "whitePoint")
    desc.setValue(CGPoint(x: 0.1494, y: 0.0557), forKey: "bluePrimary")
    desc.setValue(CGPoint(x: 0.2559, y: 0.6983), forKey: "greenPrimary")
    desc.setValue(CGPoint(x: 0.6797, y: 0.3203), forKey: "redPrimary")
    desc.setValue(1, forKey: "serialNum")
    desc.setValue(0, forKey: "productID")
    desc.setValue(505, forKey: "vendorID")
    desc.setValue(1, forKey: "serialNumber")
    desc.setValue(nil, forKey: "terminationHandler")

    // alloc first, then initWithDescriptor: on the instance — calling it on the
    // class returned a broken object on macOS 26+.
    typealias dInit = @convention(c) (AnyObject, Selector, AnyObject) -> AnyObject?
    guard let rawDisp = (dispC as AnyObject).perform(sel_registerName("alloc"))?.takeUnretainedValue(),
          let dImp = class_getMethodImplementation(dispC, sel_registerName("initWithDescriptor:")),
          let vd = unsafeBitCast(dImp, to: dInit.self)(rawDisp, sel_registerName("initWithDescriptor:"), desc)
    else { return nil }

    // mode: alloc + 3-arg initWithWidth:height:refreshRate:
    typealias modeInit = @convention(c) (AnyObject, Selector, Int, Int, Double) -> AnyObject?
    let mSel = sel_registerName("initWithWidth:height:refreshRate:")
    guard let rawMode = (modeC as AnyObject).perform(sel_registerName("alloc"))?.takeUnretainedValue(),
          let mImp = class_getMethodImplementation(modeC, mSel),
          let mode = unsafeBitCast(mImp, to: modeInit.self)(rawMode, mSel, W, H, 60.0)
    else { return nil }

    let settings = setC.init()
    settings.setValue(0, forKey: "hiDPI")
    settings.setValue(0, forKey: "rotation")
    settings.setValue([mode], forKey: "modes")

    typealias applyFn = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
    let applySel = sel_registerName("applySettings:")
    guard let applyImp = class_getMethodImplementation(type(of: vd), applySel),
          unsafeBitCast(applyImp, to: applyFn.self)(vd, applySel, settings) else { return nil }
    return vd
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var display: AnyObject?   // strong ref keeps the virtual display alive
    private var item: NSStatusItem?

    func applicationDidFinishLaunching(_ n: Notification) {
        display = makeVirtualDisplay(width: 1920, height: 1080)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = item?.button {
            b.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "vdisplay")
        }
        let m = NSMenu()
        m.addItem(NSMenuItem(title: display != nil ? "Virtual display 1920×1080 — active" : "Failed to create display",
                             action: nil, keyEquivalent: ""))
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item?.menu = m
    }

    func applicationWillTerminate(_ n: Notification) {
        display = nil   // drops the CGVirtualDisplay; macOS removes the screen
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon, menubar only
let d = AppDelegate()
app.delegate = d
app.run()
