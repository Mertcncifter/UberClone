//
//  HomeViewModel.swift
//  UberClone
//
//  Created by mert can çifter on 19.10.2022.
//

import Firebase
import MapKit

protocol HomeViewModelProtocol {
    var delegate: HomeViewModelDelegate? { get set }
    func load(location: CLLocation?)
    func searchBy(naturalLanguageQuery: String, region: MKCoordinateRegion)
    func uploadTrip(pickupCoordinates: CLLocationCoordinate2D, destinationCoordinates: CLLocationCoordinate2D)
    func cancelTrip()
    func observeTripCancelled(trip: Trip)
    func observeCurrentTripFetchUserData(driverUid: String)
    func didAcceptTripFetchUserData(uid: String)
    func updateDriverLocation(location: CLLocation)
    func updateTripState(trip: Trip, state: TripState, typeId: Int?)
    func startTrip(trip: Trip)
    func completedTrip()
}

enum HomeViewModelOutput{
    case setLoading(Bool)
    case fetchUserData(User)
    case fetchDriver(DriverAnnotation)
    case searchResult([MKPlacemark])
    case observeTrip(Trip)
    case outUploadTrip
    case observeCurrentTrip(Trip)
    case outCancelTrip
    case outObserveTripCancelled
    case outObserveCurrentTripFetchUserData(User)
    case outDidAcceptTripFetchUserData(User)
    case outUpdateTripState(Int?)
    case outStartTrip
    case error(error: String)
}

enum HomeViewRoute {
    
}

protocol HomeViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: HomeViewModelOutput)
    func navigate(to route : HomeViewRoute)
}


final class HomeViewModel: HomeViewModelProtocol {
    func didAcceptTripFetchUserData(uid: String) {
        Service.shared.fetchUserData(uid: uid) { passenger in
            self.notify(.outDidAcceptTripFetchUserData(passenger))
        }
    }
    
    
    weak var delegate: HomeViewModelDelegate?
    var service: Service = Service.shared
    let currentUid = Auth.auth().currentUser?.uid
    var user: User?
    
    func load(location: CLLocation?) {
        fetchUserData(location: location)
    }
    
    func fetchUserData(location: CLLocation?){
        guard let currentUid = currentUid else { return }
        service.fetchUserData(uid: currentUid) { user in
            self.user = user
            self.notify(.fetchUserData(user))
            guard let location = location else { return }
            if user.accountType == .passenger {
                self.fetchDrivers(location: location)
                self.observeCurrentTrip()
            }else{
                self.observeTrips()
            }
        }
    }
    
    func fetchDrivers(location: CLLocation){
        PassengerService.shared.fetchDrivers(location: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            self.notify(.fetchDriver(annotation))
        }
    }
    
    func observeTrips(){
        DriverService.shared.observeTrips { trip in
            self.notify(.observeTrip(trip))
        }
    }
    
    func searchBy(naturalLanguageQuery: String,region: MKCoordinateRegion) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        
        search.start {(response,error) in
            
            guard let response = response else { return }
            
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            
            self.notify(.searchResult(results))
        }
    }
    
    func uploadTrip(pickupCoordinates: CLLocationCoordinate2D, destinationCoordinates: CLLocationCoordinate2D) {
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (err,ref) in
            self.notify(.outUploadTrip)
        }
    }
    
    func observeCurrentTrip(){
        PassengerService.shared.observeCurrentTrip { (trip) in
            self.notify(.observeCurrentTrip(trip))
        }
    }
    
    func cancelTrip() {
        PassengerService.shared.deleteTrip { (error,ref) in
            if let error = error {
                return
            }
            self.notify(.outCancelTrip)
        }
    }
    
    func observeTripCancelled(trip: Trip){
        guard trip.state != .completed else { return }
        
        DriverService.shared.observeTripCancelled(trip: trip) {
            self.notify(.outObserveTripCancelled)
        }
    }
    
    func observeCurrentTripFetchUserData(driverUid: String) {
        Service.shared.fetchUserData(uid: driverUid) { driver in
            self.notify(.outObserveCurrentTripFetchUserData(driver))
        }
    }
    
    func updateDriverLocation(location: CLLocation) {
        DriverService.shared.updateDriverLocation(location: location)
    }
    
    func updateTripState(trip: Trip, state: TripState,typeId: Int?) {
        DriverService.shared.updateTripState(trip: trip, state: state) { (err,ref) in
            if typeId != nil {
                self.notify(.outUpdateTripState(typeId))
            }
        }
    }
    
    func startTrip(trip: Trip){
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { (err,ref) in
            self.notify(.outStartTrip)
        }
        
    }
        
    private func notify(_ output: HomeViewModelOutput){
        delegate?.handleViewModelOutput(output)
    }
    
    func completedTrip() {
        PassengerService.shared.deleteTrip { (error,ref) in
            if let error = error {
                return
            }
            self.notify(.outCancelTrip)
        }
    }

}
