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
    * [Workspace](#workspace)
    * [Robot](#robot)
    * [Tool](#tool)
    * [Part](#part)
    * [Connectors](#connectors)
    * [Model Controllers](#model-controllers)
    * [Functions](#functions)
    * [Extensions](#extensions)
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

### Workspace <a name="workspace">

Described by the *Workspace* class is the basis of the production complex, which consists of robots, tools, parts, controlled by a common program, presented as a sequence of blocks - algorithmic elements. Thus, this class contains four properties of an array of values of types of workspace objects *Robot*, *Tool*, *Part* and elements of the global control program *WorkspaceProgramElement*.

For arrays of objects, a standard set of functions is used, including adding, deleting, selecting, deselecting, searching by name. However, some features may not be available for some objects.

### Robot <a name="robot">

The *Robot* class describes an object of the production system that works with the representation of positions in space and is able to move its manipulator endpoint to them. The robot contains in its property an array of positional programs related to the *PositionsProgram* class.

The positional program contains an array of target positions of type *PositionPoint*. Position describes the location (*x*, *y*, *z*), rotation angles in it (*r*, *p*, *w*), type and speed of movement.

Robot can add, delete and edit its programs. There are functions for selecting and starting, pausing, resetting the program.

### Tool <a name="tool">

Other kinds of industrial equipment used in a technological complex is described by the *Tool* class. Tool can be either free-standing or attached to the endpoint of the robot manipulator.

Interaction with tools is organized by opcides and infocodes. The opcode is responsible for the executable technological operation - when a numerical value is set in the spectial property, the start of the operation associated with the code is initialized. The default value for this property is -1, which means no operation performed. When operation done, the value of the opcode is reset to this value.

Operational code sequences are contained in the programs array, the elements are the *OperationProgram* class, with a set of numeric code values with *OperationCode* class. Program management is similar to that of robots - there are functions for adding, deleting, selecting and performing.

### Part <a name="part">

Parts form the environment, such as tables, drives, safety fences, etc., and also represent objects with which the executing devices interact directly - an example is the parts assembled by robots. Described by the *Detail* class.

This class has a set of properties that describe the appearance and physical properties of the part. A part model can be obtained both parametrically - from an array of lengths and the name of a geometric primitive, and by importing from a scene file.

### Connectors <a name="connectors">

Connectors are used to connect and control industrial equipment. They are divided into two subtypes - for switching robots and tools, described by the *RobotConnector* and *ToolConnector* classes, respectively.

Connectors of individual models are inherited from these base classes and have their own specific redefinitions of functions and variables.

Connection to the equipment is performed by the connect function, disconnection - disconnect. The connection state returns by Bool property. State of the equipment returns in array of dictionaries. They contains String name of the returned property and the value of Any type. The connection parameters are set in the corresponding array of structures.

### Model Controllers <a name="model-controllers">

Used to connect to and control robot and tool models in the rendered scene. Represented by *RobotModelController* and *ToolModelController* subclasses.

Also, controllers can change the model in accordance with the specified parameters.

### Functions <a name="functions">

Functions...

### Extensions <a name="extensions">

Extensions...

# IndustrialKitUI <a name="industrialkitui"></a>

### Cards <a name="industrialkitui-cards"></a>

Used to display workspace objects and get their content from the card_info method, which is available for all objects inherited from WorkspaceObject.

Cards can be large and small, delete buttons can be round and outlineless, respectively. The large card contains an image, title, subtitle, and has a background color. A round delete button is applied to such a card, placed in the upper right corner.

The small card has no title, its right segment is marked with color. It has an outlineless delete button that is white in color and is located in the center right.

<p align="center">
  <img src="https://user-images.githubusercontent.com/62340924/217912672-89e07885-683b-4ca2-a932-054dfcfd8b99.png" />
</p>

### Position View <a name="industrialkitui-positionview"></a>

Provides editing of positions, for example for production objects in the workspace or target positions for robots.
The editing window contains two groups of three editable parameters:
   * __Location__ with editable position parameters in a rectangular coordinate system - *x*, *y*, *z*;
   * __Rotation__ with editable rotation angles at a point - *r*, *p*, *w*.

Each editable parameter consists of a field and an associated stepper. The described sequence of groups can be displayed in a vertical, horizontal or some other stack.

<p align="center">
  <img src="https://user-images.githubusercontent.com/62340924/217921506-b5ee2a5d-8bba-46a3-93cb-fefcd01abac6.png" />
</p>

### Charts View <a name="industrialkitui-chartsview"></a>

Output of an arrays of __WorkspaceObjectChart__ charts, with the ability to switch between them by segmented picker (if count of arrays of arrays is more than one). The type of chart is determined by its properties.

<p align="center">
  <img src="https://user-images.githubusercontent.com/62340924/217925809-2388c544-e15c-4118-85f8-3a145f875440.png" />
</p>

### State View <a name="industrialkitui-stateview"></a>

Output statistics by the StateItem array. If the elements are nested within each other, they will be displayed in the corresponding disclosure group. Icons are defined by the name of avaliable SF Symbols.

<p align="center">
  <img src="https://user-images.githubusercontent.com/62340924/217926978-00048eda-4dce-4397-839e-70ef15ba51be.png" />
</p>

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of a Apache 2.0 license. See the [LICENSE](LICENSE) file.
