//
//  WeatherCollectionViewCell.swift
//  WeatherApp
//
//  Created by Rohit Jangid on 03/02/21.
//

import UIKit

class WeatherCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dayAndTimeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    
    
    /// Updating collection view cell with date, time, temperature and image
    /// - Parameters:
    ///   - dateTime: date and time info according to the hourly or daily weather request
    ///   - temp: temperature for hourly or daily weather request
    ///   - image: weather icon for hourly or daily weather request
    func updateWeather(dateTime: String, temp: String, image: UIImage?) {
        dayAndTimeLabel.text = dateTime
        temperatureLabel.text = temp
        weatherImage.image = image
    }
    
}
