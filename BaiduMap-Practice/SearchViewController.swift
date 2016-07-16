//
//  SearchViewController.swift
//  BaiduMap-Practice
//
//  Created by Popeye Lau on 16/7/15.
//  Copyright © 2016年 Popeye. All rights reserved.
//

import UIKit

enum POISearchType: Int {
	case NearBy = 0, City

	func toString() -> String {
		switch self {
		case .NearBy:
			return "附近检索"
		case .City:
			return "城市检索"
		}
	}
}

class SearchViewController: UIViewController {

	var userLocation: CLLocationCoordinate2D!
	var tableView: UITableView!
	let cellIdentifier = "poi_result_cell"
	var resultArray: [BMKPoiInfo] = []
	var callBack: ((BMKPoiInfo) -> Void)?
	var segmentView: UISegmentedControl!
	var searchBar: UISearchBar!
	var poiSearch: BMKPoiSearch!
	var routeSearch: BMKRouteSearch!

	init(location: CLLocationCoordinate2D) {
		super.init(nibName: nil, bundle: nil)
		self.userLocation = location

	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.whiteColor()
		automaticallyAdjustsScrollViewInsets = false

		let screenWidth = UIScreen.mainScreen().bounds.size.width
		let screenHeight = UIScreen.mainScreen().bounds.height
		searchBar = UISearchBar(frame: CGRectMake(0, 0, screenWidth, 44))
		searchBar.delegate = self
		navigationItem.titleView = searchBar
		searchBar.becomeFirstResponder()

		poiSearch = BMKPoiSearch()
		poiSearch.delegate = self

		// 路线搜索
		routeSearch = BMKRouteSearch()
		routeSearch.delegate = self

		let items: [POISearchType] = [.NearBy, .City]
		segmentView = UISegmentedControl(items: items.map { $0.toString() })
		segmentView.frame = CGRectMake(0, 64, screenWidth, 29)
		segmentView.selectedSegmentIndex = 0
		view.addSubview(segmentView)

		tableView = UITableView(frame: CGRectMake(0, CGRectGetMaxY(segmentView.frame), screenWidth, screenHeight - 29), style: .Plain)
		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.tableFooterView = UIView()
		tableView.dataSource = self
		tableView.delegate = self
		view.addSubview(tableView)
	}

	func buildSearchOption() -> Bool {

		let value = segmentView.selectedSegmentIndex
		let type = POISearchType(rawValue: value)!
		let keywords = searchBar.text

		switch type {
		case .NearBy:
			// 附近检索
			let option = BMKNearbySearchOption()
			option.pageIndex = 1
			option.pageCapacity = 20
			option.keyword = keywords
			option.location = userLocation
			return poiSearch.poiSearchNearBy(option)
		case .City:
			// 城市检索
			let option = BMKCitySearchOption()
			option.pageIndex = 1
			option.pageCapacity = 20
			option.city = "深圳市"
			option.keyword = keywords
			return poiSearch.poiSearchInCity(option)
		}
	}

	func routeSearchOption(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
		let driverOption = BMKDrivingRoutePlanOption()

		let from = BMKPlanNode()
		from.pt = startPoint

		let to = BMKPlanNode()
		to.pt = endPoint

		driverOption.from = from
		driverOption.to = to

		routeSearch.drivingSearch(driverOption)
	}
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		view.endEditing(true)
		let flag = buildSearchOption()
		let message = flag ? "发送成功" : "发送失败"
		print(message)
	}
}

// MARK: - BMKPoiSearchDelegate
extension SearchViewController: BMKPoiSearchDelegate {
	func onGetPoiResult(searcher: BMKPoiSearch!, result poiResult: BMKPoiResult!, errorCode: BMKSearchErrorCode) {
		resultArray.removeAll()
		if poiResult != nil {
			let results = poiResult.poiInfoList as! [BMKPoiInfo]
			resultArray.appendContentsOf(results)
		}
		tableView.reloadData()
	}
}
// MARK: - BMKRouteSearchDelegate
extension SearchViewController: BMKRouteSearchDelegate {
	func onGetDrivingRouteResult(searcher: BMKRouteSearch!, result: BMKDrivingRouteResult!, errorCode error: BMKSearchErrorCode) {
        if result == nil {
            return
        }
        let routeLine = result.routes.first as! BMKDrivingRouteLine
        let steps = routeLine.steps as! [BMKRouteStep]
        steps.forEach { (step) in

        }
	}
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return resultArray.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
		let poiInfo = resultArray[indexPath.row]
		cell.textLabel?.text = poiInfo.address
		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let poiInfo = resultArray[indexPath.row]
		 callBack?(poiInfo)
		 navigationController?.popViewControllerAnimated(false)
	}
}