//
//  RegisterViewModel.swift
//  UberClone
//
//  Created by mert can çifter on 17.10.2022.
//

import Foundation
import FirebaseAuth
import GeoFire

protocol SignUpViewModelProtocol {
    var delegate: SignUpViewModelDelegate? { get set }
    func signUp(email: String, password: String,fullName: String, accountTypeIndex: Int)
}

enum SignUpViewModelOutput{
    case setLoading(Bool)
    case error(error: String)
}

enum SignUpViewRoute {
    case home
}

protocol SignUpViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: SignUpViewModelOutput)
    func navigate(to route : SignUpViewRoute)
}

final class SignUpViewModel: SignUpViewModelProtocol {
    weak var delegate: SignUpViewModelDelegate?
    private let location = LocationHandler.shared.locationManager.location
    let DB_REF = Database.database().reference()
    
    func signUp(email: String, password: String, fullName: String, accountTypeIndex: Int) {
        notify(.setLoading(true))
        Auth.auth().createUser(withEmail: email, password: password) { (result,error) in
            self.notify(.setLoading(false))
            if let error = error {
                self.notify(.error(error: error.localizedDescription))
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            let values = ["email": email,
                          "fullname": fullName,
                          "accountType": accountTypeIndex] as [String : Any]
            
            if accountTypeIndex == 1 {
                let geofire = GeoFire(firebaseRef: self.DB_REF.child(AppConstants.REF_DRIVER_LOCATIONS))
                guard let location = self.location else { return }
                
                geofire.setLocation(location, forKey: uid) { (error) in
                    self.saveUser(uid: uid, values: values)
                }
            }else{
                self.saveUser(uid: uid, values: values)
            }
            
        }
    }
    
    private func saveUser(uid: String, values: [String : Any]){
        self.DB_REF.child(AppConstants.REF_USERS).child(uid).updateChildValues(values) { (error,ref) in
            self.goHome()
        }
    }
    
    private func notify(_ output: SignUpViewModelOutput){
        delegate?.handleViewModelOutput(output)
    }
    
    func goHome(){
        delegate?.navigate(to: .home)
    }
    
}
