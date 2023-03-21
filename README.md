# Basin - Wash N' Dry Made Simple
[![Swift Version badge](https://img.shields.io/badge/Swift-5.1-orange.svg)](https://shields.io/)
[![Platforms description badge](https://img.shields.io/badge/Platforms-iOS|Web|Android-blue.svg)](https://shields.io/)
[![GitHub version](https://badge.fury.io/gh/jcook03266%2FBasin.svg)](https://badge.fury.io/gh/jcook03266%2FBasin)
[![License Badge](https://img.shields.io/github/license/jcook03266/Basin)](https://opensource.org/licenses/MIT)

![Hero Image](Hero.jpg)

## Meet Brookyln's Premiere Laundry Service 👋
Welcome to the only laundromat and dry cleaning service platform that can satisfy Brooklyn's constant hustle and bustle. Whether picking up laundry, dropping it off, or getting it delivered, Basin is here every step of the way 💪

Local Brooklyn laundromats and dry cleaners can finally rejoice because an affordable, modern, and professional solution is now being handcrafted to best suit their needs. And best suit their needs it will because I'm currently working side-by-side with a local multi-location laundromat business to deliver a product that checks off all possible boxes of satisfactory service, nothing less, but much more in store. 

## My Mission 💙
Beyond helping local businesses cater to their modern userbase in order to boost their profit margins, I want to be able to provide jobs for the less fortunate by offering competitive rates for delivery drivers. We all deserve to live decent lives at the end of the day, and most delivery drivers can't do so because one missed tip can make or break their entire day of earnings. Therefore, I want this app to be successful, not only for my own gain, but for the gain of the communities in which it will be utilized in. We have to protect the local communities and enrich them; I don't want a random platform from the UK coming in and not doing NYC justice with proper service, NYC deserves the best possible solution, and this is only possible by someone who lives there. 

## My Goal 🥇
Personally, I don't use laundromats to wash my clothes, so my mission is to make this platform so worth it that even I will consider using it to wash my own clothes. That's the end goal for this product, to inspire people to use it and free up their spare time each and every week by using Basin.

## Proudly Partnered With:
### 🤝 [Stuy Wash N' Dry](https://www.stuywashndryny.com/)

## Q&A:
### What Does Basin Offer?
- Residential & Commercial laundry pick-up/delivery services so that you never have to even look at your dirty clothes.
- Fast & reliable service with a direct communication layer to drivers and laundromats at the press of a button.
- Multiple affordable pricing model for businesses.
- Fair pricing for customers as a result of third-party advertising and revenue from business pricing models.
- Livable wages for delivery personnel regardless of tipping.
- Clean, modern, professional, responsive, and tactile UI that promotes readability and usability for all ages through dynamic content size support.
- Enhanced security through secured backend communication as a result of firebase's user Authentication rules that prevent unauthorized parties from accessing sensitive data.

## What is The Revenue Model For This Platform?
Basin shares a similar revenue model to that of Uber's Ubereats platform in the sense that businesses are charged fixed one-time setup fees, and are structured using a business subscription tier system. Each business tier system delegates a priority level to that business's performance and satisfaction, it is our mission to make the higher tier businesses as profitable as possible through diverse and aggressive advertising and algorithmic weighting in search results. Ultimately, the higher the tier of the business' subscription the more we split their total revenue from orders. Each business subscription tier is enumerated below:

- **Basic Bucket: `(Low Priority) 💧`**
  - 20% Fee on the subtotal (pre-tax and fees) for delivery orders
  - 12% Fee on the subtotal for pickup orders

- **Wash Basin: `(Medium Priority) 💦`**
  - 22% Fee on the subtotal for delivery orders 
  - 15% Fee on the subtotal for pickup orders

- **Washing Machine: `(High Priority) 🌊`**
  - 25% Fee on the subtotal for delivery orders
  - 18% Fee on the subtotal for pickup orders

> Note: Total order profit is the amount of money after taxes, service fees, and delivery fees, that have been deducted from the payment entity record. It is essentially the subtotal of the order.

### Notable Libraries and Frameworks Used:
- **Firebase 🔥** (Cloud, Auth, Core, Storage, Store, Analytics, AdMob) | (Front-end / Backend) -> Backend API, File Storage, Database, Analytics, Advertisements
- **Google Maps 🗺** | (Front-end) -> User Navigation
- **Stripe 💳** | (Front-end / Backend) -> Payment Processing
- **Nuke 🏙** | (Front-end) -> Image loading and caching
- **Lottie iOS ⌛️** | (Front-end) -> After Effects JSON Animations
- **Google Places 🏠** | (Backend) -> Geocoding and Reverse Geocoding
- **PhoneNumberKit 📞** | (Front-end) -> Parse phone numbers into objects on the fly
- **IQKeyboardManager ⌨️** | (Front-end) -> Allows the UI to be dynamically centered around textfields to prevent blockage by the keyboard
- **FBSDKLoginKit & Google Sign In 🔐** | (Front-end / Backend) -> Authenticate a user with facebook or google, connects with firebase

> Note: All libraries and frameworks are made possible through [CocoaPods](https://cocoapods.org/)

### How is this App Structured?
- #### Basin is structured around 3 authorized user bases:
  - Customers 🙋‍♂️ (Remote / Transient Clients)
  - Delivery Drivers 🚘 (Transient Clients)
  - Business Employees 👨‍💻 (Point of Sale Clients) 

- Customers and Delivery driver users are considered transients meaning they operate in one location for short periods of time, they're on the move and should be treated as such. The Business clients are considered fixed, their data propagation and UI reflect this fixed nature, their UI doesn't operate around movement, rather confirming orders, updating received orders to provide customers with real-time data, and marking orders for delivery.

  - The app supports 3 of the enumerated user types, but outside of this the platform's backend architecture is structured around 5 user types, with business administrator being 1, and developer being the last and highest level. Business administrators are above employees, they are the owners of the laundromats and or trusted high-level associates that require access to all of the business's data. Administrators can create each physical location and supply it with descriptive metadata, and if not desired an engineer can go out to the location to take photos and gather other important information about the site to create an online entity representing it. 

- These two extraneous user types are only permissible on the website [Basin.io](https://www.basin.io). The web app allows for all data-sensitive operations to be carried out in a clean, high fidelity, professional, and secure environment. The employees of said business can also use the website, with the only exception being delivery drivers and customers who are locked to the mobile application for now due to the complexity of implementation.

## How can I use Basin? 
The iOS version of the app is currently being developed as we speak, but when the customer portion of the app is relatively complete (>= 90%) then I will upload the application to testflight and allow users to download and experience Basin. Current development is blazing fast, it's really only limited by my ability to type fast and stay awake at this point, so realistically, I expect the app to be on testflight very soon. And above all, thanks for your patience.

## Demos:
### Startup - FTUE
https://user-images.githubusercontent.com/63657230/226747035-3e62c235-5cd5-4532-8b0f-b819b61c4692.mp4

### Startup - Logged In
https://user-images.githubusercontent.com/63657230/226746490-2e2ffb2d-13db-4755-b6de-9119e6576569.mov

### Signup - Part I
https://user-images.githubusercontent.com/63657230/226752008-86e87b18-d755-4f6b-9dd4-1bd6bb5dd745.mp4

### Signup - Part II
https://user-images.githubusercontent.com/63657230/226752593-7c7b12a6-0755-4c23-bdab-0642d3796589.mp4

### Signup - Part III
https://user-images.githubusercontent.com/63657230/226753034-331db107-1bab-4803-a99b-e9a1f3c5dee4.mp4

### Forgot/Reset Password
https://user-images.githubusercontent.com/63657230/226752654-63f9a61e-3c1b-4d9d-a473-3bc2d2e5d15a.mp4

### Home Tab
https://user-images.githubusercontent.com/63657230/226753732-4f6680b2-066d-4545-95e4-adf459b397c2.mp4

### Detail View
https://user-images.githubusercontent.com/63657230/226753266-9c8ef615-b9c3-4162-956d-98ffc87776e5.mp4

### Cart View
https://user-images.githubusercontent.com/63657230/226753388-9c2d2ae9-a18b-4e2d-8e5a-7286a7fe41bb.mp4

## Contributions:
Open source contributions are not allowed at this time, this application contains sensitive information at the moment and shouldn't be exposed to unauthorized parties. Reproduction of source materials is allowed via the MIT license, but only to those marked as authorized viewers and contributors to this project.

## License:
MIT License

Copyright © 2022 Justin Cook
