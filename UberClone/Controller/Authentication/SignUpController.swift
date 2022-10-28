//
//  SignUpController.swift
//  UberClone
//
//  Created by mert can çifter on 17.10.2022.
//

import UIKit

class SignUpController : UIViewController {
    
    // MARK: - Properties
    
    private var viewModel : SignUpViewModelProtocol! {
        didSet {
            viewModel.delegate = self
        }
    }
    
    let spinner = UIActivityIndicatorView(style: .large)
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private lazy var emailContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var fullNameContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullnameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    
    private lazy var passwordContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var accountTypeContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: accountTypeSegmentedControl)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let fullnameTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Full Name", isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
       let sc = UISegmentedControl(items: ["Rider", "Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        
        return sc
    }()
    
    private let signUpButton: UIButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Already have an account ",
                                                        attributes: [ .font : UIFont.systemFont(ofSize: 16),
                                                                      .foregroundColor : UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up",
                                                  attributes: [ .font : UIFont.boldSystemFont(ofSize: 16),
                                                                .foregroundColor : UIColor.mainBlueTint]))
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        viewModel = SignUpViewModel()
        configureUI()
        configureLoading()
    }
    
    // MARK: - Selectors
    
    @objc func handleSignUp() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullname = fullnameTextField.text else { return }
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        viewModel.signUp(email: email, password: password, fullName: fullname, accountTypeIndex: accountTypeIndex)
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers
   
    
    func configureUI() {
        view.backgroundColor = UIColor.backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,
                                                   fullNameContainerView,
                                                   passwordContainerView,
                                                   accountTypeContainerView,
                                                   signUpButton])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 16
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    func configureLoading(){
        let container = UIView()
        container.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        spinner.center = self.view.center
        container.addSubview(spinner)
        self.view.addSubview(container)
    }
    
    private func setLoadingScreen(statu: Bool) {
        if statu {
            self.view.isUserInteractionEnabled = false
            spinner.startAnimating()
        }else{
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                self.spinner.stopAnimating()
                self.spinner.isHidden = true
            }
        }
    }
}


extension SignUpController: SignUpViewModelDelegate {

    func handleViewModelOutput(_ output: SignUpViewModelOutput) {
        switch output {
        case .setLoading(let bool):
            setLoadingScreen(statu: bool)
        case .error(let error):
         print("DEBUG \(error)")
        default:
            break
         }
    }
    
    
    func navigate(to route: SignUpViewRoute) {
        switch route {
        case .home:
            let controller = HomeController()
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
}
