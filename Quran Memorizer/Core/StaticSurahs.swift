import Foundation

enum StaticSurahs {
    static let all: [Surah] = {
        var s: [Surah] = [
            .init(id: 1, arabicName: "ٱلْفَاتِحَة", englishName: "Al-Fātiḥah", ayahCount: 7),
            .init(id: 2, arabicName: "ٱلْبَقَرَة", englishName: "Al-Baqarah", ayahCount: 286),
            .init(id: 3, arabicName: "آلِ عِمْرَان", englishName: "Āl ʿImrān", ayahCount: 200),
            .init(id: 4, arabicName: "ٱلنِّسَاء", englishName: "An-Nisā’", ayahCount: 176),
            .init(id: 5, arabicName: "ٱلْمَائِدَة", englishName: "Al-Mā’idah", ayahCount: 120),
            .init(id: 6, arabicName: "ٱلْأَنْعَام", englishName: "Al-Anʿām", ayahCount: 165),
            .init(id: 7, arabicName: "ٱلْأَعْرَاف", englishName: "Al-Aʿrāf", ayahCount: 206),
            .init(id: 8, arabicName: "ٱلْأَنْفَال", englishName: "Al-Anfāl", ayahCount: 75),
            .init(id: 9, arabicName: "ٱلتَّوْبَة", englishName: "At-Tawbah", ayahCount: 129),
            .init(id:10, arabicName: "يُونُس",    englishName: "Yūnus", ayahCount: 109),
        ]
        if s.count < 114 {
            for i in (s.count+1)...114 {
                s.append(.init(id: i, arabicName: "سورة \(i)", englishName: "Surah \(i)", ayahCount: 7))
            }
        }
        return s
    }()
}
