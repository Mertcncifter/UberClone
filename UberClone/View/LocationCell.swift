//
//  LocationCell.swift
//  UberClone
//
//  Created by mert can çifter on 18.10.2022.
//

import UIKit
import MapKit

class LocationCell: UITableViewCell {
    
    static let reuseIdentifier = "LocationCell"
    
    var placemark: MKPlacemark? {
        didSet {
            titleLabel.text = placemark?.name
            adressLabel.text = placemark?.address
        }
    }

    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Header"
        return label
    }()
    
    private let adressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = "Footer"
        return label
    }()
    
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, adressLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
