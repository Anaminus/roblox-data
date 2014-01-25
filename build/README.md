# Creating a build system

This file specifies the various requirements for creating a new build system.

## Structure

Source files for a build system should be located in a subdirectory within the
"**build**" folder. The name of this subdirectory should be the name of the
language the build system is written in.

This subdirectory should contain a file named "build", which is the main file
to run. The file extension may be whatever is usual for the language. The
subdirectory should also contain a file that gives instructions on how to run
the build system.

The build system should enable the user to supply a list of one or more paths,
indicating directories to output data to. Preferably, this would come in the
form of options given to the "build" file.

For example, the Lua build system makes use of options to allow directories to
be supplied.

```
build.lua <dir1> <dir2> <etc>
```

The build system should output raw data to the specified directories. It
should also be possible to specify an alternate format to output to.

For example, the Lua build system uses the `-f` option.

```
build.lua -f json <directory>
```

## Versions file

This is the "**versions**" file in the top directory. It contains a list of
ROBLOX client versions, and is the main source from which all other data is
generated.

The format is as follows:

Line endings may be of any style (LF, CRLF). The first line contains the
schematic version of the file. This looks like `schema 1`, where `1` is
the version number.

For version 1, the next line is the domain to retrieve data from. (i.e.
`roblox.com`). The lines afterward take on a tab-separated-values-like format.

Each line consists of a single record, which consist of fields, each separated
by a tab. The first line indicates the names of each field, and is not an
actual record.

Each record indicates a single Player build, and contains the following
fields, in order:

- `Date`: A unix time stamp indicating when the Player build was created.
  While it is roughly correct, it may not be reliable for a precise time.
- `PlayerHash`: The version hash of the Player build, taking the form of
  `version-<hash>`.
- `StudioHash`: The version hash of a Studio build, companion to the
  Player build. This is necessary for generating certain data.
- `PlayerVersion`: The version number of the Player build, taking the form
  of `<int>.<int>.<int>.<int>`.

## Data

The build system should support the generation of the following types of data:

- **Header file**: A central file used to retrieve files for other types of
  data.
- **API dumps**: A list of Lua API dumps for each version of the ROBLOX client.
- **ReflectionMetadata**: A list of files that contain metadata about the Lua API.

### Header file

Pretty much all of the data in the header file can be acquired from the
*versions* file.

### API dumps

The most reliable way to retrieve API dumps is to get them from builds of the
ROBLOX client. Information about fetching API dumps is available on the
[FetchAPI][fetchapi] wiki page. Player version hashes from the *versions* file
can be used to retrieve specific versions.

### ReflectionMetadata

A "**ReflectionMetadata.xml**" file is (usually) located in the top directory
of a given Player build. The same FetchAPI can be used to retrieve this file
for a particular version.

*For some versions, the ReflectionMetadata file does not exist in the Player
build.* However, it does still exist in the equivalent Studio build. The
*versions* file lists the version hash of a Studio build along side each
Player build, so this may be used to retrieve the file. This is detailed
further by the FetchAPI method.

## Output formats

The build system should support the following formats:

- **raw**: Files in their original form. The format for each type of file is
  described in [raw-format.md](../info/raw-format.md).
- **json**: Files in JSON format. The format for each type of file is
  described in [json-format.md](../info/json-format.md).

## Ensuring correct data

As an optimization, data files that already exist do not have to be generated
again. However, it may be necessary to update them if the metadata about a
given version changes.

The metadata in the *versions* file is not incremental. That is, any entry may
change at any time. Since it is inconvenient to generate all of the data every
time an update occurs, techniques should be applied so that files that haven't
changed do not get updated.

This can be done best by comparing the *versions* file against the current raw
header file.

[fetchapi]: https://github.com/Anaminus/roblox-api-tools/wiki/FetchAPI
