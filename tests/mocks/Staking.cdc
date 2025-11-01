access(all) contract Staking {
    access(all) let UserCertificateStoragePath: StoragePath
    
    access(all) resource UserCertificate {
        init() {
            // Simple resource for testing
        }
    }
    
    access(all) fun createUserCertificate(): @UserCertificate {
        return <- create UserCertificate()
    }
    
    init() {
        self.UserCertificateStoragePath = /storage/UserCertificate
    }
}