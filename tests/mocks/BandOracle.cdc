access(all) contract BandOracle {
    access(contract) var fee: UFix64
    
    access(all) fun getFee(): UFix64 {
        return self.fee
    }
    
    init() {
        self.fee = 0.001
    }
}