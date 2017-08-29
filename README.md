### This project is archived! Pull requests will be ignored. Dependencies on this project should be avoided. Please fork this project if you wish to continue development.
----

# ROBLOX Data

This repository contains systems for generating data about the
[ROBLOX][roblox] client.

**This project is in beta. Do not use for any serious work unless you want it
to break!**

## Contents

- `README.md`

	This file!

	Usually subdirectories will also have a README file, which contains more
	detailed information related to that subdirectory.

- `versions`

	A file containing a list of ROBLOX client versions. This file is the main
	source from which all data is generated.

- `build`

	A folder that contains systems for generating data, in various languages.
	Each subdirectory holds files for a single programming language.

- `info`

	Contains information about each format, such as schematics.


## Data

Generated data is available in multiple formats, which are contained in
separate folders. However, the structure of each folder is very much the same.
For the purposes of this documentation, the "root" folder will refer to the
folder that contains a given format. Also note that while file names will be
mostly the same, file extensions will depend on the format.

Generated data comes in 3 parts:

- Lua API dumps
- ReflectionMetadata files
- A "header" file

The API dumps are files generated by the ROBLOX client, which reveal
information about ROBLOX's Lua API. This information is held in the `api`
folder, a subdirectory of the root folder. Each file in this folder is a dump
file for a single Player build. The name of each file is the version hash of
the build it was created from.

ReflectionMetadata is a file used to specify metadata for parts of the Lua
API. This data is contained under the `rmd` folder, in the root folder.
Similar to the API dumps, this folder contains ReflectionMetadata files for
each Player build, with the version hash used as the name.

Each folder also has a file named `latest`, which contains data for the most
recent build.

The header file, located in the root folder, is named `header`. It contains a
list of each Player build, as well as metadata related to each build. Such
metadata includes:

- the version hash of the Player build
- the version number of the Player build
- when the build was created
- the version hash of a Studio build, companion to the Player build

The idea of the header file is to associate other information with a version
hash, so that this information can be used to retrieve data.


## Formats

Generated data is contained in a "top" directory, which contains each format.
Each subdirectory is the "root" folder described in the previous section, for
each format.

Currently, 2 formats are supported:

- `raw`: Data as it appears in its raw form. That is, it hasn't been
  normalized into one specific format, and may be unstable. This is used by
  the build system to convert the data into other supported formats.
- `json`: Data in JSON format.

The `info` folder contains files which have more specific information about
each format, such as schematics.

Examples:

	Get header file in JSON:
	<top>/json/header.json

	Get API dump of first build in JSON:
	<top>/json/api/version-55bff205328042f4.json

	Get ReflectionMetadata of latest build in JSON:
	<top>/json/rmd/latest.json

	Get API dump of latest in raw format:
	<top>/raw/api/latest.txt


## Generating

The `build` folder contains systems for generating the data. Each subdirectory
contains a build system for a specific language. Each of these contains a
README file, which you may consult for instructions on how to run the build
system for that language.

Generally, generating data will require running a `build` file, which will
involve supplying one or more "top" directories as options.

Note that generating data requires downloading many files from the ROBLOX
website, each of which are megabytes in size. However, these files are cached
in the temporary directory. Once a version is successfully downloaded, it will
not need to be downloaded again, as long as the temporary copy exists. Also,
since most of the data is static, most files will only be generated once.

The following languages are available:

- [Lua instructions](build/lua/README.md)


[roblox]: http://corp.roblox.com/
