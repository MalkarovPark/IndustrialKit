![ik_caption_image](https://github.com/user-attachments/assets/d057dc41-9f3a-4b27-be8a-5667766e97ae)
<!-- ![IndustiralKit](https://user-images.githubusercontent.com/62340924/206910209-87495b62-2a9b-42c2-b825-85830a1d2623.png) -->
<!--- (https://user-images.githubusercontent.com/62340924/206910169-3009a0da-eeeb-475b-9983-4a2fffa58f9a.png) -->

# IndustrialKit

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) ![Xcode 15.0+](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

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
* [Ithi Macro Assembler](#ima)
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

The primary IndustrialKit framework codebase supports macOS, iOS/iPadOS, visionOS and requires Xcode 15.0 or newer. The IndustrialKit framework has a Base SDK version of 14.0, 17.0 and 1.0 respectively.

# Getting Started <a name="getting-started"></a>

* [Website](https://celadon-production-systems.carrd.co/)
* [Documentation](https://malkarovpark.github.io/documentation/industrialkit)

### Installation with SPM

CareKit can be installed via SPM. Create a new Xcode project and navigate to `File > Add Package Dependences`. Enter the url `https://github.com/MalkarovPark/IndustrialKit` and select the `main` branch. Next, select targeted project and tap `Add Package`.

<img width="1226" height="797" alt="Add Package" src="https://github.com/user-attachments/assets/290c243b-bea1-4779-b7da-033ef2e91ebe" />

### [Robotic Complex Workspace](https://github.com/MalkarovPark/Robotic-Complex-Workspace) <a name="rcworkspace-app"></a>

This sample demonstrates a fully constructed IndustrialKit app.

<p align="center">
   <img width="893" src="https://github.com/user-attachments/assets/8a75a328-b4a0-428b-aa4c-aea5ed7e5dac" />
</p>

# IndustrialKit <a name="industrialkit"></a>

IndustrialKit is the overarching package that provides all need classes, structures, functions, enums for build industrial applications.

IndustrialKitUI provides some views and modifiers for use in design and data processing tasks.

### Workspace <a name="workspace">

Described by the *Workspace* class is the basis of the production complex, which consists of robots, tools, parts and controlled by a global program, presented as a sequence of blocks – algorithmic elements. Thus, this class contains four properties of an array of values of types of workspace objects (*WorkspaceObject* class) inherited such as *Robot*, *Tool*, *Part* and elements of the global control program with type *WorkspaceProgramElement*.

For arrays of objects, a standard set of functions is used, including adding, deleting, selecting, deselecting, searching by name. However, some features may not be available for some objects.

### Robot <a name="robot">

The *Robot* class describes an object of the production system that works with the representation of positions in space and is able to move its arm (manipulator) endpoint to them. The robot contains in its property an array of positional programs related to the *PositionsProgram* class.

The positional program contains an array of target positions of type *PositionPoint*. Position describes the location (*x*, *y*, *z*), rotation angles in it (*r*, *p*, *w*), type and speed of movement.

Robot can add, delete and edit its programs. There are functions for selecting and starting, pausing, resetting the program.

### Tool <a name="tool">

Other kinds of industrial equipment used in a technological complex is described by the *Tool* class. Tool can be either free-standing or attached to the endpoint of the robot manipulator.

Interaction with tools is organized by opcides and infocodes. The opcode is responsible for the executable technological operation – when a numerical value is set in the spectial property, the start of the operation associated with the code is initialized. The default value for this property is -1, which means no operation performed. When the operation is done, the value of the opcode is reset to this value.

Operational code sequences are contained in the programs array, the elements are the *OperationProgram* class, with a set of numeric code values with *OperationCode* class. Program management is similar to that of robots – there are functions for adding, deleting, selecting and performing.

### Part <a name="part">

Parts form the environment, such as tables, drives, safety fences, etc., and also represent objects with which the executing devices interact directly – an example is the parts assembled by robots. Described by the *Part* class.

This class has a set of properties that describe the appearance and physical properties of the part. A part model can be obtained both parametrically – from an array of lengths and the name of a geometric primitive, and by importing from a scene file.

### Connectors <a name="connectors">

Connectors are used to connect and control industrial equipment. They are divided into two subtypes – for switching robots and tools, described by the *RobotConnector* and *ToolConnector* classes, respectively.

Connectors of individual models are inherited from these base classes and have their own specific redefinitions of functions and variables.

Connection to the equipment is performed by the connect function, disconnection – disconnect. The connection state returns by Bool property. State of the equipment returns in array of dictionaries. They contain String name of the returned property and the value of Any type. The connection parameters are set in the corresponding array of structures.

### Model Controllers <a name="model-controllers">

This controllers are used to connect to and control robot and tool models in the rendered scene. Represented by *RobotModelController* and *ToolModelController* subclasses.

Also, controllers can change the model in accordance with the specified parameters.

### Functions <a name="functions">

Some functions that can be used both in framework and independently by developers.

   * __mismatched_name__ – finds and updates mismatched name;

   * __origin_transform__ – transforms input position by origin rotation;

   * __apply_bit_mask__ – applies certain category bit mask int value for inputed node and all nested;

   * __pass_robot_preferences__ – pass parameters between robots, such as origin location/rotation and working space scaling;

   * __pass_positions_programs__ – pass positions programs, specified by names, between robots.

   * __element_from_struct__ – universal function, that initializes the workspace program element by corresponding file struct data.

### Extensions <a name="extensions">

Added methods for `Float` to convert radians to degrees – __to_deg__ and vice versa – __to_rad__.

Provided new methods for `SCNNode` – __remove_all_constraints__ to remove all constraints and refresh node, __remove_all_child_nodes__ to remove all child nodes, and __deep_clone__ to fully clone node with geometry, materials, and children.

Extension to provide the __pngData__ method for `UIImage` (UIKit / NSImage AppKit).

Aliases for `NSImage` and `NSColor` to use them as `UIImage` and `UIColor` respectively (AppKit).

Safe access extensions for `Array` and `Dictionary` – __safe__, __safe_float__, __safe_name__ to get/set elements or nodes without crashes.

Extensions for `Color` and `UIColor` to initialize from HEX (__init(hex:)__) and get HEX string (__to_hex__).

Encodable extensions – __json_data__ and __json_string__ for pretty-printed JSON output.

String extension – __code_correct_format__ to convert to code-safe string (spaces → underscores, digits prefixed with _).

# [Ithi Macro Assembler](https://celadon-production-systems.blogspot.com/2023/12/the-ithi-macro-assembler-ima-formalizes.html) <a name="ima"></a>

The built-in programming language of the IndustrialKit platform formalizes methods for robotic systems algoritmization and organizes unified connection and control of various robots and equipment tools.

<!-- <p align="center">
   <img width="168" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/2792a352-5574-4965-885d-cc69a27de9c2">
</p> -->

# IndustrialKitUI <a name="industrialkitui"></a>

### Object Scene View <a name="industrialkitui-objectsceneview"></a>

The simple view for SceneKit nodes. Initalises only by SCNNode and has transparent background.

It has the functionality of double tap to reset camera position for macOS.

<p align="center">
  <img width="712" height="512" alt="Object Scene View" src="https://github.com/user-attachments/assets/59ad9231-bf58-4039-9c25-ec142c7de42e" />
</p>

### Cards <a name="industrialkitui-cards"></a>

Used to display various objects. Box Card can display title, subtitle and SF Symbol. Glass Box Card can display title and subtitle with an Image or a SceneKit Node.

These cards can be used in conjunction with objects inherited from WorkspaceObject by passing them the values ​​returned by the object's *card_info* method.

<p align="center">
  <img width="992" height="224" alt="Cards" src="https://github.com/user-attachments/assets/11c19b3a-9a5a-4aa5-bc2f-3ea6cde07ec0" />
</p>

The program element card. Marked if corresponding program element is performing.

<p align="center">
  <img width="304" src="https://github.com/user-attachments/assets/f10aa961-b91e-4bd1-a501-b1ef7f3be87a" />
</p>

The register card allows edit the register value.

<p align="center">
  <img width="128" height="128" alt="RegisterCard" src="https://github.com/user-attachments/assets/4290a0bd-d123-4def-bec9-779f7d8c4357" />
</p>

### Position View <a name="industrialkitui-positionview"></a>

Provides editing of positions, for example for production objects in the workspace or target positions for robots.
The editing window contains two groups of three editable parameters:
   * __Location__ with editable position parameters in a rectangular coordinate system – *x*, *y*, *z*;
   * __Rotation__ with editable rotation angles at a point – *r*, *p*, *w*.

Each editable parameter consists of a field and an associated stepper. The described sequence of groups can be displayed in a vertical, horizontal or some other stack.

<p align="center">
  <img width="352" height="243" alt="PositionView" src="https://github.com/user-attachments/assets/04afbdf8-d7c2-4545-83ba-9d6dec1e5498" />
</p>

### Position Control <a name="industrialkitui-positioncontrol"></a>

Provides position editing with sliders. For location should set upper limits (lower limits have 0 value). Rotations are limited to the range -180º – 180º.

<p align="center">
  <img width="352" src="https://github.com/user-attachments/assets/acc3e380-79ab-485f-acbc-1c37440ab547" />
</p>

### Registers View <a name="industrialkitui-registersview"></a>

View for editing the Workspace memory of the robotic technological complex.

<p align="center">
  <img width="527" height="592" alt="RegistersView" src="https://github.com/user-attachments/assets/a91f76c8-ea91-4ca3-b97a-b622ba5f2aa7" />
</p>

### Registers Selector <a name="industrialkitui-registersselector"></a>

Pruposed for elements, registers from which they take data can be specified. This functionality is provided by the Registers Selector control. One or more registers can be selected.

<p align="center">
  <img width="600" src="https://github.com/user-attachments/assets/543859bc-e595-42dd-957a-df2413ede23f" />
</p>

### Program Elements Views <a name="industrialkitui-programelementsviews"></a>

Views for editing different types of IMA program elements – Performers, Modifiers and Logic.

<p align="center">
  <img width="600" alt="performers_views" src="https://github.com/user-attachments/assets/605e9781-6f3c-44eb-8c67-25f2ebcbf23f" />
  <img width="600" alt="modifier_views" src="https://github.com/user-attachments/assets/2387d9ce-da14-46dd-88db-2a573f4e55ce" />
  <img width="600" alt="logic_views" src="https://github.com/user-attachments/assets/85e57094-3ed2-4d71-9c25-3e9bf3f5e4bc" />
</p>

### Charts View <a name="industrialkitui-chartsview"></a>

Output of an arrays of __WorkspaceObjectChart__ charts, with the ability to switch between them by segmented picker (if count of arrays of arrays is more than one). The type of chart is determined by its properties.

<p align="center">
  <img width="752" src="https://github.com/user-attachments/assets/c77a8564-e3dd-4f67-aec8-a24e1a0af774" />
</p>

### State View <a name="industrialkitui-stateview"></a>

Output statistics by the StateItem array. If the elements are nested within each other, they will be displayed in the corresponding disclosure group. Icons are defined by the name of avaliable [SF Symbols](https://developer.apple.com/sf-symbols/).

<p align="center">
  <img width="432" height="384" alt="StateView" src="https://github.com/user-attachments/assets/22cf3a4a-b96f-4fbe-98a9-58260eb6d836" />
</p>

### Spatial Pendant <a name="industrialkitui-spendant"></a>

A universal UI control for programming and handling workspace and its constituent industrial equipment. Contents of this pendant vary depending on the specific selected object and its type – Workspace, Robot or Tool. Content of this control is blank if no suitable object is selected.

The spatial pendant allows you to set the sequence of program elements and control their performing.

<p align="center">
  <img width="500" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/1741d4b2-34aa-4679-a2a4-d94a2b301406" />
</p>

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for IndustrialKit. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of an Apache 2.0 license. See the [LICENSE](LICENSE) file.
