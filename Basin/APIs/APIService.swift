//
//  APIService.swift
//  Basin
//
//  Created by Justin Cook on 5/6/22.
//
import Foundation

/** Singleton class responsible for fetching and decoding JSON data into structured data usable by this platform*/
let apiService = APIService.shared

class APIService{
    /** Shared singleton that can handle large network intensive tasks*/
    static let shared = APIService()
    
    /** Enum that simplifies error passing for this class*/
    enum APIError: Error{
        case error(_ errorString: String)
    }
    
    /** Specify the type of API to fetch and decode data from*/
    enum APIType: Int{
        case openWeatherAPI = 0
        case googleGeocodingAPI = 1
    }
    
    func getJSON(urlString: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, APIType: APIType, completion: @escaping (Result<Any,APIError>) -> Void){
        
        guard let url = URL(string: urlString) else{
            completion(.failure(.error(NSLocalizedString("Error: Invalid URL in JSON fetch request", comment: ""))))
            return
        }
        
        /** Get the JSON data from the url and decode it into a current weather struct*/
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let error = error {
                completion(.failure(.error("Error: \(error.localizedDescription)")))
            }
            
            guard let data = data else{
                completion(.failure(.error(NSLocalizedString("Error: Data is corrupt", comment: ""))))
                return
            }
            
            /** Attempt to decode the data into a current weather struct*/
            let decoder = JSONDecoder()
            /** Set the decoding strategies for the JSON decoder when decoding to these specific types*/
            decoder.dateDecodingStrategy = dateDecodingStrategy
            decoder.keyDecodingStrategy = keyDecodingStrategy
            
            switch APIType {
            case .openWeatherAPI:
                do{
                    let decodedData = try decoder.decode(CurrentWeather.self, from: data)
                    completion(.success(decodedData))
                    return
                }catch let decodingError{
                    completion(.failure(APIError.error("Error: \(decodingError.localizedDescription)")))
                    return
                }
            case .googleGeocodingAPI:
                do{
                    let decodedData = try decoder.decode(GeocodedLocation.self, from: data)
                    completion(.success(decodedData))
                    return
                }catch let decodingError{
                    completion(.failure(APIError.error("Error: \(decodingError.localizedDescription)")))
                    return
                }
            }
        }.resume() ///Start the task
    }
}
