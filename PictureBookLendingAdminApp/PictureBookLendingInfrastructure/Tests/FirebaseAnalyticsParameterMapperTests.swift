import XCTest

@testable import PictureBookLendingInfrastructure

final class FirebaseAnalyticsParameterMapperTests: XCTestCase {
    
    func testStringValueMapsToString() {
        let params = FirebaseAnalyticsParameterMapper.makeParameters(from: [
            "find_method": .string("shelf")
        ])
        
        XCTAssertEqual(params["find_method"] as? String, "shelf")
    }
    
    func testIntValueMapsToInt() {
        let params = FirebaseAnalyticsParameterMapper.makeParameters(from: [
            "total_ms": .int(1200)
        ])
        
        XCTAssertEqual(params["total_ms"] as? Int, 1200)
    }
    
    func testBoolValueMapsToBool() {
        let params = FirebaseAnalyticsParameterMapper.makeParameters(from: [
            "zero_hit": .bool(true)
        ])
        
        XCTAssertEqual(params["zero_hit"] as? Bool, true)
    }
    
    func testEmptyParamsMapsToEmptyDictionary() {
        let params = FirebaseAnalyticsParameterMapper.makeParameters(from: [:])
        
        XCTAssertTrue(params.isEmpty)
    }
    
    func testMultipleValuesPreserveAllKeys() {
        let params = FirebaseAnalyticsParameterMapper.makeParameters(from: [
            "slot_type": .string("child"),
            "total_ms": .int(3400),
            "guardian_fallback": .bool(false),
        ])
        
        XCTAssertEqual(params.count, 3)
        XCTAssertEqual(params["slot_type"] as? String, "child")
        XCTAssertEqual(params["total_ms"] as? Int, 3400)
        XCTAssertEqual(params["guardian_fallback"] as? Bool, false)
    }
}
