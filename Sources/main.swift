import Cocoa

// vdisplay - create a CGVirtualDisplay and keep it alive.
// usage: vdisplay [width height]
// Modeled on Chromium's virtual_display_util_mac.mm (BSD-3): descriptor
// with queue + serial/vendor, 3-arg CGVirtualDisplayMode, applySettings:.
// Private API - local recording tool, not App Store-safe.

let W = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[1])! : 1920
let H = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2])! : 1080

guard let descC = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
      let modeC = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type,
      let setC  = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
      let dispC = NSClassFromString("CGVirtualDisplay") as? NSObject.Type else {
    print("CGVirtualDisplay classes not found"); exit(1)
}

let desc = descC.init()
// queue: try "queue" then "dispatchQueue" (property name varies by macOS)
let q = DispatchQueue.global(qos: .userInteractive)
for key in ["queue", "dispatchQueue"] {
    if desc.responds(to: NSSelectorFromString("set\(key.prefix(1).uppercased())\(key.dropFirst()):")) {
        desc.setValue(q, forKey: key); break
    }
}
desc.setValue("vdisplay", forKey: "name")
desc.setValue(W, forKey: "maxPixelsWide")
desc.setValue(H, forKey: "maxPixelsHigh")
let ppi = 72.0
desc.setValue(CGSize(width: 25.4 * Double(W) / ppi, height: 25.4 * Double(H) / ppi), forKey: "sizeInMillimeters")
desc.setValue(CGPoint(x: 0.3125, y: 0.3291), forKey: "whitePoint")
desc.setValue(CGPoint(x: 0.1494, y: 0.0557), forKey: "bluePrimary")
desc.setValue(CGPoint(x: 0.2559, y: 0.6983), forKey: "greenPrimary")
desc.setValue(CGPoint(x: 0.6797, y: 0.3203), forKey: "redPrimary")
desc.setValue(1, forKey: "serialNum")
desc.setValue(0, forKey: "productID")
desc.setValue(505, forKey: "vendorID")
desc.setValue(1, forKey: "serialNumber")
desc.setValue(nil, forKey: "terminationHandler")
typealias dInit = @convention(c) (AnyObject, Selector, AnyObject) -> AnyObject?
// alloc the display object first, then initWithDescriptor: on the instance.
// Sending initWithDescriptor: directly to the class returned a broken object.
guard let rawDisp = (dispC as AnyObject).perform(sel_registerName("alloc"))?.takeUnretainedValue(),
      let dImp = class_getMethodImplementation(dispC, sel_registerName("initWithDescriptor:")),
      let vd = unsafeBitCast(dImp, to: dInit.self)(rawDisp, sel_registerName("initWithDescriptor:"), desc) else {
    print("initWithDescriptor failed"); exit(1)
}


// mode: 3-arg initWithWidth:height:refreshRate:
typealias modeInit = @convention(c) (AnyObject, Selector, Int, Int, Double) -> AnyObject?
let mSel = sel_registerName("initWithWidth:height:refreshRate:")
guard let rawMode = (modeC as AnyObject).perform(sel_registerName("alloc"))?.takeUnretainedValue(),
      let mImp = class_getMethodImplementation(modeC, mSel),
      let mode = unsafeBitCast(mImp, to: modeInit.self)(rawMode, mSel, W, H, 60.0) else {
    print("mode init failed"); exit(1)
}

let settings = setC.init()
settings.setValue(0, forKey: "hiDPI")
settings.setValue(0, forKey: "rotation")
settings.setValue([mode], forKey: "modes")

typealias applyFn = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
let applySel = sel_registerName("applySettings:")
guard let applyImp = class_getMethodImplementation(type(of: vd), applySel) else {
    print("no applySettings:"); exit(1)
}
let ok = unsafeBitCast(applyImp, to: applyFn.self)(vd, applySel, settings)
print("applySettings ->", ok)

var count: UInt32 = 0
CGGetOnlineDisplayList(0, nil, &count)
var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
CGGetOnlineDisplayList(count, &ids, &count)
print("online displayIDs:", ids)

print("vdisplay \(W)x\(H) created. Ctrl-C to remove.")
RunLoop.current.run()
