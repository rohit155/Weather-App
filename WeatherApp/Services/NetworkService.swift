//
//  NetworkService.swift
//  WeatherApp
//
//  Created by Rohit Jangid on 29/01/21.
//

import Foundation
import CoreLocation

class NetworkService {
    static let shared = NetworkService()
    
    let URL_BASE = "https://api.openweathermap.org/data/2.5/onecall?"
    let API_KEY = "YOUR_API_KEY"
    let unitType = "&units=metric"
    let excludeParameter = "&exclude=minutely,alerts"
    
    let session = URLSession(configuration: .default)
    
    /// This function make a GET request and receive a weather data which is decoded to local weather model
    /// - Parameters:
    ///   - longitude: current longitude of the device
    ///   - latitude: current latitude of the device
    ///   - onSuccess: This closure triggers when the network request is successfull and capture weather data
    ///   - onError: This closure triggers when the network request fails and throw an error
    func getWeather(from longitude: CLLocationDegrees, and latitude: CLLocationDegrees, onSuccess: @escaping (WeatherData) -> Void, onError: @escaping (String) -> Void) {
        
        guard let url = URL(string: "\(URL_BASE)lat=\(latitude)&lon=\(longitude)\(unitType)\(excludeParameter)\(API_KEY)") else { return }
        let task = session.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }
                
                guard let data = data, let response = response as? HTTPURLResponse else {
                    onError("Invalid data or response")
                    return
                }
                
                do {
                    if response.statusCode == 200 {
                        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                        onSuccess(weatherData)
                    }
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    /// Make request to fetch weather icon
    /// - Parameters:
    ///   - url: url for the weather icon for current, hourly and daily weather data
    ///   - completion: after the weather icon fetch request returns the data, URLresponse or error
    /// - Returns: resume the the task after the weather request
    func getImageData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    /// Create a specific url for the image to download and pass it to the getImageData function to process
    /// - Parameters:
    ///   - urlImage: name of the weather icon to download and to append it in the url
    ///   - imageData: On successfull weather data fetch request this closure makes it available to use
    func downloadImage(from urlImage: String, imageData: @escaping (Data) -> Void) {
        guard let url = URL(string: "https://openweathermap.org/img/wn/\(urlImage)@2x.png") else { return }
        
        getImageData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                imageData(data)
            }
        }
    }
    
}
