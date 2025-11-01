access(all) contract Burner {
    
    /// Burnable interface for resources that want to implement custom burn logic
    access(all) resource interface Burnable {
        access(contract) fun burnCallback()
    }

    /// burn destroys any resource it is given
    /// If the resource implements Burnable, it calls burnCallback first
    access(all) fun burn(_ toBurn: @AnyResource?) {
        if toBurn == nil {
            destroy toBurn
            return
        }
        let r <- toBurn!

        if let s <- r as? @{Burnable} {
            s.burnCallback()
            destroy s
        } else {
            destroy r
        }
    }
}