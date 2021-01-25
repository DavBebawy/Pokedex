import UIKit

class PokemonListViewController: UITableViewController, UISearchBarDelegate  {
    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!

    // MARK: - Stored properties
    var pokemon: [PokemonListResult] = []
    var pokemonListResult: [PokemonListResult] = []
    var searchText = ""
    private let pokemonListURL = "https://pokeapi.co/api/v2/pokemon?limit=151"

    // MARK: - Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        loadPokemonList()
    }

    // MARK: - Functions
    /// Function to load the list of pokemon items
    private func loadPokemonList() {
        guard let url = URL(string: pokemonListURL) else {
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let `self` = self,
                  let data = data else {
                return
            }

            do {
                let entries = try JSONDecoder().decode(PokemonListResults.self, from: data)
                DispatchQueue.main.async {
                    self.pokemon = entries.results
                    self.tableView.reloadData()
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        
        pokemonListResult.removeAll()

        pokemonListResult = pokemon.filter { $0.name.lowercased().contains(searchText.lowercased()) }

        self.tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPokemonSegue",
           let destination = segue.destination as? PokemonViewController,
           let index = tableView.indexPathForSelectedRow?.row {
            destination.url = searchText.isEmpty ?
                pokemon[index].url :
                pokemonListResult[index].url
        }
    }

    // MARK: - Tableview delegate functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchText.isEmpty ? pokemon.count : pokemonListResult.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PokemonCell", for: indexPath)

        cell.textLabel?.text = self.searchText.isEmpty ?
            pokemon[indexPath.row].name.uppercased() :
            pokemonListResult[indexPath.row].name.uppercased()
        return cell
    }
}
