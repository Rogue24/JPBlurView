//
//  ViewController.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Examples"
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = indexPath.row == 0 ? "Custom Blur" : "Interactive & Animable Blur"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = indexPath.row == 0 ?
            storyboard!.instantiateViewController(withIdentifier: "CustomBlurViewController") :
            WaterfallViewController()
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
