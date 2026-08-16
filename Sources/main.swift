import SwiftUI

enum InstallState {
    case idle
    case running
    case success
    case failure
}

final class Installer: ObservableObject {
    @Published var state: InstallState = .idle
    @Published var log: String = ""

    private let installCommand =
        #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    func start() {
        guard state != .running else { return }
        state = .running
        log = ""

        DispatchQueue.global(qos: .userInitiated).async {
            let ok = self.runInstallScript()
            if ok {
                self.configureZshProfile()
            }
            DispatchQueue.main.async {
                self.state = ok ? .success : .failure
            }
        }
    }

    private func append(_ text: String) {
        DispatchQueue.main.async {
            self.log += text
        }
    }

    private func runInstallScript() -> Bool {
        guard let askpass = Bundle.main.path(forResource: "askpass", ofType: "sh") else {
            append("Internal error: askpass helper is missing from the app bundle.\n")
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", installCommand]

        var env = ProcessInfo.processInfo.environment
        env["NONINTERACTIVE"] = "1"
        env["SUDO_ASKPASS"] = askpass
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                self.append(text)
            }
        }

        do {
            try process.run()
        } catch {
            append("Failed to start the installer: \(error.localizedDescription)\n")
            return false
        }
        process.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        return process.terminationStatus == 0
    }

    private func configureZshProfile() {
        let brew = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
            .first { FileManager.default.fileExists(atPath: $0) }
        guard let brew else {
            append("\nWarning: brew was not found. The shell profile was not changed.\n")
            return
        }

        let line = "eval \"$(\(brew) shellenv)\""
        let profileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".zprofile")
        let existing = (try? String(contentsOf: profileURL, encoding: .utf8)) ?? ""

        if existing.contains(line) {
            append("\nThe shell profile already contains the Homebrew setup line.\n")
            return
        }

        var updated = existing
        if !updated.isEmpty && !updated.hasSuffix("\n") {
            updated += "\n"
        }
        updated += line + "\n"

        do {
            try updated.write(to: profileURL, atomically: true, encoding: .utf8)
            append("\nAdded the Homebrew setup line to ~/.zprofile.\n")
        } catch {
            append("\nWarning: could not update ~/.zprofile: \(error.localizedDescription)\n")
        }
    }
}

struct ContentView: View {
    @StateObject private var installer = Installer()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Homebrew Installer")
                        .font(.title2.bold())
                    Text("Installs the Homebrew package manager on this Mac.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            switch installer.state {
            case .idle:
                Text("Click Install. When macOS asks for your login password, enter it. The installation can take several minutes.")
                    .font(.callout)
            case .running:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Installing… do not close this window.")
                        .font(.callout)
                }
            case .success:
                Label("Homebrew is installed and your shell profile is configured.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout.bold())
            case .failure:
                Label("The installation failed. Review the log below.", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.callout.bold())
            }

            LogView(text: installer.log)
                .frame(minHeight: 220)

            HStack {
                Spacer()
                if installer.state == .success {
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button(installer.state == .failure ? "Try Again" : "Install Homebrew") {
                        installer.start()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(installer.state == .running)
                }
            }
        }
        .padding(20)
        .frame(width: 560)
    }
}

struct LogView: View {
    let text: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text.isEmpty ? " " : text)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .id("bottom")
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
            .onChange(of: text) { _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

@main
struct HomebrewInstallerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
