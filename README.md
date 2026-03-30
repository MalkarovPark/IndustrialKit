![ik_caption_image](https://github.com/user-attachments/assets/d057dc41-9f3a-4b27-be8a-5667766e97ae)
<!-- ![IndustiralKit](https://user-images.githubusercontent.com/62340924/206910209-87495b62-2a9b-42c2-b825-85830a1d2623.png) -->
<!-- (https://user-images.githubusercontent.com/62340924/206910169-3009a0da-eeeb-475b-9983-4a2fffa58f9a.png) -->

# IndustrialKit

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) ![Xcode 26.0+](https://img.shields.io/badge/Xcode-26.0%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

IndustrialKit is an open source software platform for creating applications that enable the design and control of automated means of production. The framework provides modules that can be used out of the box, or extended and customized for more targeted use cases.

<!--- * **IndustrialKit:** This is the best place to start building your app. CareKit provides view controllers that tie CareKitUI and CareKitStore together. The view controllers leverage Combine to provide synchronization between the store and the views.

* **IndustrialKitUI:** Provides the views used across the framework. The views are subclasses of UIView that are open and extensible. Properties within the views are public allowing for full control over the content.

* **Robotic Complex Workspace:** Provides the views used across the framework. The views are subclasses of UIView that are open and extensible. Properties within the views are public allowing for full control over the content. -->

# Table of Contents
* [Requirements](#requirements)
* [Getting Started](#getting-started)
    * [Robotic Complex Workspace App](#rcworkspace-app)
    * [Industrial Builder App](#ib-app)
* [IndustrialKit](#industrialkit)
    * [Workspace](#workspace)
    * [Robot](#robot)
    * [Tool](#tool)
    * [Part](#part)
    * [Device Twin](#device-twin)
    * [Model Controller](#model-controller)
    * [Connector](#connector)
    * [Device Output](#device-output)
    * [Workspace](#workspace)
    * [Modules](#modules)
    * [Functions](#functions)
    * [Extensions](#extensions)
* [IMA](#ima) <!-- * [Ithi Macro Assembler](#ima) -->
* [IndustrialKitUI](#industrialkitui)
    * [Object Scene View](#industrialkitui-objectsceneview)
    * [Cards](#industrialkitui-cards)
    * [Position View](#industrialkitui-positionview)
    * [Position Control](#industrialkitui-positioncontrol)
    * [Registers View](#industrialkitui-registersview)
    * [Registers Selector](#industrialkitui-registersselector)
    * [Program Elements Views](#industrialkitui-programelementsviews)
    * [Charts View](#industrialkitui-chartsview)
    * [State View](#industrialkitui-stateview)
    * [Spatial Pendant](#industrialkitui-spendant)
* [Getting Help](#getting-help)
* [License](#license)

# Requirements <a name="requirements"></a>

The primary IndustrialKit framework codebase supports macOS, iOS/iPadOS, visionOS. The IndustrialKit framework has a Base SDK version of 26.0.

# Getting Started <a name="getting-started"></a>

* [Website](https://celadon-production-systems.carrd.co/)
* [Documentation](https://malkarovpark.github.io/documentation/industrialkit)

### Installation with SPM

IndustrialKit can be installed via SPM. Create a new Xcode project and navigate to `File > Add Package Dependences`. Enter the url `https://github.com/MalkarovPark/IndustrialKit` and select the `main` branch. Next, select targeted project and tap `Add Package`.

<img width="1226" height="797" alt="Add Package" src="https://github.com/user-attachments/assets/290c243b-bea1-4779-b7da-033ef2e91ebe" />

### [Robotic Complex Workspace App](https://github.com/MalkarovPark/Robotic-Complex-Workspace) <a name="rcworkspace-app"></a>

This sample demonstrates a fully assembled, document-based IndustrialKit app. Each document represents a preset description of a robotic complex. The app enables you to design and simulate the complex, as well as program and control the robotic devices within it.

<p align="center">
   <img width="1012" height="696" alt="rcworkspace app" src="https://github.com/user-attachments/assets/a47c48ec-8bc2-4bd0-95f1-f8f2bcc4a5fd" />
</p>

### [Industrial Builder App](https://github.com/MalkarovPark/Industrial-Builder) <a name="ib-app"></a>
This document-based app provides tools for preparing and deploying production according to user requirements and the underlying technological basis. Each document represents a Standard Template Construction (STC), whose processing enables the implementation of production for a specific product.

# IndustrialKit

### WorkspaceObject <a name="workspace-object"></a>
`WorkspaceObject` defines the means of production that make up the content of a robotic complex. It provides core properties such as an identifier name, spatial data, physical body parameters, and a visual model represented by a RealityKit `Entity`.

Out of the box, this open class serves as the foundation for `Robot`, `Tool`, and `Part`. Developers can extend it to define additional types of production assets.

### Robot  <a name="robot"></a>
`Robot` represents an automatically controlled, reprogrammable, and versatile manipulator with configurable kinematics and degrees of freedom. A robot operates in spatial coordinates and can sequentially define the position of its end effector.

Robot programming is performed using positional programs (`PositionsProgram`), each consisting of a sequence of target positions (`PositionPoint`). Each target position defines:
- Spatial configuration — position relative to the robot’s local coordinate system (`x`, `y`, `z`) and orientation (`r`, `p`, `w`)
- Trajectory smoothing mode (`linear` or `fine`)
- Motion speed (mm/s)

Movement of the end effector to a target position is initiated by calling the `move_to(_:)` function with a `PositionPoint`.

### Tool <a name="tool"></a>
`Tool` describes other types of robotic devices that do not implement the full capabilities of a robot. A tool can function as a standalone device or as a robot end effector mounted via a mechanical interface.

Tool programming is based on operation codes. Each code corresponds to a predefined set of operations or parameters. A sequence of operation codes (`OperationCode`) forms an operation program (`OperationProgram`). Available codes are defined by `OperationCodeInfo`, which includes additional descriptions.

Execution of an operation is initiated by calling the `perform(_:)` function with an `OperationCode`.

### Part <a name="part"></a>
`Part` represents non-controllable components of a robotic complex. These include both means of production (such as tables, drives, and safety enclosures) and objects of labor, such as raw materials and workpieces that are transformed into finished products.

### Device Twin <a name="device-twin"></a>
Robots and robotic devices can be linked to their physical counterparts as digital twins. A digital twin propagates actions from the software instance to the connected device and reflects the real device state back into the virtual model.

Digital twin functionality is enabled by conforming to the `DeviceTwin` protocol. It includes a pair of components: a model controller and a connector, along with supporting properties and methods.

`DeviceMode` defines two operating modes:
- **Simulation** — the device is fully simulated by the `ModelController`
- **Real** — the physical device is controlled via a `Connector`, while the virtual model remains synchronized

### Model Controller <a name="model-controller"></a>
The `ModelController` base class manages the virtual representation of a device (`Entity`). Each device type can use its own subclass:

- `RobotModelController` continuously updates the positions of robot links based on the end effector state. Link transforms are defined by an array of `EntityPositionData`, generated by the `entity_positions` function.
- `ToolModelController` applies animations to tool components. Animation parameters are stored in `EntityAnimationData`, generated by `entity_animations` based on the current operation code. Animations are applied using `process_animations`.

### Connector <a name="connector"></a>
`Connector` enables communication between virtual and physical devices. It synchronizes device state and transmits commands such as starting or stopping operations.

A connector periodically produces state data (`RobotState` / `ToolState`), including:
- Performing state (`PerformingState`)
- Statistical output (`DeviceOutputData`)
- Model parameters (link positions or animations)

Connection parameters (`ConnectionParameter`) may include values of type `String`, `Int`, `Float`, and `Bool`.

### Device Output <a name="device-output"></a>
Devices can provide extended output beyond the performing state. This includes:
- Charts (`StateChart`)
- Nested data arrays (`StateItem`)

These are aggregated into `DeviceOutputData`.

For `Robot` and `Tool`, the current output is available via `current_device_output`, while default values are provided by `initial_device_output`.

### Workspace <a name="workspace"></a>
`Workspace` represents a unified environment for robots, tools, and parts. It stores them in separate collections and provides services for managing, selecting, adding, removing, and controlling them.

Control of the robotic complex is performed by executing programs (`ProductionProgram`) written in **Ithi Macro Assembler (IMA)**, a pendant-style language transferred from robot level—where execution units are target positions—to system level, where execution units are individual robotic devices.

An IMA program consists of `WorkspaceProgramElement` types:
- `Performers` — execute programs or operations on devices
- `Modifiers` — update register values, including device data
- `Logic` — control execution flow (branching and jumps)

The workspace includes a configurable array of `Float` registers. These registers are used to select device programs and parameters. Values are rounded when integer interpretation is required.

Registers can also be populated from `DeviceOutputData`, using indexed access across flattened `StateItem` collections.

### Extensibility and Compatibility <a name="modules"></a>
Support for diverse robot and tool configurations, as well as advanced data processing, is provided through industrial modules (`IndustrialModule`).

Module types include:
- `RobotModule` — defines a `RobotModelController`, `RobotConnector`, and a RealityKit `Entity`
- `ToolModule` — defines a `ToolModelController`, `ToolConnector`, `Entity`, and supported operation codes
- `PartModule` — defines only an `Entity`
- `ChangerModule` — defines register update logic for the workspace

Instances of `Robot`, `Tool`, `Part`, and `Changer` (alias: `ChangerProgramElement`) can be initialized either directly from a module or by name. Named modules must be registered in `internal_modules` or `external_modules`.

Modules can be:
- **Internal** — compiled into the app for maximum performance
- **External** — loaded from packages for easier updates

External modules are packaged with extensions (`.robot`, `.tool`, `.part`, `.changer`) and include:
- A module descriptor (XML)
- Component code
- A USDZ model (except for changers)

External logic (ModelController and IMA Changer) is executed in a `JSEnvironment`. External connectors are implemented as executable processes communicating via UNIX sockets.

### Extensions <a name="extensions"></a>
A collection of extensions for working with arrays and dictionaries, JSON transformation, RealityKit `Entity` manipulation, angle conversions, and color initialization from hex values.

### Functions <a name="functions"></a>
Utility functions for generating unique object names, coordinate transformations, cloning codable objects, interacting with terminal applications, and working with UNIX sockets.

# IndustrialKitUI <a name="industrialkitui"></a>

### Object Scene View <a name="industrialkitui-objectsceneview"></a>

The simple view for SceneKit nodes. Initalises only by `SCNNode` and has transparent background.

It has the functionality of double tap to reset camera position for macOS.

<p align="center">
  <img width="712" height="512" alt="Object Scene View" src="https://github.com/user-attachments/assets/59ad9231-bf58-4039-9c25-ec142c7de42e" />
</p>

### Cards <a name="industrialkitui-cards"></a>

Used to display various objects. Box Card can display title, subtitle and SF Symbol. Glass Box Card can display title and subtitle with an Image or a SceneKit Node.

These cards can be used in conjunction with objects inherited from WorkspaceObject by passing them the values ​​returned by the object's `card_info` method.

<p align="center">
  <img width="992" height="224" alt="Cards" src="https://github.com/user-attachments/assets/11c19b3a-9a5a-4aa5-bc2f-3ea6cde07ec0" />
</p>

The program element card. Marked if corresponding program element is performing.

<p align="center">
  <img width="304" src="https://github.com/user-attachments/assets/f10aa961-b91e-4bd1-a501-b1ef7f3be87a" />
</p>

The registers cards allows edit the registers values.

<p align="center">
  <img width="336" height="128" alt="RegisterCard" src="https://github.com/user-attachments/assets/d91bb81c-82db-4abd-8d05-8ba0cbc9a304" />
</p>

### Position View <a name="industrialkitui-positionview"></a>

Provides editing of positions, for example for production objects in the workspace or target positions for robots.
The editing window contains two groups of three editable parameters:
   * `Location` with editable position parameters in a rectangular coordinate system – `x`, `y`, `z`;
   * `Rotation` with editable rotation angles at a point – `r`, `p`, `w`.

Each editable parameter consists of a field and an associated stepper. The described sequence of groups can be displayed in a vertical, horizontal or some other stack.

<p align="center">
  <img width="352" height="243" alt="PositionView" src="https://github.com/user-attachments/assets/04afbdf8-d7c2-4545-83ba-9d6dec1e5498" />
</p>

### Position Control <a name="industrialkitui-positioncontrol"></a>

Provides position editing with sliders. For location should set upper limits (lower limits have 0 value). Rotations are limited to the range __-180º__ – __180º__.

<p align="center">
  <img width="352" src="https://github.com/user-attachments/assets/acc3e380-79ab-485f-acbc-1c37440ab547" />
</p>

### Registers View <a name="industrialkitui-registersview"></a>

View for editing the Workspace memory of the robotic technological complex.

<p align="center">
  <img width="527" height="592" alt="RegistersView" src="https://github.com/user-attachments/assets/888f9387-8516-4fdd-8430-de3510bc8560" />
</p>

### Registers Selector <a name="industrialkitui-registersselector"></a>

Pruposed for elements, registers from which they take data can be specified. This functionality is provided by the Registers Selector control. One or more registers can be selected.

<p align="center">
  <img width="600" src="https://github.com/user-attachments/assets/543859bc-e595-42dd-957a-df2413ede23f" />
</p>

### Program Elements Views <a name="industrialkitui-programelementsviews"></a>

Views for editing different types of IMA program elements – *Performers*, *Modifiers* and *Logic*.

<p align="center">
  <img width="600" alt="performers_views" src="https://github.com/user-attachments/assets/605e9781-6f3c-44eb-8c67-25f2ebcbf23f" />
  <img width="600" alt="modifier_views" src="https://github.com/user-attachments/assets/2387d9ce-da14-46dd-88db-2a573f4e55ce" />
  <img width="600" alt="logic_views" src="https://github.com/user-attachments/assets/ecc0cce4-7565-47f8-9028-533c00a972fc" />
</p>

### Charts View <a name="industrialkitui-chartsview"></a>

Output of an arrays of `WorkspaceObjectChart` charts, with the ability to switch between them by segmented picker (if count of arrays of arrays is more than one). The type of chart is determined by its properties.

<p align="center">
  <img width="752" src="https://github.com/user-attachments/assets/c77a8564-e3dd-4f67-aec8-a24e1a0af774" />
</p>

### State View <a name="industrialkitui-stateview"></a>

Output statistics by the StateItem array. If the elements are nested within each other, they will be displayed in the corresponding disclosure group. Icons are defined by the name of avaliable [SF Symbols](https://developer.apple.com/sf-symbols/).

<p align="center">
  <img width="432" height="384" alt="StateView" src="https://github.com/user-attachments/assets/22cf3a4a-b96f-4fbe-98a9-58260eb6d836" />
</p>

### Spatial Pendant <a name="industrialkitui-spendant"></a>

A universal UI control for programming and handling workspace and its constituent industrial equipment. Contents of this pendant vary depending on the specific selected object and its type – `Workspace`, `Robot` or `Tool`. Content of this control is blank if no suitable object is selected.

The spatial pendant allows you to set the sequence of program elements and control their performing.

<p align="center">
  <img width="500" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/1741d4b2-34aa-4679-a2a4-d94a2b301406" />
</p>

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of an Apache 2.0 license. See the [LICENSE](LICENSE) file.
