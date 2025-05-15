import UIKit
import PictureBookLendingCore
import PictureBookLendingAdmin

class AdminViewController: UIViewController {
    private let bookManagementService = BookManagementService()
    
    private let tableView = UITableView()
    private var books: [Book] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "管理アプリ"
        view.backgroundColor = .white
        
        setupTableView()
        
        let book1 = bookManagementService.addBook(
            title: "はらぺこあおむし",
            author: "エリック・カール",
            isbn: "978-4033280103",
            publishedYear: 1976
        )
        
        let book2 = bookManagementService.addBook(
            title: "ぐりとぐら",
            author: "中川李枝子",
            isbn: "978-4834000825",
            publishedYear: 1967
        )
        
        books = [book1, book2]
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BookCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension AdminViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath)
        let book = books[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = book.title
        content.secondaryText = book.author
        cell.contentConfiguration = content
        
        return cell
    }
}
