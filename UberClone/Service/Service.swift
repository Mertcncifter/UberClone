//
//  Service.swift
//  UberClone
//
//  Created by mert can çifter on 19.10.2022.
//

import Firebase
import CoreLocation
import GeoFire



struct DriverService {
    
    static let shared = DriverService()
    let DB_REF = Database.database().reference()

    
    func observeTrips(completion: @escaping(Trip) -> Void) {
        DB_REF.child(AppConstants.REF_TRIPS).observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func observeTripCancelled(trip: Trip,completion: @escaping() -> Void) {
        DB_REF.child(AppConstants.REF_TRIPS).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?,DatabaseReference) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid": uid, "state": TripState.accepted.rawValue] as [String: Any]
        DB_REF.child(AppConstants.REF_TRIPS).child(trip.passengerUid).updateChildValues(values,withCompletionBlock: completion)
    }
    
    func updateTripState(trip: Trip, state: TripState,completion: @escaping(Error?, DatabaseReference) -> Void){
        DB_REF.child(AppConstants.REF_TRIPS).child(trip.passengerUid).child("state").setValue(state.rawValue,withCompletionBlock: completion)
        
        if state == .completed {
            DB_REF.child(AppConstants.REF_TRIPS).child(trip.passengerUid).removeAllObservers()
        }
    }
    
    func updateDriverLocation(location: CLLocation){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geofire = GeoFire(firebaseRef: DB_REF.child(AppConstants.REF_DRIVER_LOCATIONS))
        geofire.setLocation(location, forKey: uid)
    }
}

struct PassengerService {
    
    static let shared = PassengerService()
    let DB_REF = Database.database().reference()
    
    func fetchDrivers(location: CLLocation,completion: @escaping(User) -> Void){
        let geoFire = GeoFire(firebaseRef: DB_REF.child(AppConstants.REF_DRIVER_LOCATIONS))
        
        DB_REF.child(AppConstants.REF_DRIVER_LOCATIONS).observe(.value) { (snapshot) in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered,with: { (uid, location) in
                Service.shared.fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
    
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D, _ destinationCoordinates: CLLocationCoordinate2D,
                    completion: @escaping(Error?, DatabaseReference) -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = ["pickupCoordinates": pickupArray, "destinationCoordinates": destinationArray,
                      "state": TripState.requested.rawValue] as [String: Any]
        
        DB_REF.child(AppConstants.REF_TRIPS).child(uid).updateChildValues(values,withCompletionBlock: completion)
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }

        DB_REF.child(AppConstants.REF_TRIPS).child(uid).observe(.value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func deleteTrip(completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DB_REF.child(AppConstants.REF_TRIPS).child(uid).removeValue(completionBlock: completion)
    }
    
    
    
    
}


struct Service{
    
    static let shared = Service()
    let DB_REF = Database.database().reference()
    
    
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void){
        DB_REF.child(AppConstants.REF_USERS).child(uid).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let user = User(uid: uid ,dictionary: dictionary)
            completion(user)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
    
}
