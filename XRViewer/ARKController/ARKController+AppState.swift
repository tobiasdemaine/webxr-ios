import ARKit

extension ARKController {
    /**
     Updates the internal AR Request dictionary
     Creates an ARKit configuration object
     Runs the ARKit session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    func startSession(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arSessionState = .ARKSessionRunning
        
        // if we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        
        // if we've already received authorization for CV or WorldState data, likely because of a preference setting or
        // previous saved approval for the site, make sure we set up the state properly here
        if state.askedComputerVisionData {
            computerVisionDataEnabled = state.userGrantedSendingComputerVisionData
        }
        if state.askedWorldStateData {
            sendingWorldSensingDataAuthorizationStatus = state.userGrantedSendingWorldStateData
        }
        
        setupDeviceCamera()
        setShowMode(state.showMode)
        setShowOptions(state.showOptions)
    }
    
    /**
     Updates the internal AR request dictionary.
     Creates a AR configuration object based on the request.
     Runs the session.
     Sets the session status to running.
     
     @param state the app state
     */
    func runSession(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [])
        arSessionState = .ARKSessionRunning
    }
    
    func runSessionRemovingAnchors(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: .removeExistingAnchors)
        // If we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        arSessionState = .ARKSessionRunning
    }
    
    func runSessionResettingTrackingAndRemovingAnchors(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        // If we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        arSessionState = .ARKSessionRunning
    }
    
    /**
     Updates the internal AR Request dictionary and the configuration
     Runs the session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    func resumeSession(with state: AppState) {
        request = state.aRRequest
        
        if configuration is ARWorldTrackingConfiguration {
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            if hasBackgroundWorldMap() {
                worldTrackingConfiguration?.initialWorldMap = backgroundWorldMap
                backgroundWorldMap = nil
                DDLogError("using Saved WorldMap to resume session")
            } else {
                worldTrackingConfiguration?.initialWorldMap = nil
                DDLogError("no Saved WorldMap, resuming without background worldmap")
            }
        } else {
            DDLogError("resume session on a face-tracking camera")
        }
        session.run(configuration, options: [])
        arSessionState = .ARKSessionRunning
        setupDeviceCamera()
        setShowMode(state.showMode)
        setShowOptions(state.showOptions)
    }
    
    /**
     Updates the internal AR Request dictionary and the configuration
     Runs the session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    func resumeSession(fromBackground state: AppState) {
        request = state.aRRequest
        
        if configuration is ARWorldTrackingConfiguration {
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            if hasBackgroundWorldMap() {
                worldTrackingConfiguration?.initialWorldMap = backgroundWorldMap
                backgroundWorldMap = nil
                DDLogError("using Saved WorldMap to resume session")
            } else {
                worldTrackingConfiguration?.initialWorldMap = nil
                DDLogError("no Saved WorldMap, resuming without background worldmap")
            }
        } else {
            DDLogError("resume session on a face-tracking camera")
        }
        session.run(configuration, options: [])
        arSessionState = .ARKSessionRunning
    }
    
    /**
     Pauses the AR session and sets the arSessionState to paused
     */
    func pauseSession() {
        session.pause()
        arSessionState = .ARKSessionPaused
    }
    
    // The session was paused, which implies it was off of the AR page, somewhere 2D, for a bit
    // The app was backgrounded, so try to reactivate the session map
    func updateARConfiguration(with state: AppState) {
        request = state.aRRequest
        
        // Make sure there is no initial worldmap set
        if configuration is ARWorldTrackingConfiguration {
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            worldTrackingConfiguration?.initialWorldMap = nil
            if hasBackgroundWorldMap() {
                backgroundWorldMap = nil
                DDLogError("clearing Saved Background WorldMap from resume session")
            }
        }
        
        if state.aRRequest[WEB_AR_WORLD_ALIGNMENT] as? Bool ?? false {
            configuration?.worldAlignment = .gravityAndHeading
        } else {
            configuration?.worldAlignment = .gravity
        }
    }
    
    // MARK: - Helpers
    
    func currentFrameTimeInMilliseconds() -> TimeInterval {
        return TimeInterval((session.currentFrame?.timestamp ?? 0.0) * 1000)
    }
    
    func trackingStateNormal() -> Bool {
        guard let ts = session.currentFrame?.camera.trackingState.presentationString else { return false }
        return ts == ARCamera.TrackingState.normal.presentationString
    }
}
