import UIKit

class PokemonViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var firstPowerLabel: UILabel!
    @IBOutlet weak var secondPowerLabel: UILabel!
    @IBOutlet weak var catchButton: UIButton!
    @IBOutlet weak var pokemonImage: UIImageView!
    @IBOutlet weak var pokemonDetails: UITextView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var contentView: UIView!

    // MARK: - Stored properties
    public var url = ""
    private var isCaughtTapped = false
    private var pokemonResult: PokemonResult?
    private var pokemonDetailsResult: PokemonDetails?
    private let pokemonDetailsURL = "https://pokeapi.co/api/v2/pokemon-species/"


    // MARK: - Lifecycle functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the contentView and start the progress bar
        contentView.isHidden = true
        loadingIndicator.startAnimating()

        loadPokemonInformation()
    }

    // MARK: - Functions
    /// Function to load the pokemon information after the loading of the pokemon information is complete
    private func loadPokemonInformation() {
        guard let url = URL(string: url) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let `self` = self,
                  let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(PokemonResult.self, from: data)

                DispatchQueue.main.async {
                    self.pokemonResult = result

                    // UI updates after fetching the pokemon response
                    self.handlePokemonResponse()
                    
                    // Load the pokemon image after pokemon info finishing loading
                    self.loadPokemonImage()
                }
            }
            catch let error {
                print(error)
            }

        }.resume()

    }

    /// Function to update the UI elements with the pokemon response
    private func handlePokemonResponse() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self,
                  let pokemonResult = self.pokemonResult else {
                return
            }

            self.navigationItem.title = pokemonResult.name.uppercased()
            self.nameLabel.text = pokemonResult.name.uppercased()
            self.indexLabel.text = String(format: "#%03d", pokemonResult.id)
            self.isCaughtTapped = UserDefaults.standard.bool(forKey: pokemonResult.name.uppercased())

            let buttonTitle = self.isCaughtTapped ? "Release" : "Catch"
            self.catchButton.setTitle(buttonTitle, for: .normal)

            self.firstPowerLabel.text = pokemonResult.types.filter({ $0.slot == 1 }).first?.type.name
            self.secondPowerLabel.text = pokemonResult.types.filter({ $0.slot == 2
            }).first?.type.name
        }

        // Load the pokemon details after the loading of the pokemon information is complete
        loadPokemonDetails()
    }

    /// Function to load the pokemon image
    private func loadPokemonImage() {
        guard let pokemonResult = self.pokemonResult,
              let imageURL = URL(string: pokemonResult.sprites.front_default) else {
            return
        }

        pokemonImage.load(url: imageURL)
    }

    /// Function to load the pokemon details
    private func loadPokemonDetails() {
        guard let pokemonResult = self.pokemonResult,
              let descriptionUrl = URL(string: "\(pokemonDetailsURL)\(pokemonResult.id)") else {
            return
        }

        URLSession.shared.dataTask(with: descriptionUrl) { [weak self] (data, response, error) in
            guard let `self` = self,
                  let data = data else {
                return
            }

            do {
                let details = try JSONDecoder().decode(PokemonDetails.self, from: data)
                DispatchQueue.main.async {
                    self.pokemonDetailsResult = details
                    self.handlePokemonDetailsResponse()
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }

    /// Function to update the UI elements with the pokemon details response
    private func handlePokemonDetailsResponse() {
        self.pokemonDetails.text = pokemonDetailsResult?.flavor_text_entries.first?.flavor_text

        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.isHidden = true
        self.contentView.isHidden = false
    }

    /// Function to handle the tapping of the catch button
    @IBAction func toggleCatch() {
        let catchButtonTitle = isCaughtTapped ? "Catch" : "Release"
        isCaughtTapped = isCaughtTapped ? false : true

        catchButton.setTitle(catchButtonTitle, for: .normal)

        // Store the value of the caught flag with the key of the name of the pokemon
        if let nameLabelText = nameLabel.text {
            UserDefaults.standard.set(isCaughtTapped, forKey: nameLabelText)
        }
    }
}

extension UIImageView {
    /// Function to load the image view with an image from a URL
    /// - Parameters:
    ///   - url: the URL that will be used to fetch the image from and load it to the image view
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
