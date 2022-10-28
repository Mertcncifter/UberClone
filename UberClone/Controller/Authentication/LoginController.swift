//
//  LoginController.swift
//  UberClone
//
//  Created by mert can çifter on 17.10.2022.
//

import UIKit

class LoginController: UIViewController {

    // MARK: - Properties
    
    private var viewModel : LoginViewModelProtocol! {
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
        let view = UIView().inputContainerView(image: UIImage(systemName: "person")! , textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()

    private lazy var passwordContainerView: UIView = {
        let view = UIView().inputContainerView(image: UIImage(systemName: "lock")!, textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    var textFields: [UITextField] {
        return [emailTextField, passwordTextField]
    }
    
    private let loginButton: UIButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ",
                                                        attributes: [ .font : UIFont.systemFont(ofSize: 16),
                                                                      .foregroundColor : UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up",
                                                  attributes: [ .font : UIFont.boldSystemFont(ofSize: 16),
                                                                .foregroundColor : UIColor.mainBlueTint]))
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = LoginViewModel()
        configureUI()
        configureLoading()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    // MARK: - Selectors
    
    @objc  func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        viewModel.login(email: email, password: password)
    }
    
    @objc func handleShowSignUp(){
        let controller = SignUpController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - Helpers
    
    func configureUI() {
        configureNavigationBar()
        view.backgroundColor = UIColor.backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView,loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 16
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
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

extension LoginController: LoginViewModelDelegate {

    func handleViewModelOutput(_ output: LoginViewModelOutput) {
        switch output {
        case .setLoading(let bool):
            setLoadingScreen(statu: bool)
        case .error(let error):
         print("DEBUG \(error)")
        default:
            break
         }
    }
    
    
    func navigate(to route: LoginViewRoute) {
        switch route {
        case .home:
            let controller = HomeController()
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
}
