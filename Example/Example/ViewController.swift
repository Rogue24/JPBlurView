//
//  ViewController.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

enum Example: Int, CaseIterable {
    case customBlur
    case customBlurList
    case interactiveBlur
    
    var title: String {
        switch self {
        case .customBlur:
            return "Custom Blur"
        case .customBlurList:
            return "Custom Blur List"
        case .interactiveBlur:
            return "Interactive & Animable Blur"
        }
    }
    
    var vc: UIViewController {
        switch self {
        case .customBlur:
            return UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "CustomBlurViewController")
        case .customBlurList:
            return CustomBlurListViewController()
        case .interactiveBlur:
            return WaterfallViewController()
        }
    }
}

class ViewController: UIViewController {
    let examples = Example.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Examples"
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        examples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = examples[indexPath.row].title
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(examples[indexPath.row].vc, animated: true)
    }
}
