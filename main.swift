#!/usr/bin/env xcrun swift -F ./Rome/ -framework Swiftline -framework Commander -framework CSwiftV

import Foundation
import Swiftline
import Commander
import CSwiftV

/*
Example:

./main.swift ./world.csv Ordino
Searching Population of Ordino in ./world.csv
The population of Ordino, AD is 2553

*/

struct Row {
    let country: String
    let city: String
    let accent_city: String
    let region: String
    
    // Not every row has data for the population, latitude or longitude!
    // So we express them as `Option` types, which admits the possibility of
    // absence. The CSV parser will fill in the correct value for us.
    let population: Int?
    let latitude: Int?
    let longitude: Int?
    
    // Country,City,AccentCity,Region,Population,Latitude,Longitude
    init?(row: [String]) {
        guard row.count == 7 else {
            self.country = ""
            self.city = ""
            self.accent_city = ""
            self.region = ""
            self.population = nil
            self.latitude = nil
            self.longitude = nil
            return nil
        }
        
        self.country = row[0]
        self.city = row[1]
        self.accent_city = row[2]
        self.region = row[3]
        
        if let population = Int(row[4]) {
            self.population = population
        } else {
            self.population = nil
        }
        if let latitude = Int(row[5]) {
            self.latitude = latitude
        } else {
            self.latitude = nil
        }
        if let longitude = Int(row[6]) {
            self.longitude = longitude
        } else {
            self.longitude = nil
        }
    }
}

struct PopulationCount {
    let city: String
    let country: String
    // This is no longer an `Option` because values of this type are only
    // constructed if they have a population count.
    let count: Int
}

enum CliError: ErrorType {
    case IO
    case CSV
    case NotFound
}

func search(atPath path: NSURL, city: String) throws -> Array<PopulationCount> {
    
    let content: String
    do {
        content = try String(contentsOfURL: path)
    } catch {
        throw CliError.IO
    }
    
    let csv = CSwiftV(String: content) // this could fail but the lib doesn't throw.

    var found: Array<PopulationCount> = []
    
    for r in csv.rows {
        guard let row = Row(row: r) else {
            throw CliError.CSV
        }
        
        switch row.population {
        case .Some(let population) where row.city == city:
            found.append(
                PopulationCount(
                    city: row.city,
                    country: row.country,
                    count: population
                )
            )
        case .None, .Some: break // Skip it
        }
    }
    
    if found.isEmpty {
        throw CliError.NotFound
    }
    
    return found
}

let main = command { (file: String, city: String) in
    print("Searching Population of \(city) in \(file)...".f.Green)
    
    let path = NSURL(fileURLWithPath: file)

    do {
        let found = try search(atPath: path, city: city.lowercaseString)
        for pop in found {
            print("The population of \(city), \(pop.country.uppercaseString) is \(pop.count).".f.Blue)
        }
    } catch CliError.NotFound {
        print("\(city) population not found")
    } catch let error {
        fatalError(String(error))
    }
}

main.run()
