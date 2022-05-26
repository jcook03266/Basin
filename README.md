# Basin - Wash N' Dry
[![Generic badge](https://img.shields.io/badge/Swift-5.1-orange.svg)](https://shields.io/)
[![Generic badge](https://img.shields.io/badge/Platforms-iOS|Web|Android-blue.svg)](https://shields.io/)
[![GitHub version](https://badge.fury.io/gh/jcook03266%2FBasin.svg)](https://badge.fury.io/gh/jcook03266%2FBasin)

![gif](Hero.jpg)

## Meet Brookyln's Premiere Laundry Service

Welcome to the only laundromat and dry cleaning service platform that can satisfy Brooklyn's constant hustle and bustle. Whether picking up laundry, dropping it off, or getting it delivered, Basin is here every step of the way 💪

## Proudly Partnered With:
### [Stuy Wash N' Dry](https://www.stuywashndryny.com/)

## Q&A:
### What Does Basin Offer?
- Residental & Commercial laundry pick-up/delivery services so that you never have to even look at your dirty clothes.
- Fast & reliable service with a direct communication layer to drivers and laundromats at the press of a button.
- Multiple affordable pricing model for businesses.
- Fair pricing for customers as a result of third-party advertising and revenue from business pricing models.
- Livable wages for delivery personnel regardless of tipping.
- Clean, modern, professional, responsive, and tactile UI that promotes readability and usability for all ages through dynamic content size support.
- Enhanced security through secured backend communication as a result of firebase's user Authentication rules that prevent unauthorized parties from accessing sensitive data.

### Notable Libraries and Frameworks:
- **Firebase** (Cloud, Auth, Core, Storage, Store, Analytics, AdMob) | (Front-end / Backend) -> Backend API, File Storage, Database, Analytics, Advertisements
- **Google Maps** | (Front-end) -> User Navigation
- **Stripe** | (Front-end / Backend) -> Payment Processing
- **Nuke** | (Front-end) -> Image loading and caching
- **Lottie iOS** | (Front-end) -> After Effects JSON Animations
- **Google Places** | (Backend) -> Geocoding and Reverse Geocoding
- **PhoneNumberKit** | (Front-end) -> Parse phone numbers into objects on the fly
- **IQKeyboardManager** | (Front-end) -> Allows the UI to be dynamically centered around textfields to prevent blockage by the keyboard
- **FBSDKLoginKit & Google Sign In** | (Front-end / Backend) -> Authenticate a user with facebook or google, connects with firebase

**Note:** All libraries and frameworks are made possible through [CocoaPods](https://cocoapods.org/)

### How is this App Structured?
- #### Basin is structured around 3 authorized user bases:
  - Customers (Remote / Transient Clients)
  - Delivery Drivers (Transient Clients)
  - Business Employees (Point of Sale Clients) 

Customers and Delivery driver users are considered transients meaning they operate in one location for short periods of time, they're on the move and should be treated as such. The Business clients are considered fixed, their data propagation and UI reflect this fixed nature, their UI doesn't operate around movement, rather confirming orders, updating received orders to provide customers with real-time data, and marking orders for delivery.

The app supports 3 of the enumerated user types, but outside of this the platform's backend architecture is structured around 5 user types, with business administrator being 1, and developer being the last and highest level. Business administrators are above employees, they are the owners of the laundromats and or trusted high-level associates that require access to all of the business's data. Administrators can create each physical location and supply it with descriptive metadata, and if not desired an engineer can go out to the location to take photos and gather other important information about the site to create an online entity representing it. 

These two extraneous user types are only permissible on the website [Basin.io](https://www.basin.io). The web app allows for all data-sensitive operations to be carried out in a clean, high fidelity, professional, and secure environment. The employees of said business can also use the website, with the only exception being delivery drivers and customers who are locked to the mobile application for now due to the complexity of implementation.

## Contributions:
Open source contributions are not allowed at this time, this application contains sensitive information at the moment and shouldn't be exposed to unauthorized parties. Reproduction of source materials is allowed via the MIT license, but only to those marked as authorized viewers and contributors to this project.

## License:

