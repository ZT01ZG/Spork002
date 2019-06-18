//
//  ContentView.swift
//  Spork002_CupcakeCorner
//
//  Created by Zach on 6/18/19.
//  Copyright © 2019 RogueSpork. All rights reserved.
//
import Combine
import SwiftUI

class Order: BindableObject, Codable {

    enum CodingKeys: String, CodingKey {
        case type, quantity, extraFrosting, addSprinkles, name, address, city, zip
    }

    var didChange = PassthroughSubject<Void, Never>()

    static let types = ["Vanilla", "Chocolate", "Strawberry", "Rainbow"]

    var type = 0 { didSet { update() }}
    var quantity = 3 { didSet { update() }}

    var specialRequestsEnabled = false { didSet { update() }}

    var extraFrosting = false { didSet { update() }}
    var addSprinkles = false { didSet { update() }}

    var name = "" { didSet { update() }}
    var address = "" { didSet { update() }}
    var city = "" { didSet { update() }}
    var zip = "" { didSet { update() }}

    var isValid: Bool {
        if name.isEmpty || address.isEmpty || city.isEmpty || zip.isEmpty {
            return false
        }
        return true
    }


    func update() {
        didChange.send(())
    }
}

struct ContentView : View {

    @ObjectBinding var order = Order()

    @State var confirmationMessage = ""
    @State var showingConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $order.type, label: Text("Select your type of ice cream...")) {
                        ForEach(0 ..< Order.types.count) {
                            Text(Order.types[$0]).tag($0)
                        }
                    }
                    Stepper(value: $order.quantity, in: 3...20) {
                        Text("Number of cakes: \(order.quantity)")
                    }
                }

                Section {
                    Toggle(isOn: $order.specialRequestsEnabled) {
                        Text("Any special requests...")
                    }
                    if order.specialRequestsEnabled {
                        Toggle(isOn: $order.extraFrosting) {
                            Text("Add extra frosting...")
                        }
                        Toggle(isOn: $order.addSprinkles) {
                            Text("Add sprinkles...")
                        }
                    }

                }

                Section {
                    TextField($order.name, placeholder: Text("Name"))
                    TextField($order.address, placeholder: Text("Address"))
                    TextField($order.city, placeholder: Text("City"))
                    TextField($order.zip, placeholder: Text("Zip"))
                }

                Section {
                    Button(action: {
                        self.placeOrder()
                    }) {
                        Text("Place Order")
                    }.disabled(!order.isValid)
                }
            }
            .navigationBarTitle(Text("Cupcake Corner"))
            .presentation($showingConfirmation) {
                Alert(title: Text("Thank you!"), message: Text(confirmationMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func placeOrder() {

        guard let encoded = try? JSONEncoder().encode(order) else {
            print("Unable to encode the order...")
            return
        }

        let url = URL(string: "https://reqres.in/api/cupcakes")!

        var reuqest = URLRequest(url: url)
        reuqest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        reuqest.httpMethod = "POST"
        reuqest.httpBody = encoded

        URLSession.shared.dataTask(with: reuqest) {
            guard let data = $0 else {
                print("No data in response: \($2?.localizedDescription ?? "Unknown error"). ")
                return
            }
            if let decodedOrder = try? JSONDecoder().decode(Order.self, from: data) {
                self.confirmationMessage = "Your order for \(decodedOrder.quantity)x\(Order.types[decodedOrder.type].lowercased()) cupcakes is on its way!"
                self.showingConfirmation = false
            } else {
                let dataString = String(data: data, encoding: .utf8)
                print("Invalid response: \(data)")
//                let dataString =
//                print("Invalid response: \(data)")
            }
        }.resume()

    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
