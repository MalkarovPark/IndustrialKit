![IndustiralKit](https://user-images.githubusercontent.com/62340924/206910209-87495b62-2a9b-42c2-b825-85830a1d2623.png)
<!--- (https://user-images.githubusercontent.com/62340924/206910169-3009a0da-eeeb-475b-9983-4a2fffa58f9a.png) -->

# IndustrialKit

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Swift](https://img.shields.io/badge/swift-5.7-brightgreen.svg) ![Xcode 14.1+](https://img.shields.io/badge/Xcode-14.1%2B-blue.svg) ![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue.svg) ![iOS 16.1+](https://img.shields.io/badge/iOS-16.1%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

IndustrialKit is an open source software platform for creating applications that enable the design and control of automated means of production. The framework provides modules that can be used out of the box, or extended and customized for more targeted use cases.

<!--- * **IndustrialKit:** This is the best place to start building your app. CareKit provides view controllers that tie CareKitUI and CareKitStore together. The view controllers leverage Combine to provide synchronization between the store and the views.

* **IndustrialKitUI:** Provides the views used across the framework. The views are subclasses of UIView that are open and extensible. Properties within the views are public allowing for full control over the content.

* **Robotic Complex Workspace:** Provides the views used across the framework. The views are subclasses of UIView that are open and extensible. Properties within the views are public allowing for full control over the content. -->

# Table of Contents
* [Requirements](#requirements)
* [Getting Started](#getting-started)
    * [Robotic Complex Workspace App](#rcworkspace-app)
* [IndustrialKit](#industrialkit)
    * [Workspace Object](#workspace-object)
* [IndustrialKitUI](#industrialkitui)
    * [Cards](#industrialkitui-cards)
    * [Position View](#industrialkitui-positionview)
    * [Charts View](#industrialkitui-chartsview)
    * [State View](#industrialkitui-stateview)
* [Getting Help](#getting-help)
* [License](#license)

# Requirements <a name="requirements"></a>

The primary IndustrialKit framework codebase supports macOS, iOS/iPadOS and requires Xcode 14.1 or newer. The IndustrialKit framework has a Base SDK version of 13.0 and 16.1 respectively.

# Getting Started <a name="getting-started"></a>

* [Website](https://malkarovpark.github.io/Celadon/)
* [Documentation](https://celadon-industrial.github.io/IndustrialKit/documentation/industrialkit/)

### Installation with SPM

CareKit can be installed via SPM. Create a new Xcode project and navigate to `File > Swift Packages > Add Package Dependency`. Enter the url `https://github.com/MalkarovPark/IndustrialKit` and tap `Next`. Choose the `main` branch, and on the next screen, check off the packages as needed.

<img width="1000" alt="embedded-framework" src="https://user-images.githubusercontent.com/62340924/207657493-af8eae06-1e02-4c3d-a330-730225a19306.png">

### Robotic Complex Workspace App <a name="rcworkspace-app"></a>

The included sample app demonstrates a fully constructed IndustrialKit app: [RCWorkspace](https://github.com/MalkarovPark/Robotic-Complex-Workspace)

![rcworkspace](https://user-images.githubusercontent.com/62340924/213884632-2e7d7706-6d00-472c-b56f-4712770dfd47.png)

# IndustrialKit <a name="industrialkit"></a>

CareKit is the overarching package that provides view controllers to tie CareKitUI and CareKitStore together. When importing CareKit, CareKitUI and CareKitStore will be imported under the hood.

### Workspace Object <a name="workspace-object">

The workspace object is...

# IndustrialKitUI <a name="industrialkitui"></a>

### Cards <a name="industrialkitui-cards"></a>

Cards

### Position View <a name="industrialkitui-positionview"></a>

Position View

### Charts View <a name="industrialkitui-chartsview"></a>

Charts View

### State View <a name="industrialkitui-stateview"></a>

State View

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of a Apache 2.0 license. See the [LICENSE](LICENSE) file.
