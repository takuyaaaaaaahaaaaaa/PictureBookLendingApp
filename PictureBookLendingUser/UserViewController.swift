import UIKit
import PictureBookLendingCore
import PictureBookLendingUser

class UserViewController: UIViewController {
    private let bookBrowsingService = BookBrowsingService()
    private let userLendingService = UserLendingService()
    
    private let tableView = UITableView()
    private var books: [Book] = []
    private let userId = UUID()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ユーザーアプリ"
        view.backgroundColor = .white
        
        setupTableView()
        
        books = bookBrowsingService.searchBooks()
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
    
    private func borrowBook(at indexPath: IndexPath) {
        let book = books[indexPath.row]
        let _ = userLendingService.borrowBook(userId: userId, bookId: book.id)
        
        let alert = UIAlertController(
            title: "貸出完了",
            message: "「\(book.title)」を借りました。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UserViewController: UITableViewDataSource, UITableViewDelegate {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        borrowBook(at: indexPath)
    }
}
