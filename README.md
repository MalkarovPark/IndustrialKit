![ik_caption_image](https://github.com/user-attachments/assets/d057dc41-9f3a-4b27-be8a-5667766e97ae)
<!-- ![IndustiralKit](https://user-images.githubusercontent.com/62340924/206910209-87495b62-2a9b-42c2-b825-85830a1d2623.png) -->
<!--- (https://user-images.githubusercontent.com/62340924/206910169-3009a0da-eeeb-475b-9983-4a2fffa58f9a.png) -->

# IndustrialKit

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) ![Xcode 14.1+](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

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

CareKit can be installed via SPM. Create a new Xcode project and navigate to `File > Swift Packages > Add Package Dependency`. Enter the url `https://github.com/MalkarovPark/IndustrialKit` and tap `Next`. Select the `main` branch, and on the next screen, check off the packages as needed.

<img width="1000" alt="embedded-framework" src="https://user-images.githubusercontent.com/62340924/207657493-af8eae06-1e02-4c3d-a330-730225a19306.png">

### [Robotic Complex Workspace App](https://github.com/MalkarovPark/Robotic-Complex-Workspace) <a name="rcworkspace-app"></a>

This sample demonstrates a fully constructed IndustrialKit app.

<p align="center">
   <img width="1228" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/b7007142-d354-46f7-97de-9ed9e4dd4d1b">
</p>

# IndustrialKit <a name="industrialkit"></a>

IndustrialKit is the overarching package that provides all need classes, structures, functions, enums for build industrial applications.

IndustrialKitUI provides some views and modifiers for use in design and data processing tasks.

### Workspace <a name="workspace">

Described by the *Workspace* class is the basis of the production complex, which consists of robots, tools, parts and controlled by a global program, presented as a sequence of blocks - algorithmic elements. Thus, this class contains four properties of an array of values of types of workspace objects (*WorkspaceObject* class) inherited such as *Robot*, *Tool*, *Part* and elements of the global control program with type *WorkspaceProgramElement*.

For arrays of objects, a standard set of functions is used, including adding, deleting, selecting, deselecting, searching by name. However, some features may not be available for some objects.

### Robot <a name="robot">

The *Robot* class describes an object of the production system that works with the representation of positions in space and is able to move its arm (manipulator) endpoint to them. The robot contains in its property an array of positional programs related to the *PositionsProgram* class.

The positional program contains an array of target positions of type *PositionPoint*. Position describes the location (*x*, *y*, *z*), rotation angles in it (*r*, *p*, *w*), type and speed of movement.

Robot can add, delete and edit its programs. There are functions for selecting and starting, pausing, resetting the program.

### Tool <a name="tool">

Other kinds of industrial equipment used in a technological complex is described by the *Tool* class. Tool can be either free-standing or attached to the endpoint of the robot manipulator.

Interaction with tools is organized by opcides and infocodes. The opcode is responsible for the executable technological operation - when a numerical value is set in the spectial property, the start of the operation associated with the code is initialized. The default value for this property is -1, which means no operation performed. When the operation is done, the value of the opcode is reset to this value.

Operational code sequences are contained in the programs array, the elements are the *OperationProgram* class, with a set of numeric code values with *OperationCode* class. Program management is similar to that of robots - there are functions for adding, deleting, selecting and performing.

### Part <a name="part">

Parts form the environment, such as tables, drives, safety fences, etc., and also represent objects with which the executing devices interact directly - an example is the parts assembled by robots. Described by the *Part* class.

This class has a set of properties that describe the appearance and physical properties of the part. A part model can be obtained both parametrically - from an array of lengths and the name of a geometric primitive, and by importing from a scene file.

### Connectors <a name="connectors">

Connectors are used to connect and control industrial equipment. They are divided into two subtypes - for switching robots and tools, described by the *RobotConnector* and *ToolConnector* classes, respectively.

Connectors of individual models are inherited from these base classes and have their own specific redefinitions of functions and variables.

Connection to the equipment is performed by the connect function, disconnection - disconnect. The connection state returns by Bool property. State of the equipment returns in array of dictionaries. They contain String name of the returned property and the value of Any type. The connection parameters are set in the corresponding array of structures.

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

Added methods for Float and uses to convert radians to degrees – __to_deg__ and vice versa – __to_rad__.

Provided new methods for __SCNNode__ – __remove_all_constraints__ to remove constraints and reset default position, __remove_all_child_nodes__ to remove all child nodes from this node.

Extension for provide the __pngData__ missed method for __UIImage__ (UIKit).

Aliases for __NSImage__, __NSColor__ to use them as __UIImage__ and __UIColor__ respectively (AppKit).

# [Ithi Macro Assembler](https://celadon-production-systems.blogspot.com/2023/12/the-ithi-macro-assembler-ima-formalizes.html) <a name="ima"></a>

The built-in programming language of the IndustrialKit platform formalizes methods for robotic systems algoritmization and organizes unified connection and control of various robots and equipment tools.

<p align="center">
   <img width="168" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/2792a352-5574-4965-885d-cc69a27de9c2">
</p>

# IndustrialKitUI <a name="industrialkitui"></a>

### Object Scene View <a name="industrialkitui-objectsceneview"></a>

The simple view for SceneKit nodes. Initalises only by SCNNode and has transparent background.

It has the functionality of double tap to reset camera position for macOS.

<p align="center">
  <img width="712" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/af8223de-82e1-4ab7-a194-16f6ce721478" />
</p>

### Cards <a name="industrialkitui-cards"></a>

Used to display various objects. Can display a description with an image or a SceneKit scene model.

Can be used in conjunction with objects inherited from WorkspaceObject. The card initializer is passed the values returned by the object's *card_info* method.

The small card has no subtitle.

<p align="center">
  <img width="672" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/f4335808-4442-4636-99a7-6a3f669de7a0" />
</p>

The program element card. Marked if corresponding program element is performing.

<p align="center">
  <img width="304" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/ebc9cc09-01a1-44d3-8e20-94f2d54031c2" />
</p>

The register card allows edit the register value.

<p align="center">
  <img width="128" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/4bae3f72-254f-47f8-9589-401f9df3620a" />
</p>

### Position View <a name="industrialkitui-positionview"></a>

Provides editing of positions, for example for production objects in the workspace or target positions for robots.
The editing window contains two groups of three editable parameters:
   * __Location__ with editable position parameters in a rectangular coordinate system - *x*, *y*, *z*;
   * __Rotation__ with editable rotation angles at a point - *r*, *p*, *w*.

Each editable parameter consists of a field and an associated stepper. The described sequence of groups can be displayed in a vertical, horizontal or some other stack.

<p align="center">
  <img width="288" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/4f516989-ce57-4c0a-b519-4e90bd320e00" />
</p>

### Position Control <a name="industrialkitui-positioncontrol"></a>

Provides position editing with sliders. For location should set upper limits (lower limits have 0 value). Rotations are limited to the range -180º – 180º.

<p align="center">
  <img width="256" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/078ff7dc-6468-4d1d-b536-e1432979fedd" />
</p>

### Registers View <a name="industrialkitui-registersview"></a>

Pruposed for elements, registers from which they take data can be specified. This functionality is provided by the Registers Selector control. One or more registers can be selected.

<p align="center">
  <img width="468" alt="registers_view" src="https://github.com/user-attachments/assets/b2c2f15e-71f8-40b3-930c-8c12b247b00f" />
</p>

### Registers Selector <a name="industrialkitui-registersselector"></a>

Pruposed for elements, registers from which they take data can be specified. This functionality is provided by the Registers Selector control. One or more registers can be selected.

<p align="center">
  <img width="680" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/0d600fa1-6a99-4129-9f5d-ab5a3572629a" />
</p>

### Program Elements Views <a name="industrialkitui-programelementsviews"></a>

Views for editing different types of IMA software elements – Performers, Modifiers and Logic.

<p align="center">
  <img width="600" alt="performers_views" src="https://github.com/user-attachments/assets/be0b7cac-b2d3-4fcf-a92d-39abc78f7968" />
  <img width="600" alt="modifier_views" src="https://github.com/user-attachments/assets/93b0fe5c-91cc-49f0-a0b3-538fd7d3c980" />
  <img width="600" alt="logic_views" src="https://github.com/user-attachments/assets/6d970534-6006-4740-9114-a7b44d9407d0" />
</p>

### Charts View <a name="industrialkitui-chartsview"></a>

Output of an arrays of __WorkspaceObjectChart__ charts, with the ability to switch between them by segmented picker (if count of arrays of arrays is more than one). The type of chart is determined by its properties.

<p align="center">
  <img width="752" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/c869219d-4d1b-4c73-b1b8-bcd5ae27833d" />
</p>

### State View <a name="industrialkitui-stateview"></a>

Output statistics by the StateItem array. If the elements are nested within each other, they will be displayed in the corresponding disclosure group. Icons are defined by the name of avaliable [SF Symbols](https://developer.apple.com/sf-symbols/).

<p align="center">
  <img width="432" src="https://github.com/MalkarovPark/IndustrialKit/assets/62340924/106bb432-846d-494a-aa39-09ab6cfbcaba" />
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
