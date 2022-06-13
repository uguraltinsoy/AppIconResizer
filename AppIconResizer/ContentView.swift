//
//  ContentView.swift
//  AppIconResizer
//
//  Created by UĞUR ALTINSOY on 13.06.2022.
//

import SwiftUI

struct ContentView: View {
    @State var selectImage = false
    @State var image = NSImage(named: "image")
    @State private var dragOver = false
    
    @State var name = "ic_launcher"
    
    @State var iphoneExport = false
    @State var ipadExport = false
    @State var watchOsExport = false
    @State var macOsExport = false
    @State var androidExport = false
    
    let iphoneSize = [29, 40, 57, 58, 60, 80, 87, 114, 120, 180, 1024]
    let ipadSize = [20, 29, 40, 50, 58, 72, 76, 80, 100, 144, 152, 167]
    let wacthOsSize = [48, 55, 58, 80, 87, 88, 100, 172, 196, 216, 1024]
    let macOsSize = [16, 32, 64, 128, 256, 512, 1024]
    
    let androidFolders: [(String, Int)] = [("mipmap-mdpi" , 48), ("mipmap-hdpi", 72), ("mipmap-xhdpi", 96), ("mipmap-xxhdpi", 144), ("mipmap-xxxhdpi" , 192)]
    
    // Error Bool
    @State var isOn = false
    @State var isName = false
    @State var isPlatform = false
    
    @State var isPopover = false
    
    let manager = FileManager.default
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    VStack {
                        if selectImage {
                            Image(nsImage: image ?? NSImage())
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(6)
                                .frame(width: 200, height: 200)
                        }
                        else {
                            VStack {
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80)
                                Text("Drag image to here")
                            }
                            .frame(width: 200, height: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .foregroundColor(Color(red: 113 / 255, green: 113 / 255, blue: 113 / 255))
                            )
                        }
                        Text("Square picture")
                            .padding(.top, 10)
                    }
                    .frame(width: 250)
                    Divider()
                    VStack {
                        VStack(alignment: .leading) {
                            Group {
                                Text("iOS and macOS")
                                Divider()
                                Toggle("iPhone", isOn: $iphoneExport)
                                    .toggleStyle(.checkbox)
                                Toggle("iPad", isOn: $ipadExport)
                                    .toggleStyle(.checkbox)
                                Toggle("watchOS", isOn: $watchOsExport)
                                    .toggleStyle(.checkbox)
                                Toggle("macOS", isOn: $macOsExport)
                                    .toggleStyle(.checkbox)
                                Text("Android")
                                Divider()
                                Toggle("Android", isOn: $androidExport)
                                    .toggleStyle(.checkbox)
                            }
                            Divider()
                            HStack {
                                Text("Name:")
                                TextField("name", text: $name)
                            }
                        }
                        .padding(.horizontal, 10)
                        Spacer()
                        HStack {
                            Button(action: {
                                guard let url = manager.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
                                let ic_launcher = url.appendingPathComponent("App Icon Resizer")
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ic_launcher.path)
                            }, label: {
                                Text("Saved folder")
                            })
                            Spacer()
                            Button(action: {
                                if name == "" {
                                    isName = true
                                } else if !iphoneExport && !ipadExport && !watchOsExport && !macOsExport && !androidExport {
                                    isPlatform = true
                                } else if image != nil {
                                    exportZipFile()
                                }
                            }, label: {
                                Text("Generate")
                            })
                        }.padding(.horizontal, 10)
                    }
                    .frame(height: 230)
                }
            }
            VStack{
                HStack {
                    Spacer()
                    Button(action: { self.isPopover.toggle() }, label: {
                        Image(systemName: "questionmark.circle")
                            .popover(isPresented: self.$isPopover, arrowEdge: .bottom) {
                                PopoverView()
                            }
                            .padding(.trailing, 10)
                            .padding(.top, 6)
                    }).buttonStyle(PlainButtonStyle())
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("V1.0")
                        .font(.system(size: 12))
                        .padding(.trailing, 10)
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(width: 500, height: 300)
        .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                if let data = data,
                   let path = NSString(data: data, encoding: 4),
                   let url = URL(string: path as String) {
                    let image = NSImage(contentsOf: url)
                    if image != nil {
                        let size = image?.size
                        if size?.width == size?.height {
                            DispatchQueue.main.async {
                                self.image = image
                                selectImage = true
                                isOn = false
                            }
                        } else {
                            isOn = true
                        }
                    }
                }
            })
            return true
        }
        .navigationTitle("App Icon Resizer")
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification), perform: { _ in
            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        })
        .alert("Invalid size", isPresented: $isOn) {
            Button("OK", role: .cancel) { }
        }
        .alert("Enter name", isPresented: $isName) {
            Button("OK", role: .cancel) { }
        }
        .alert("Choose platform", isPresented: $isPlatform) {
            Button("OK", role: .cancel) { }
        }
    }
    
    
    
    func exportZipFile() {
        guard let url = manager.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }

        let ic_launcher = url.appendingPathComponent("App Icon Resizer/\(name)")
        
        if manager.fileExists(atPath: ic_launcher.path) {
            exportZipFile(index: 1)
            return
        }
        
        do {
            try manager.createDirectory(
                at: ic_launcher,
                withIntermediateDirectories: true,
                attributes: [:]
            )
        } catch {
            return
        }
        
        if (iphoneExport || ipadExport || watchOsExport || macOsExport) && androidExport {
            let apple = ic_launcher.appendingPathComponent("Apple")
            let andro = ic_launcher.appendingPathComponent("Android/res")
            iosAndMac(url:apple)
            android(url:andro, name: name)
        } else if (androidExport) {
            let andro = ic_launcher.appendingPathComponent("Android/res")
            android(url:andro, name: name)
            
        } else {
            let apple = ic_launcher.appendingPathComponent("Apple")
            iosAndMac(url:apple)
        }
    }
    
    func exportZipFile(index:Int) {
        guard let url = manager.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }

        let ic_launcher = url.appendingPathComponent("App Icon Resizer/\(name) (\(index))")
        
        if manager.fileExists(atPath: ic_launcher.path) {
            exportZipFile(index: index + 1)
            return
        }
        
        do {
            try manager.createDirectory(
                at: ic_launcher,
                withIntermediateDirectories: true,
                attributes: [:]
            )
        } catch {
            return
        }
        
        if (iphoneExport || ipadExport || watchOsExport || macOsExport) && androidExport {
            let apple = ic_launcher.appendingPathComponent("Apple")
            let andro = ic_launcher.appendingPathComponent("Android/res")
            iosAndMac(url:apple)
            android(url:andro, name: name)
        } else if (androidExport) {
            let andro = ic_launcher.appendingPathComponent("Android/res")
            android(url:andro, name: name)
            
        } else {
            let apple = ic_launcher.appendingPathComponent("Apple")
            iosAndMac(url:apple)
        }
    }
    
    func createFolder(url:URL) -> Bool{
        do {
            try manager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: [:]
            )
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func android(url:URL, name:String) {
        DispatchQueue.global(qos: .userInteractive).async {
            if createFolder(url: url) {
                for pt in androidFolders {
                    let folder = url.appendingPathComponent(pt.0)
                    if createFolder(url: folder) {
                        let size = CGFloat(pt.1) / 2
                        let img = image?.resize(width: size, height: size, padding: 0)
                        let path = folder.appendingPathComponent("\(name).png")
                        img?.pngWrite(to: path, options: .withoutOverwriting)
                    }
                }
            }
        }
    }
    
    func iosAndMac(url:URL) {
        if iphoneExport {
            DispatchQueue.global(qos: .userInteractive).async {
                let iphone = url.appendingPathComponent("iphone")
                if createFolder(url: iphone) {
                    for sz in iphoneSize {
                        let size = CGFloat(sz) / 2
                        let img = image?.resize(width: size, height: size, padding: 0)
                        let path = iphone.appendingPathComponent("\(sz).png")
                        img?.pngWrite(to: path, options: .withoutOverwriting)
                    }
                }
            }
        }
        if ipadExport {
            DispatchQueue.global(qos: .userInteractive).async {
                let ipad = url.appendingPathComponent("ipad")
                if createFolder(url: ipad) {
                    for sz in ipadSize {
                        let size = CGFloat(sz) / 2
                        let img = image?.resize(width: size, height: size, padding: 0)
                        let path = ipad.appendingPathComponent("\(sz).png")
                        img?.pngWrite(to: path, options: .withoutOverwriting)
                    }
                }
            }
        }
        if watchOsExport {
            DispatchQueue.global(qos: .userInteractive).async {
                let watch = url.appendingPathComponent("watch")
                if createFolder(url: watch) {
                    for sz in wacthOsSize {
                        let size = CGFloat(sz) / 2
                        let img = image?.resize(width: size, height: size, padding: 0)
                        let path = watch.appendingPathComponent("\(sz).png")
                        img?.pngWrite(to: path, options: .withoutOverwriting)
                    }
                }
            }
        }
        if macOsExport {
            DispatchQueue.global(qos: .userInteractive).async {
                let macos = url.appendingPathComponent("macos")
                if createFolder(url: macos) {
                    for sz in macOsSize {
                        let size = CGFloat(sz) / 2
                        let img = image?.resize(width: size, height: size, padding: 0)
                        let path = macos.appendingPathComponent("\(sz).png")
                        img?.pngWrite(to: path, options: .withoutOverwriting)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct PopoverView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text("Social media")
                Spacer()
            }
            HStack {
                Text("Linkedin")
                Link("profile", destination: URL(string: "https://www.linkedin.com/in/uguraltnsy/")!)
            }
            HStack {
                Text("GitHub")
                Link("profile", destination: URL(string: "https://github.com/uguraltinsoy/")!)
            }
            HStack {
                Text("Twitter")
                Link("profile", destination: URL(string: "https://twitter.com/uguraltnsy/")!)
            }
            HStack {
                Text("Instagram")
                Link("profile", destination: URL(string: "https://www.instagram.com/ugur.altnsy/")!)
            }
            
        }.padding()
    }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func resize(width: CGFloat, height: CGFloat, padding: CGFloat) -> NSImage {
        let img = NSImage(size: CGSize(width: width, height: height))
        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high
        self.draw(
            in: NSMakeRect(0, 0, width, height),
            from: NSMakeRect(0, -padding, size.width, size.height - padding),
            operation: .copy,
            fraction: 1
        )
        img.unlockFocus()
        
        return img
    }
}
