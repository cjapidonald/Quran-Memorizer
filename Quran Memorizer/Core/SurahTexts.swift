import Foundation

struct SurahTextContent {
    let arabic: [String]
    let english: [String]
}

enum SurahTexts {
    static func text(for id: Int) -> SurahTextContent? {
        switch id {
        case 1:
            return SurahTextContent(
                arabic: [
                    "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                    "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَالَمِينَ",
                    "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                    "مَالِكِ يَوْمِ ٱلدِّينِ",
                    "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
                    "ٱهْدِنَا ٱلصِّرَاطَ ٱلْمُسْتَقِيمَ",
                    "صِرَاطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّالِّينَ"
                ],
                english: [
                    "In the Name of Allah—the Most Compassionate, Most Merciful.",
                    "All praise is for Allah—Lord of all worlds,",
                    "the Most Compassionate, Most Merciful,",
                    "Master of the Day of Judgment.",
                    "You ˹alone˺ we worship and You ˹alone˺ we ask for help.",
                    "Guide us along the Straight Path,",
                    "the Path of those You have blessed—not those You are displeased with, or those who are astray."
                ]
            )
        default:
            return nil
        }
    }
}
