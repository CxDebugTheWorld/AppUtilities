import XCTest
@testable import AppUtilities

final class AppUtilitiesTests: XCTestCase {
    func testClamp() {
        XCTAssertEqual(3,     clamp(3.141, lower: 1, upper: 3))
        XCTAssertEqual(3.141, clamp(3.141, lower: 1, upper: 5))
        XCTAssertEqual(1,     clamp(0.141, lower: 1, upper: 3))
        XCTAssertEqual(3,     clamp(3, lower: 1, upper: 3))
        XCTAssertEqual(1,     clamp(1, lower: 1, upper: 3))
    }
    
    func testRNGDeterminism() {
        let seeds: [UInt64] = [9281, 28931, 647831, 38130]
        for seed in seeds {
            var baseRng = ARC4RandomNumberGenerator(seed: seed)
            let baseline = [Int](repeating: 0, count: 10).map { _ in baseRng.random(in: Int.min...Int.max) }
            
            for _ in 0..<5 {
                var nextRng = ARC4RandomNumberGenerator(seed: seed)
                XCTAssertEqual([Int](repeating: 0, count: 10).map { _ in nextRng.random(in: Int.min...Int.max) }, baseline)
            }
        }
    }
    
    func testFormatTimeLimit() {
        XCTAssertEqual("00:00", Format.formatTimeLimit(0, includeMilliseconds: false))
        XCTAssertEqual("00:00.0", Format.formatTimeLimit(0, includeMilliseconds: true))
        
        XCTAssertEqual("00:35", Format.formatTimeLimit(35.5, includeMilliseconds: false))
        XCTAssertEqual("00:35.5", Format.formatTimeLimit(35.5, includeMilliseconds: true))
        
        XCTAssertEqual("01:35", Format.formatTimeLimit(95.5, includeMilliseconds: false))
        XCTAssertEqual("01:35.5", Format.formatTimeLimit(95.5, includeMilliseconds: true))
        
        XCTAssertEqual("59:59", Format.formatTimeLimit(59*60 + 59.9, includeMilliseconds: false))
        XCTAssertEqual("59:59.9", Format.formatTimeLimit(59*60 + 59.9, includeMilliseconds: true))
        
        XCTAssertEqual("01:00:00", Format.formatTimeLimit(59*60 + 60, includeMilliseconds: false))
        XCTAssertEqual("01:00:00", Format.formatTimeLimit(59*60 + 60, includeMilliseconds: true))
        
        XCTAssertEqual("01:01:35", Format.formatTimeLimit(60*60 + 95.7, includeMilliseconds: false))
        XCTAssertEqual("01:01:35", Format.formatTimeLimit(60*60 + 95.7, includeMilliseconds: true))
    }
    
    func testVersionFromString() {
        let strings = [
            "1",
            "2.2",
            "0.3.1",
            "0.5.2.1",
            "1.1.1D",
            "1.1D.1",
            "-1.3.5",
            "1.",
            "99.99.99",
            "2101.28.2112",
            "a.b.c",
            "1.a",
        ]
        
        let expected: [VersionTriple?] = [
            .init(major: 1, minor: 0, patch: 0),
            .init(major: 2, minor: 2, patch: 0),
            .init(major: 0, minor: 3, patch: 1),
            nil,
            .init(major: 1, minor: 1, patch: 1),
            nil,
            nil,
            .init(major: 1, minor: 0, patch: 0),
            .init(major: 99, minor: 99, patch: 99),
            .init(major: 2101, minor: 28, patch: 2112),
            nil,
            nil,
        ]
        
        for i in 0..<strings.count {
            XCTAssertEqual(VersionTriple(versionString: strings[i]), expected[i])
        }
    }
    
    func testVersionComparison() {
        XCTAssertLessThan(VersionTriple(major: 1, minor: 1, patch: 0), VersionTriple(major: 1, minor: 1, patch: 1)) // 1.1.0 < 1.1.1
        XCTAssertLessThan(VersionTriple(major: 1, minor: 1, patch: 0), VersionTriple(major: 2, minor: 0, patch: 0)) // 1.1.0 < 2.0.0
        XCTAssertLessThan(VersionTriple(major: 1, minor: 9, patch: 0), VersionTriple(major: 2, minor: 0, patch: 0)) // 1.9.0 < 2.0.0
        XCTAssertLessThan(VersionTriple(major: 0, minor: 0, patch: 1), VersionTriple(major: 0, minor: 0, patch: 2)) // 0.0.1 < 0.0.2
        XCTAssertLessThan(VersionTriple(major: 0, minor: 1, patch: 0), VersionTriple(major: 0, minor: 2, patch: 0)) // 0.1.0 < 0.2.0
        XCTAssertLessThan(VersionTriple(major: 1, minor: 0, patch: 0), VersionTriple(major: 1, minor: 0, patch: 1)) // 1.0.0 < 1.0.1
    }
    
    func testStartOfDay() {
        let calendar = Calendar(identifier: .gregorian)
        let startComponents = DateComponents(timeZone: .current, year: 2020, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        var currentDate = calendar.date(from: startComponents)!
        var expectedDay = 1
        var expectedMonth = 1
        var expectedYear = 2020
        
        for i in 1...367 {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate.startOfDay)
            XCTAssertEqual(components.year, expectedYear)
            XCTAssertEqual(components.month, expectedMonth)
            XCTAssertEqual(components.day, expectedDay)
            
            switch i {
            case 31:
                fallthrough
            case 60:
                fallthrough
            case 91:
                fallthrough
            case 121:
                fallthrough
            case 152:
                fallthrough
            case 182:
                fallthrough
            case 213:
                fallthrough
            case 244:
                fallthrough
            case 274:
                fallthrough
            case 305:
                fallthrough
            case 335:
                expectedDay = 1
                expectedMonth += 1
            case 366:
                expectedDay = 1
                expectedMonth = 1
                expectedYear += 1
            default:
                expectedDay += 1
            }
            
            currentDate.addTimeInterval(24*60*60)
        }
    }
    
    func testStartOfMonth() {
        let dates = [
            "2021-02-28T00:00:00+0000",
            "2021-02-28T10:00:00+0000",
            "2021-02-01T18:59:59+0000",
            "2021-02-01T00:00:00+0000",
            
            "2021-10-31T19:01:00+0000",
            "2021-11-30T23:59:59+0000",
            "2023-06-15T16:02:04+0000",
        ]
        
        let expected = [
            "2021-02-01T00:00:00+0000",
            "2021-02-01T00:00:00+0000",
            "2021-02-01T00:00:00+0000",
            "2021-02-01T00:00:00+0000",
            
            "2021-10-01T00:00:00+0000",
            "2021-11-01T00:00:00+0000",
            "2023-06-01T00:00:00+0000",
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = .utc
        
        var i = 0
        for dateStr in dates {
            let date = dateFormatter.date(from: dateStr)!
            XCTAssertEqual(expected[i], dateFormatter.string(from: date.startOfMonth))
            
            i += 1
        }
    }
    
    func testMean() {
        let tests: [([Float], [Float], [Float])] = [
            ([1, 2, 3], [5, 6, 7], [6/3, 11/4, 17/5, 24/6]),
            (
                [5.3, 132.5, 69.2],
                [21.53, 212.84, 6.5],
                [
                    (5.3+132.5+69.2)/3,
                    (5.3+132.5+69.2+21.53)/4,
                    (5.3+132.5+69.2+21.53+212.84)/5,
                    (5.3+132.5+69.2+21.53+212.84+6.5)/6,
                ]
            ),
        ]
        
        for (values, newValues, expectedMeans) in tests {
            var values = values
            var mean = values.mean!
            
            XCTAssertEqual(mean, expectedMeans[0], accuracy: 0.1)
            
            for i in 0..<newValues.count {
                let newValue = newValues[i]
                values.append(newValue)
                
                XCTAssertEqual(values.mean!, expectedMeans[i+1], accuracy: 0.1)
                
                let newMean = Float.updateRunningMean(meanSoFar: mean, valueCountSoFar: values.count - 1, newValue: newValue)
                XCTAssertEqual(newMean, expectedMeans[i+1], accuracy: 0.1)
                
                mean = newMean
            }
        }
    }
    
    func testSetExtensions() {
        let tests: [(Set<Int>, [Int], Int)] = [
            ([1, 2, 3, 4, 5], [1, 3, 8, 9], 2),
            ([1, 2, 3, 4, 5, 8, 9, 10], [1, 3, 8, 9], 0),
            ([1, 2, 3, 4, 5], [0, 10, 18, 8, 9], 5),
        ]
        
        for (values, newValues, expectedNewValueCount) in tests {
            var testValues = values
            
            let newValueCount = testValues.insert(contentsOf: newValues)
            XCTAssertEqual(newValueCount, expectedNewValueCount)
            
            var controlValues = values
            for v in newValues {
                controlValues.insert(v)
            }
            
            XCTAssertEqual(testValues, controlValues)
        }
    }
    
    func testDictionaryExtensions() {
        let tests: [([String: Int], [String: Int], [String: Int])] = [
            (
                ["A": 3,  "B": 94, "C": 90],
                ["A": 21, "B": 5,           "D": 29],
                ["A": 24, "B": 99, "C": 90, "D": 29]
            ),
        ]
        
        for (dict, valuesToAdd, expected) in tests {
            var dict = dict
            dict.add(valuesOf: valuesToAdd)
            
            XCTAssertEqual(dict, expected)
        }
    }
}
