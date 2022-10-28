//
//  DriverAnnotation.swift
//  UberClone
//
//  Created by mert can çifter on 19.10.2022.
//

import MapKit


class DriverAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    let uid: String
    
    init(uid: String,coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationPosition(withCoordinate coordinate: CLLocationCoordinate2D){
        UIView.animate(withDuration: 0.2) {
            self.coordinate = coordinate
        }
    }
}
