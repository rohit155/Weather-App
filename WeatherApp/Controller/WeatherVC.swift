//
//  ViewController.swift
//  WeatherApp
//
//  Created by Rohit Jangid on 28/01/21.
//

import UIKit
import CoreLocation

class WeatherVC: UIViewController {
    
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var currentWeatherImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var feelsLikeLabel: UILabel!
    @IBOutlet weak var sunRiseLabel: UILabel!
    @IBOutlet weak var sunRiseImage: UIImageView!
    @IBOutlet weak var sunsetLabel: UILabel!
    @IBOutlet weak var sunsetImage: UIImageView!
    @IBOutlet weak var weatherSegmentControl: UISegmentedControl!
    
    @IBOutlet weak var weatherCollectionView: UICollectionView!
    
    var currentWeatherData: CurrentWeather?
    var hourlyWeatherData = [HourlyWeather]()
    var dailyWeatherData = [DailyWeather]()
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    var imageCacheHourly = [Int: UIImage]()
    var imageCacheDaily = [Int: UIImage]()
    
    var isWeekdayWeather: Bool = false
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        weatherCollectionView.delegate = self
        weatherCollectionView.dataSource = self
        configLocation()
    }
    
    
    /// This function configure location manager and start updating location
    func configLocation() {
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func reloadWeatherBtnTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        updateWeather()
        weatherCollectionView.reloadData()
    }
    
    @IBAction func weatherFormatChangeTapped(_ sender: UISegmentedControl) {
        weatherCollectionView.reloadData()
    }
    
    
    /// This convert date and time received from api in UTC format
    /// - Parameters:
    ///   - fromDate: Date received from api in UTC format
    ///   - withTime: This Bool value indicate weather we need Time or Date
    /// - Returns: Date or time in string format
    func getLocaleDate(fromDate: Double, withTime: Bool) -> String {
        let date = Date(timeIntervalSince1970: fromDate)
        let dateFormatter = DateFormatter()
        if withTime {
            dateFormatter.timeStyle = DateFormatter.Style.short //Set time style
        } else {
            dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        }
        dateFormatter.timeZone = .current
        if isWeekdayWeather {
            dateFormatter.dateFormat = "EE"
        }
        return dateFormatter.string(from: date)
    }
    
    
    /// Used dispatchGroup to download images from the server both for Hourly data and Daily data
    func cacheImage() {
        let group = DispatchGroup()
        
        for (index, data) in hourlyWeatherData.enumerated() {
            group.enter()
            NetworkService.shared.downloadImage(from: data.weather[0].icon) { (data) in
                let image = UIImage(data: data)
                self.imageCacheHourly[index] = image
                group.leave()
            }
        }
        for (index, data) in dailyWeatherData.enumerated() {
            group.enter()
            NetworkService.shared.downloadImage(from: data.weather[0].icon) { (data) in
                let image = UIImage(data: data)
                self.imageCacheDaily[index] = image
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.weatherCollectionView.reloadData()
        }
    }
    
    /// This function make weather request and icons from server asyc and update labels and UIImage
    func updateWeather() {
        NetworkService.shared.getWeather(from: longitude, and: latitude) { [self] (weatherData) in
            currentWeatherData = weatherData.current
            hourlyWeatherData = weatherData.hourly
            dailyWeatherData = weatherData.daily
            hourlyWeatherData.removeSubrange(8...)
            cacheImage()
            
            guard let currentData = currentWeatherData else { return } //unwraping the optional current weather data
            weatherCollectionView.reloadData()
            
            NetworkService.shared.downloadImage(from: currentData.weather[0].icon) { (data) in
                currentWeatherImage.image = UIImage(data: data)
                dataLabel.text = "\(getLocaleDate(fromDate: currentData.dt, withTime: false))"
                temperatureLabel.text = "\(currentData.temp)°"
                weatherDescription.text = "\(currentData.weather[0].description)"
                feelsLikeLabel.text = "Feels like \(currentData.feels_like)°"
                sunRiseLabel.text = "\(getLocaleDate(fromDate: currentData.sunrise, withTime: true))"
                sunsetLabel.text = "\(getLocaleDate(fromDate: currentData.sunset, withTime: true))"
            }
            
            //dismiss alert view for reloading data
            dismiss(animated: false, completion: nil)
        } onError: { (error) in
            debugPrint(error)
        }
        locationManager.stopUpdatingLocation()
    }
}

//MARK: - CLLocationManagerDelegate
extension WeatherVC: CLLocationManagerDelegate {
    
    /// Reverse geocoding the location collected from CLLocation class to get the locality and latitude and longitude
    /// - Parameters:
    ///   - manager: location manager object which generate the update event
    ///   - locations: array of location object with location data
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        longitude = location.coordinate.longitude
        latitude = location.coordinate.latitude
        
        let translateToUserReadable = CLGeocoder()
        
        translateToUserReadable.reverseGeocodeLocation(location) { [self] (placemark: [CLPlacemark]?, error: Error?) in
            if let placemark = placemark {
                cityName.text = placemark.last?.locality ?? "Delhi"
            }
        }
        
        updateWeather()
    }
}

//MARK: - UICollectionViewDelegate
extension WeatherVC: UICollectionViewDelegate {}

//MARK: - UICollectionViewDataSource
extension WeatherVC: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if weatherSegmentControl.selectedSegmentIndex == 0 {
            return hourlyWeatherData.count
        } else {
            return dailyWeatherData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as? WeatherCollectionViewCell else { return UICollectionViewCell() }
        
        /// requesting icon for hourly and daily weather data to update collection view cell's UIImage
        let imageHourly = imageCacheHourly[indexPath.row]
        let imageDaily = imageCacheDaily[indexPath.row]
        let dayAndTime: String
        let temp = "\(dailyWeatherData[indexPath.item].temp.day)°"
        if weatherSegmentControl.selectedSegmentIndex == 0 {
            isWeekdayWeather = false
            dayAndTime = getLocaleDate(fromDate: hourlyWeatherData[indexPath.item].dt, withTime: true)
            cell.updateWeather(dateTime: dayAndTime, temp: temp, image: imageHourly)
        } else {
            isWeekdayWeather = true
            dayAndTime = getLocaleDate(fromDate: dailyWeatherData[indexPath.item].dt, withTime: false)
            cell.updateWeather(dateTime: dayAndTime, temp: temp, image: imageDaily)
        }
        return cell
    }
}
