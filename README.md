![IndustrialKit](https://github.com/user-attachments/assets/d0247453-b964-49e0-856a-929a3476090c)
<!-- ![ik_caption_image](https://github.com/user-attachments/assets/d057dc41-9f3a-4b27-be8a-5667766e97ae) -->
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
* [IndustrialKitUI](#industrialkitui)
    * [Spatial Pendant](#spatial-pendant)
    * [Controls](#controls)
    * [PositionControl](#position-control)
    * [OperationControl](#operation-control)
    * [ElementControl](#element-control)
    * [Pendant Views](#pendant-views)
    * [Registers](#registers)
    * [Output Views](#output-views)
    * [Connector View](#connector-view)
    * [Cards](#cards)
    * [BoxCard](#box-card)
    * [GlassBoxCard](#glass-box-card)
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

### ProductionObject <a name="workspace-object"></a>
`ProductionObject` defines the means of production that make up the content of a robotic complex. It provides core properties such as an identifier name, spatial data, physical body parameters, and a visual model represented by a RealityKit `Entity`.

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

Performing an operation is initiated by calling the `perform(_:)` function with an `Int` value representing an `OperationCode`.

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

An IMA program consists of `ProductionProgramElement` types:
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

### Spatial Pendant <a name="spatial-pendant"></a>

A universal pendant for `Workspace` and its constituent **means of production** — `Robot` and `Tool`.

`Spatial Pendant` represents a **unified control interface of labor**, in which the content dynamically adapts depending on the selected production object. It acts as a synthesis of multiple device-specific pendants into a single adaptive interface.

<p align="center">
  <img width="316" height="580" alt="Spatial Pendant" src="https://github.com/user-attachments/assets/0d90f6bf-3839-4c5a-a99a-91cef311db88" />
</p>

The state of the pendant is determined by the `Workspace` property:

* `selected_object` — defines the currently selected means of production
* `select_object(_:)` / `deselect_object()` — perform selection management

External control over pendant presentation is handled by `PendantController`.

### Controls <a name="controls"></a>

Manual performing of a **means of production** is carried out using controls that directly define the state of robotic devices and their representation within the `Workspace`.

### PositionControl <a name="position-control"></a>

`PositionControl` is a control element for updating the current position of a robot end-effector.

It is implemented as a virtual **ClickWheel**, enabling intuitive manual guiding of a manipulator in space.

<p align="center">
  <img width="208" height="312" alt="Position Control" src="https://github.com/user-attachments/assets/0fa41d01-3a6e-4d1a-bc42-870c3722d125" />
</p>

For fine adjustment, use `PositionView`, which can also be applied independently to edit arbitrary positions.

<p align="center">
  <img width="384" height="280" alt="Position View" src="https://github.com/user-attachments/assets/b1f44e02-2660-4a81-8e8d-3da8109f298a" />
</p>

### OperationControl <a name="operation-control"></a>

`OperationControl` enables performing a single operation on a `Tool` via a direct interaction.

In expanded form, the control provides:

* Selection of operation code
* Numeric representation of the code
* Detailed description (if available)

<p align="center">
  <img width="408" height="184" alt="Operation Control" src="https://github.com/user-attachments/assets/69f9751f-f19c-4b11-9b55-224d034edb85" />
</p>

### ElementControl <a name="element-control"></a>

`ElementControl` provides a mechanism for constructing a program element of the **Ithi Macro Assembler (IMA)**.

In expanded form, it allows flexible configuration of element parameters. During creation, the visual representation of the control evolves, reflecting the forming program structure.

A completed element can be tested by triggering performing at the `Workspace` level.

<p align="center">
  <img width="404" height="456" alt="Element Control" src="https://github.com/user-attachments/assets/40d61417-c2c1-4b1f-9c89-074d8571baad" />
</p>

### Pendant Views <a name="pendant-views"></a>

For both individual means of labor (`Robot`, `Tool`) and composite systems (`Workspace`), the framework provides **pendant content views**.

These views represent controls combined with program management in the form of a dynamic program list.

Program formation is achieved through a process analogous to **teaching**: a control defines the current state (*e.g., position or operation*), the state is tested and refined, and then recorded into a program as an element (`PositionPoint`, `OperationCode`, or `ProductionProgramElement`).

These assembled views, placed within a `FloatingView`, form a complete pendant that can be attached to a specific means of production. They collectively define the dynamic content of the `Spatial Pendant`.

<!-- <p align="center">
  <img width="712" height="512" alt="Pendant Views" src="🎆 (program list separately)" />
</p> -->

### Registers <a name="registers"></a>

Management of the **register memory** of the `Workspace` is performed using `RegisterDataView`.

This view enables:

* Editing register values
* Clearing register contents
* Adjusting the number of registers

<p align="center">
  <img width="532" height="592" alt="Registers Data View" src="https://github.com/user-attachments/assets/0e1a285e-b0d5-4b29-b7ac-5f0ec71b048c" />
</p>

Manual selection of registers for IMA program elements is provided by `RegistersSelector`.

<p align="center">
  <img width="320" height="416" alt="Registers" src="https://github.com/user-attachments/assets/8b92ed81-3ee1-4fe7-91db-80ee2e62d3b0" />
</p>

### Output Views <a name="output-views"></a>

For visual representation of **state data** of a robotic device — including charts and nested items — the framework provides dedicated views: `StateChartsView` and `StateItemsView`.

`DeviceOutputView` consolidates these data representations into a single interface and provides UI controls for managing and configuring statistical data collection parameters, including synchronization interval and scope type.

<p align="center">
  <img width="592" height="592" alt="Output Views" src="https://github.com/user-attachments/assets/b772287e-4bef-47be-8f6c-1dbb1fd1f9cb" />
</p>

This view is available for devices conforming to the `StateOutputCapable` protocol — out of the box, these are `Robot` and `Tool`.

### Connector View <a name="connector-view"></a>

A UI for managing the connection between a virtual robotic device and its physical counterpart, as well as synchronizing the digital twin.

`ConnectorView` allows switching between **simulation** and **real** modes, configuring connection parameters, and performing connection and disconnection operations.

<p align="center">
  <img width="352" height="512" alt="Connector View" src="https://github.com/user-attachments/assets/43565e4e-9565-4e7c-8a58-af77c9a88fe4" />
</p>

This view is available for classes of means of production conforming to the `DeviceTwin` protocol. For external connectors, management of the executable process is also supported.

### Cards <a name="cards"></a>

Representation of **means of production** and other objects is not limited to `Entity`.

Objects may also be expressed through a system of **cards**, reflecting their role within the production structure.

<p align="center">
  <img width="1008" height="240" alt="Cards" src="https://github.com/user-attachments/assets/82e83d28-acfc-4cee-8caa-8c206df6dd5c" />
</p>

### BoxCard <a name="box-card"></a>

`BoxCard` displays:

* An SF Symbol
* A name (and optional subtitle)

This card emphasizes the **form and primary color**, highlighting the identity of the object as a unit of production.

### GlassBoxCard <a name="glass-box-card"></a>

`GlassBoxCard` is a translucent card resembling a thick glass plate.

It can contain:

* A UI image
* A RealityKit `Entity`

This card shifts emphasis from color to **content**, reflecting the internal structure or visual model of the production object.

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of an Apache 2.0 license. See the [LICENSE](LICENSE) file.
