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
* [IndustrialUI](#carekitui)
    * [SwiftUI](#industrialkitui-swiftui)
* [Getting Help](#getting-help)
* [License](#license)

# Requirements <a name="requirements"></a>

The primary IndustrialKit framework codebase supports macOS, iOS/iPadOS and requires Xcode 14.1 or newer. The IndustrialKit framework has a Base SDK version of 13.0 and 16.1 respectively.

# Getting Started <a name="getting-started"></a>

* [Website](https://www.celadon.org)
* [Documentation](https://celadon-industrial.github.io/IndustrialKit/documentation/carekit/)

### Installation (Option One): SPM

CareKit can be installed via SPM. Create a new Xcode project and navigate to `File > Swift Packages > Add Package Dependency`. Enter the url `https://github.com/celadon-industrial/IndustrialKit` and tap `Next`. Choose the `main` branch, and on the next screen, check off the packages as needed.

### Installation (Option Two): Embedded Framework

Download the project source code and drag in IndustrialKit.xcodeproj, IndustrialKitUI.xcodeproj as needed. Then, embed the framework as a dynamic framework in your app, by adding it to the Embedded Binaries section of the General pane for your target as shown in the figure below.

<img width="1000" alt="embedded-framework" src="https://upload.wikimedia.org/wikipedia/commons/8/86/Ornament_met_bloemen_en_bladeren_Oeuvre_de_Juste_Aurele_Meissonnier_%28serietitel%29%2C_RP-P-1998-314.jpg">

### Robotic Complex Workspace App <a name="rcworkspace-app"></a>

The included sample app demonstrates a fully constructed IndustrialKit app: [OCKCatalog](https://github.com/carekit-apple/CareKitCatalog)

![ockcatalog](https://upload.wikimedia.org/wikipedia/commons/8/86/Ornament_met_bloemen_en_bladeren_Oeuvre_de_Juste_Aurele_Meissonnier_%28serietitel%29%2C_RP-P-1998-314.jpg)

# IndustrialKit <a name="industrialkit"></a>

CareKit is the overarching package that provides view controllers to tie CareKitUI and CareKitStore together. When importing CareKit, CareKitUI and CareKitStore will be imported under the hood.

### Workspace Object <a name="workspace-object">

The workspace object is...

# IndustrialKitUI <a name="industrialkitui-swiftui"></a>

### SwiftUI <a name="industrialkitui-swiftui"></a>

A SwiftUI API is currently available for the view...

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of a Apache 2.0 license. See the [LICENSE](LICENSE) file.
