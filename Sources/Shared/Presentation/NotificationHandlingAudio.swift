#if canImport(AudioToolbox)
import AudioToolbox

private enum BeepPlayer {
    static let soundID: SystemSoundID = {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav")
        else { preconditionFailure("beep.wav missing from bundle") }
        var id: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &id)
        return id
    }()
}

extension NotificationHandling {
    static func beep() {
        AudioServicesPlayAlertSound(BeepPlayer.soundID)
    }
}
#endif
