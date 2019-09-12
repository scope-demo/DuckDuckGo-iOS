//
//  PrivacyProtectionPracticesController.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Core

typealias CookieInfo = HTTPCookie

class PrivacyDashboardCookiesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    private var siteRating: SiteRating!
    private var contentBlockerConfiguration = AppDependencyProvider.shared.storageCache.current.configuration

    private var loginCookies: [CookieInfo] = []
    private var otherCookies: [CookieInfo] = []

    override func viewDidLoad() {
 //       Pixel.fire(pixel: .privacyDashboardPrivacyPractices)
        initTable()
        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        update()
    }

    @IBAction func onBack() {
        navigationController?.popViewController(animated: true)
    }

    func update() {
        guard isViewLoaded else { return }
        updateCookieCount()
        updateImageIcon()
        updateDomainLabel()
    }

    private func updateCookieCount() {
        loginCookies = []
        otherCookies = []

        WebCacheManager.cookies(for: siteRating.url) { cookies in
            cookies.forEach { cookie in
                if cookie.name.contains("login") || cookie.name.contains("session") {
                    self.loginCookies.append(cookie)
                } else {
                    self.otherCookies.append(cookie)
                }
            }
            self.subtitleLabel.text = "\(self.loginCookies.count + self.otherCookies.count) COOKIES"
            self.tableView.reloadData()
        }

    }

    private func updateImageIcon() {

    }

    private func updateDomainLabel() {
        domainLabel.text = siteRating.domain
    }

    private func initTable() {
        tableView.dataSource = self
        tableView.delegate = self
    }

}

extension PrivacyDashboardCookiesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, section == 0 ? loginCookies.count : otherCookies.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cookies = indexPath.section == 0 ? loginCookies : otherCookies
        return cookieCell(at: indexPath.row, from: cookies)
    }

    func cookieCell(at row: Int, from cookies: [CookieInfo]) -> UITableViewCell {

        if cookies.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "NoCookies")!
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CookieDetail") as? CookieDetailCell else {
                fatalError("Unable to dequeue \(CookieDetailCell.self)")
            }
            cell.update(cookies[row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Login Cookies" : "Other Cookies"
    }

}

extension PrivacyDashboardCookiesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cookies = indexPath.section == 0 ? loginCookies : otherCookies
        let cookie = cookies[indexPath.row]
        let protected = WebCacheManager.isProtected(cookie: cookie)
        WebCacheManager.setProtected(cookie: cookie, !protected)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

}

extension PrivacyDashboardCookiesViewController: PrivacyProtectionInfoDisplaying {

    func using(siteRating: SiteRating, configuration: ContentBlockerConfigurationStore) {
        self.siteRating = siteRating
        self.contentBlockerConfiguration = configuration
        update()
    }

}

class CookieDetailCell: UITableViewCell {

    @IBOutlet weak var stateImageView: UIImageView!
    @IBOutlet weak var nameValueLabel: UILabel!
    @IBOutlet weak var expiresLabel: UILabel!

    func update(_ cookieInfo: CookieInfo) {
        nameValueLabel?.text = "\(cookieInfo.name): \(cookieInfo.value)"
        expiresLabel?.isHidden = cookieInfo.expiresDate == nil
        if let expires = cookieInfo.expiresDate {
            expiresLabel?.text = "Expires: \(expires)"
        }

        stateImageView?.image = WebCacheManager.isProtected(cookie: cookieInfo) ?
            UIImage(named: "PP Icon Connection Bad") :
            UIImage(named: "Fire")
    }

}
