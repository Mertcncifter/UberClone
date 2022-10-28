//
//  HomeController.swift
//  UberClone
//
//  Created by mert can çifter on 17.10.2022.
//

import UIKit
import Firebase
import MapKit


private enum ActionButtonConfiguration{
    case showMenu
    case dismissActionView
    
    init(){
        self = .showMenu
    }
}

private enum AnnotationType: String{
    case pickup
    case destination
}

protocol HomeControllerDelegate: class {
    func handleMenuToggle()
}

class HomeController : UIViewController {

    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let rideActionView = RideActionView()
    private let locationInputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private let locationManager = LocationHandler.shared.locationManager
    private var searchResults = [MKPlacemark]()
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    
    weak var delegate: HomeControllerDelegate?

    
    
    private var viewModel : HomeViewModelProtocol! {
        didSet {
            viewModel.delegate = self
            viewModel.load(location: locationManager?.location)
        }
    }
    
    public var user: User? {
        didSet{
            locationInputView.user = user
        }
    }
    
    private var trip: Trip? {
        didSet {
            
            guard let user = user else { return }
            
            if user.accountType == .driver {
                
                guard let trip = trip else { return }
                let controller = PickupController(trip: trip)
                controller.delagate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
                
            } else {
                
            }
        }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
        
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = HomeViewModel()
        enableLocationServices()
        configureUI()
    }
    
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed(){
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
            
        case .dismissActionView:
            removeAnnotationAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.locationInputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
            
        }
    }
    
    
    // MARK: - Helpers
    
    
    func configureUI(){
        configureMapView()
        configureRideActionView()
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        configureTableView()
    }
    
    
    func configureLocationInputActivationView(){
        guard user?.accountType == .passenger else { return }
        view.addSubview(locationInputActivationView)
        locationInputActivationView.centerX(inView: view)
        locationInputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        locationInputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        locationInputActivationView.alpha = 0
        locationInputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            self.locationInputActivationView.alpha = 1
        }
    }
    
    func configureMapView(){
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    func configureLocationInputView(){
        locationInputView.delagete = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 200)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
            
        }
    }
    
    func configureRideActionView(){
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight
        
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil,
                               config: RideActionViewConfiguration? = nil, user: User? = nil){
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        
        if shouldShow {
            guard let config = config else { return }
            
            if let destination = destination {
                rideActionView.destination = destination
            }
            
            if let user = user {
                rideActionView.user = user
            }
            
            rideActionView.config = config

        }
    }
    
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration){
        switch config {
        case .showMenu:
            let image =  #imageLiteral(resourceName: "baseline_menu_black_36dp")
            self.actionButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            let image =  #imageLiteral(resourceName: "baseline_arrow_back_black_36dp")
            self.actionButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .dismissActionView

        }
    }
    
    func signOut(){
        do {
            try Auth.auth().signOut()
        }catch{
            
        }
    }
}


// MARK: - MapView Helper Functions

private extension HomeController {
    
    func searchBy(naturalLanguageQuery: String) {
        viewModel.searchBy(naturalLanguageQuery: naturalLanguageQuery, region: mapView.region)
    }
    
    func generatePolyline(toDestionation destination: MKMapItem){
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response,error) in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline,level: .aboveRoads)
        }
    }
    
    func removeAnnotationAndOverlays(){
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withType type: AnnotationType, withCoordinates coordinates: CLLocationCoordinate2D){
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
    }
    
    func zoomForActiveTrip(withDriverUid uid: String){
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }
        
        self.mapView.zoomToFit(annotations: annotations)
    }
}



// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else { return }
        guard user.accountType == .driver else { return }
        guard let location = userLocation.location else { return }
        viewModel.updateDriverLocation(location: location)
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: AppConstants.annotationIdentifier)
            view.image =  #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRendered = MKPolylineRenderer(overlay: polyline)
            lineRendered.strokeColor = .mainBlueTint
            lineRendered.lineWidth = 4
            return lineRendered
        }
        
        return MKOverlayRenderer()
    }
}


// MARK: - LocationServices

extension HomeController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        self.rideActionView.config = .pickupPassenger
        guard let trip = self.trip else { return }
        
        if region.identifier == AnnotationType.pickup.rawValue {
            viewModel.updateTripState(trip: trip, state: .driverArrived,typeId: 0)
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            viewModel.updateTripState(trip: trip, state: .driverArrived,typeId: 1)
        }
        
        
        
    }
    
    func enableLocationServices() {
        locationManager?.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case.authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
        break
        }
    }
}


// MARK: - LocationInputActivationViewDeletage

extension HomeController : LocationInputActivationViewDeletage {
    func presentLocationInputView() {
        locationInputActivationView.alpha = 0
        configureLocationInputView()
    }
}


// MARK: - LocationInputActivationViewDeletage

extension HomeController : LocationInputViewDelegate {
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5) {
                self.locationInputActivationView.alpha = 1
            }
        }
    }
    
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query)
    }
}


// MARK: - LocationInputActivationViewDeletage

extension HomeController : UITableViewDelegate, UITableViewDataSource {
   
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.reuseIdentifier, for: indexPath) as! LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestionation: destination)
        
        dismissLocationView { _ in
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        shouldPresentLoadingView(true, message: "Finding you a ride..")
        viewModel.uploadTrip(pickupCoordinates: pickupCoordinates, destinationCoordinates: destinationCoordinates)
    }
    
    func cancelTrip() {
        viewModel.cancelTrip()
    }
    
    func pickupPassenger() {
        guard let trip = self.trip else { return }
        viewModel.startTrip(trip: trip)
    }
    
    func dropOffPassenger() {
        guard let trip = self.trip else { return }
        viewModel.updateTripState(trip: trip, state: .completed, typeId: nil)
        self.removeAnnotationAndOverlays()
        self.centerMapOnUserLocation()
        self.animateRideActionView(shouldShow: false)
    }
}


// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
                
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, withCoordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestionation: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        viewModel.observeTripCancelled(trip: trip)
        
        self.dismiss(animated: true) {
            self.viewModel.didAcceptTripFetchUserData(uid: trip.passengerUid)
        }
    }
}


// MARK: - HomeViewModelDelegate

extension HomeController: HomeViewModelDelegate {

    func handleViewModelOutput(_ output: HomeViewModelOutput) {
        switch output {
        case .setLoading(_):
            break
        case .fetchUserData(let user):
            self.fetchUserData(user: user)
        case .fetchDriver(let annotation):
            self.fetchDriver(annotation: annotation)
        case .searchResult(let placemarks):
            self.searchResult(placemarks: placemarks)
        case .observeTrip(let trip):
            self.observeTrip(trip: trip)
        case .outUploadTrip:
            self.resUploadTrip()
        case .observeCurrentTrip(let trip):
            self.observeCurrentTrip(trip: trip)
        case .outCancelTrip:
            self.outCancelTrip()
        case .outObserveTripCancelled:
            self.outObserveTripCancelled()
        case .outObserveCurrentTripFetchUserData(let passenger):
            self.outObserveCurrentTripFetchUserData(passenger: passenger)
        case .outDidAcceptTripFetchUserData(let passenger):
            self.outDidAcceptTripFetchUserData(passenger: passenger)
        case .outUpdateTripState(let typeId):
            self.outUpdateTripState(typeId: typeId)
        case .outStartTrip:
            self.outStartTrip()
        case .error(let error):
         print("DEBUG \(error)")
        }
    }
    
    
    func navigate(to route: HomeViewRoute) {
        
    }
}


extension HomeController {
    func fetchUserData(user: User){
        self.user = user
        configureLocationInputActivationView()
    }
    
    func fetchDriver(annotation: DriverAnnotation){
        var driverIsVisible: Bool {
            return self.mapView.annotations.contains { mAnnotation in
                guard let driverAnno = mAnnotation as? DriverAnnotation else { return false}
                if driverAnno.uid == annotation.uid {
                    driverAnno.updateAnnotationPosition(withCoordinate: annotation.coordinate)
                    self.zoomForActiveTrip(withDriverUid: annotation.uid)
                    return true
                }
                return false
            }
        }
        
        if !driverIsVisible {
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func searchResult(placemarks: [MKPlacemark]){
        self.searchResults = placemarks
        tableView.reloadData()
    }
    
    func observeTrip(trip: Trip){
        self.trip = trip
    }
    
    func resUploadTrip(){
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = self.view.frame.height
        }
    }
    
    func observeCurrentTrip(trip: Trip){
        self.trip = trip
        
        guard let state = trip.state else { return }
        guard let driverUid = trip.driverUid else { return }

        
        switch state {
        case .requested:
            break
            
        case .accepted:
            self.shouldPresentLoadingView(false)
            self.removeAnnotationAndOverlays()
            self.zoomForActiveTrip(withDriverUid: driverUid)
            
            viewModel.observeCurrentTripFetchUserData(driverUid: driverUid)
            
        case .driverArrived:
            self.rideActionView.config = .driverArrived
            
        case .inProgress:
            self.rideActionView.config = .tripInProgress
            
        case .arrivedAtDestination:
            self.rideActionView.config = .endTrip
            
        case .completed:
            viewModel.completedTrip()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.configureActionButton(config: .showMenu)
            self.locationInputActivationView.alpha = 1
            self.presentAlertController(withTitle: "Trip Completed", message: "We hope you enjoyed your trip")
            
        }
        
      
    }
    
    func outCancelTrip(){
        self.centerMapOnUserLocation()
        self.animateRideActionView(shouldShow: false)
        self.removeAnnotationAndOverlays()
        
        let image =  #imageLiteral(resourceName: "baseline_menu_black_36dp")
        self.actionButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        self.actionButtonConfig = .showMenu
        
        self.locationInputActivationView.alpha = 0
    }
    
    func outObserveTripCancelled(){
        self.removeAnnotationAndOverlays()
        self.animateRideActionView(shouldShow: false)
        self.centerMapOnUserLocation()
        self.presentAlertController(withTitle: "Oops!", message: "The passenger has decided to cancel this ride. Press OK to continue")
    }
    
    func outObserveCurrentTripFetchUserData(passenger: User){
        self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
    }
    
    func outDidAcceptTripFetchUserData(passenger: User){
        self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
    }
    
    func outUpdateTripState(typeId: Int?){
        guard let typeId = typeId else { return }
            
    
        if typeId == 0{
            self.rideActionView.config = .pickupPassenger
        } else {
            self.rideActionView.config = .endTrip
        }
        
    }
    
    func outStartTrip(){
        guard let trip = self.trip else { return }
        self.rideActionView.config = .tripInProgress
        self.removeAnnotationAndOverlays()
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        
        self.setCustomRegion(withType: .destination, withCoordinates: trip.destinationCoordinates)
        
        self.generatePolyline(toDestionation: mapItem)
        
        self.mapView.zoomToFit(annotations: self.mapView.annotations)
    }
}







