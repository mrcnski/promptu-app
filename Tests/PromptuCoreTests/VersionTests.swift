import Testing

@testable import PromptuCore

@Test func newerVersionIsNewer() {
    #expect(Version.isNewer("0.5.0", than: "0.4.0"))
    #expect(Version.isNewer("1.0.0", than: "0.9.9"))
    #expect(Version.isNewer("0.4.1", than: "0.4.0"))
}

@Test func olderOrEqualIsNotNewer() {
    #expect(!Version.isNewer("0.4.0", than: "0.4.0"))
    #expect(!Version.isNewer("0.3.9", than: "0.4.0"))
    #expect(!Version.isNewer("0.4.0", than: "0.5.0"))
}

@Test func fieldsCompareNumericallyNotLexically() {
    // The bug a string compare would have: "0.10.0" < "0.4.0" as text.
    #expect(Version.isNewer("0.10.0", than: "0.4.0"))
    #expect(!Version.isNewer("0.4.0", than: "0.10.0"))
}

@Test func missingTrailingFieldsReadAsZero() {
    #expect(!Version.isNewer("1.0", than: "1.0.0"))
    #expect(Version.isNewer("1.1", than: "1.0.0"))
    #expect(Version.isNewer("2", than: "1.9.9"))
}

@Test func leadingVIsIgnored() {
    #expect(Version.isNewer("v0.5.0", than: "0.4.0"))
    #expect(Version.isNewer("v0.5.0", than: "v0.4.0"))
    #expect(!Version.isNewer("v0.4.0", than: "0.4.0"))
}

@Test func malformedTagNeverBeatsRunningBuild() {
    #expect(!Version.isNewer("garbage", than: "0.4.0"))
    #expect(!Version.isNewer("v", than: "0.4.0"))
    #expect(!Version.isNewer("", than: "0.4.0"))
}
