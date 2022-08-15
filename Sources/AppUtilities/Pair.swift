
public struct Pair<T, U> {
    let item1: T
    let item2: U
    
    init(item1: T, item2: U) {
        self.item1 = item1
        self.item2 = item2
    }
    
    init(_ item1: T, _ item2: U) {
        self.item1 = item1
        self.item2 = item2
    }
    
    init?(_ tuple: (T, U)?) {
        guard let tuple = tuple else {
            return nil
        }
        
        self.item1 = tuple.0
        self.item2 = tuple.1
    }
    
    var tuple: (T, U) {
        (item1, item2)
    }
}

extension Pair: Codable where T: Codable, U: Codable {
    
}

extension Pair: Hashable where T: Hashable, U: Hashable {
    
}

extension Pair: Equatable where T: Equatable, U: Equatable {
    
}
