//
//  ViewController.swift
//  BaiduMap-Practice
//
//  Created by Popeye Lau on 16/7/15.
//  Copyright © 2016年 Popeye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	var mapView: BMKMapView!
	var locationService: BMKLocationService!
	var userLocation: CLLocationCoordinate2D?
	var showRegion = true

	override func viewDidLoad() {
		super.viewDidLoad()
		mapView = BMKMapView(frame: view.bounds)
		view.addSubview(mapView)

		// 定位服务
		locationService = BMKLocationService()
		locationService.delegate = self
		locationService.startUserLocationService()

      

		// 比例尺
		mapView.showMapScaleBar = true
		// 显示当前位置
		mapView.showsUserLocation = true

		// 添加SearchBar
		let screenWidht = UIScreen.mainScreen().bounds.size.width
		let searchBar = UISearchBar(frame: CGRectMake(0, 0, screenWidht, 45))
		searchBar.delegate = self
		navigationItem.titleView = searchBar
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		mapView.viewWillAppear()
		mapView.delegate = self
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		mapView.viewWillDisappear()
		mapView.delegate = nil
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func addAnnotation(poiInfo: BMKPoiInfo) {
        //添加锚点
		let pt = poiInfo.pt
		let annotation = BMKPointAnnotation()
		annotation.coordinate = pt
		annotation.title = poiInfo.name
		annotation.subtitle = poiInfo.address
		mapView.addAnnotation(annotation)
		showRegion = false

		guard let currentPt = userLocation else {
			return
		}

		let regionX = currentPt.latitude - pt.latitude > 0 ? currentPt.latitude - pt.latitude: -currentPt.latitude + pt.latitude
		let regionY = currentPt.longitude - pt.longitude > 0 ? currentPt.longitude - pt.longitude: -currentPt.longitude + pt.longitude
		let region = max(regionX, regionY) * 2
		let viewRegion = BMKCoordinateRegionMake(currentPt, BMKCoordinateSpanMake(region, region))
		mapView.setRegion(mapView.regionThatFits(viewRegion), animated: true)

		// 画线
		drawLine([currentPt,pt])
	}

    func drawLine(points:[CLLocationCoordinate2D]) {
		let line = BMKPolyline(coordinates: UnsafeMutablePointer(points), count: UInt(points.count), textureIndex: [1])
		mapView.addOverlay(line)
	}

}

// MARK: - BMKMapViewDelegate
extension ViewController: BMKMapViewDelegate {
	// 锚点点击
	func mapView(mapView: BMKMapView!, didSelectAnnotationView view: BMKAnnotationView!) {
		// 删除锚点
		// mapView.removeAnnotation(view.annotation)

	}

	// 添加折线
	func mapView(mapView: BMKMapView!, viewForOverlay overlay: BMKOverlay!) -> BMKOverlayView! {
		if !overlay.isKindOfClass(BMKPolyline.self) {
			return nil
		}

		let lineView = BMKPolylineView(overlay: overlay)
		lineView.lineWidth = 5
		lineView.isFocus = true
		lineView.colors = [UIColor.redColor(), UIColor.orangeColor()]
		return lineView
	}
}

// MARK: - BMKLocationServiceDelegate
extension ViewController: BMKLocationServiceDelegate {
	func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
		mapView.updateLocationData(userLocation)
		self.userLocation = userLocation.location.coordinate

		// 设定当前地图的显示范围
		if showRegion {
			let viewRegion = BMKCoordinateRegionMake(userLocation.location.coordinate, BMKCoordinateSpanMake(0.03, 0.03))
			let ajustRegion = mapView.regionThatFits(viewRegion)
			mapView.setRegion(ajustRegion, animated: true)
		}
	}
}
// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
	func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
		guard let location = self.userLocation else {
			return false
		}

		let vc = SearchViewController(location: location)
		vc.callBack = { [weak self] poiInfo in
			self?.addAnnotation(poiInfo)
		}
		navigationController?.pushViewController(vc, animated: true)
		return false
	}
}

