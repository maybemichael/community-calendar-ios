//
//  EventController.swift
//  Community Calendar
//
//  Created by Jordan Christensen on 1/9/20.
//  Copyright © 2020 Mazjap Co. All rights reserved.
//

import Foundation
import Apollo
// Run this command in terminal to generate an updated schema.json:
// apollo schema:download --endpoint=https://ccstaging.herokuapp.com/schema.graphql schema.json
class EventController {
    let cache = Cache<String, UIImage>()
    private let graphQLClient = ApolloClient(url: URL(string: "https://ccstaging.herokuapp.com/graphql")!)
    
    func getEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        graphQLClient.fetch(query: GetEventsQuery()) { result in
            switch result {
            case .failure(let error):
                NSLog("\(#file):L\(#line): Error fetching events inside \(#function) with error: \(error)")
                completion(.failure(error))
            case .success(let graphQLResult):
                guard let data = graphQLResult.data?.events else { return }
                
                var events = [Event]()
                for event in data {
                    events.append(Event(event: event))
                }
                let sortedEvents = events.sorted { a, b -> Bool in
                    if let aStartDate = a.startDate, let bStartDate = b.startDate {
                        return aStartDate < bStartDate
                    } else {
                        return a.title.lowercased() < b.title.lowercased()
                    }
                }
                completion(.success(sortedEvents))
            }
        }
    }
    
    func loadImage(for key: String) {
        if let image = cache.fetch(key: key) {
            NotificationCenter.default.post(name: .imageWasLoaded, object: ImageNotification(image: image, url: key))
            return
        }
        
        let imageURL = URL(string: key)!
        URLSession.shared.dataTask(with: imageURL) { (data, _, error) in
            if let error = error {
                NSLog("\(#file):L\(#line): Unable to fetch image data inside \(#function) with error: \(error)")
                return
            }
            
            guard let data = data else {
                NSLog("\(#file):L\(#line): No data returned while trying to fetch image data inside \(#function)")
                return
            }
            
            if let image = UIImage(data: data) {
                self.cache.imageDict[key] = image
                NotificationCenter.default.post(name: .imageWasLoaded, object: ImageNotification(image: image, url: key))
            }
        }.resume()
    }
}