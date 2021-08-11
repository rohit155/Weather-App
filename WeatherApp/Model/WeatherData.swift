//
//  WeatherData.swift
//  WeatherApp
//
//  Created by Rohit Jangid on 29/01/21.
//

import Foundation

struct WeatherData: Codable {
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
}

/// current weather data
struct CurrentWeather: Codable {
    let dt: Double
    let sunrise: Double
    let sunset: Double
    let temp: Double
    let feels_like: Double
    let weather: [Weather]
}

/// Hourly weather
struct HourlyWeather: Codable {
    let dt: Double
    let temp: Double
    let weather: [Weather]
}

/// Daily weather
struct DailyWeather: Codable {
    let dt: Double
    let temp: Temperature
    let weather: [Weather]
}
/// temperature for daily weather
struct Temperature: Codable {
    let day: Double
}

/// weather data -> description and icon
struct Weather: Codable {
    let description: String
    let icon: String
}
