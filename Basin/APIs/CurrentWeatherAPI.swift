//
//  CurrentWeatherAPI.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 3/28/22.
//

import UIKit
import GoogleMaps
import Nuke

/** File that contains a singleton class for JSON fetching and decoding and structs for weather data using Open Weather's API*/

/** API key to pass when fetching JSON data*/
let openWeatherAPIKey = "43f330b80fec92f73843a6e979b15a81"

/** Send an API call to retrieve the current weather data for the given coordinate point*/
func getCurrentWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (Result<CurrentWeather,APIService.APIError>) -> Void){
    
    /** The URL String for the API call*/
    let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(openWeatherAPIKey)"
    
    /** API Service to fetch the data and decode it into a usable object*/
    apiService.getJSON(urlString: urlString, dateDecodingStrategy: .secondsSince1970, keyDecodingStrategy: .useDefaultKeys, APIType: .openWeatherAPI){ (result: Result<Any,APIService.APIError>) in
        
        switch result{
        case .success(let success):
            guard let currentWeather = success as? CurrentWeather else{
                return
            }
            completion(.success(currentWeather))
        case .failure(let failure):
            completion(.failure(failure))
        }
        
        /** How to handle the result
         switch result {
         case .success(let currentWeather):
         print("\(currentWeather.main) \(currentWeather.dt)")
         case .failure(let apiError):
         switch apiError{
         case .error(let errorString):
         print(errorString)
         }
         }
         */
    }
}

/** Temperature conversion methods*/
func convertFromKelvinToFahrenheit(k: Double)->Double?{
    return (((k - 273.15) * (9/5)) + 32)
}
func convertFromKelvinToCelsius(k: Double)->Double?{
    return (k - 273.15)
}
func convertFromCelsiusToKelvin(c: Double)->Double{
    return (c + 273.15)
}
func convertFromFahrenheitToKelvin(f: Double)->Double{
    return (((f - 32) * (5/9)) + 273.15)
}
func convertFromCelsiusToFahrenheit(c: Double)->Double{
    return ((c * (9/5)) + 32)
}
func convertFromFahrenheitToCelsius(f: Double)->Double{
    return ((f - 32)*(5/9))
}
/** Temperature conversion methods*/

/** Enum that specifies a temperature unit*/
public enum TemperatureUnit: String{
    case kelvin = "K"
    case fahrenheit = "F"
    case celsius = "C"
}

/** A uiview subclass that displays weather data in a compact and readable format*/
public class minimalWeatherView: UIView{
    /** The weather icon to display*/
    var weatherIcon: URL?{
        didSet{
            if weatherIcon != nil{
                DispatchQueue.main.async{[self] in
                    /** Load the weather icon into the imagview using Nuke*/
                    let request = ImageRequest(url: weatherIcon)
                    let options = ImageLoadingOptions(
                        transition: .fadeIn(duration: 0.5)
                    )
                    
                    Nuke.loadImage(with: request, options: options, into: imageView){ [self] _ in
                        UIView.animate(withDuration: 0.5, delay: 0){
                            self.imageView.alpha = 1
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async{[self] in
                    /** Remove the imageview if the given icon is nil*/
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.imageView.alpha = 0
                    }
                }
            }
        }
    }
    /** The temperature string to display next to the weather icon*/
    var temperature: Double?{
        didSet{
            if temperature != nil{
                /** Update only from the main thread*/
                DispatchQueue.main.async{[self] in
                    var temperatureUnitString = TemperatureUnit.fahrenheit.rawValue
                    if temperatureUnit != nil{
                        temperatureUnitString = temperatureUnit!.rawValue
                    }
                    
                    label.text = "\((String(format: "%.0f", temperature!))) °\(temperatureUnitString)"
                    
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.label.alpha = 1
                    }
                }
            }
            else{
                DispatchQueue.main.async{[self] in
                    /** Remove the label if the given text is nil*/
                    UIView.animate(withDuration: 0.5, delay: 0){
                        self.label.alpha = 0
                    }
                }
            }
        }
    }
    /** The unit to add to the end of the temperature string*/
    var temperatureUnit: TemperatureUnit?{
        didSet{
            if temperatureUnit != nil{
                let temperatureUnitString = temperatureUnit!.rawValue
                
                if temperature != nil{
                    label.text = "\((String(format: "%.0f", temperature!))) °\(temperatureUnitString)"
                }
            }
            else{
                let temperatureUnitString = TemperatureUnit.fahrenheit.rawValue
                
                if temperature != nil{
                    label.text = "\((String(format: "%.0f", temperature!))) °\(temperatureUnitString)"
                }
            }
        }
    }
    /** The color to display behind the weather icon*/
    var weatherIconBackgroundColor: UIColor?{
        didSet{
            DispatchQueue.main.async{[self] in
                imageView.backgroundColor = weatherIconBackgroundColor ?? .clear
            }
        }
    }
    
    /** The image view that will display the provided weather icon*/
    fileprivate var imageView = UIImageView()
    /** The padded label that will display the temperature*/
    var label = PaddedLabel(withInsets: 5, 5, 5, 5)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        construct()
    }
    
    /** Empty constructor to initialize the object into memory*/
    init(){
        super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        
        construct()
    }
    
    /** Construct the view using the basic provided properties*/
    private func construct(){
        self.backgroundColor = bgColor
        self.layer.cornerRadius = imageView.frame.height/2
        self.clipsToBounds = true
        
        /** Image view will be a circle with same height and width*/
        imageView.frame.size = CGSize(width: self.frame.height, height: self.frame.height)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.clipsToBounds = true
        /** Wait until the content of this view is given in order to reveal it*/
        imageView.alpha = 0
        
        /** Label fills up any remaining space that isn't used by the imageview*/
        label.frame.size = CGSize(width: (self.frame.height - self.frame.width), height: self.frame.height)
        label.font = getCustomFont(name: .Ubuntu_Regular, size: 16, dynamicSize: true)
        label.backgroundColor = .clear
        label.textColor = fontColor
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.layer.cornerRadius = label.frame.height/2
        label.layer.masksToBounds = true
        /** Wait until the content of this view is given in order to reveal it*/
        label.alpha = 0
        
        /** Layout these subviews*/
        imageView.frame.origin = .zero
        label.frame.origin = CGPoint(x: imageView.frame.maxX, y: 0)
        
        self.addSubview(imageView)
        self.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/** Current weather struct modeled after the expected return format of the JSON data*/
struct CurrentWeather: Codable{
    /** Date of this weather forecast*/
    let dt: Date
    
    struct Main: Codable{
        /** Current temperature*/
        let temp: Double
    }
    let main: Main
    
    /** The weather and its description*/
    struct Weather: Codable{
        let id: Int
        let description: String
        let icon: String
        /*** The image URL resource icon for the */
        var weatherIconURL: URL?{
            let urlString = "https://openweathermap.org/img/wn/\(icon)@2x.png"
            return URL(string: urlString)
        }
    }
    /** Array of weather objects*/
    let weather: [Weather]
}
