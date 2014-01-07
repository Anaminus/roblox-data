# Raw Format

## Header

Line endings may be of any style (unix, dos). The first line contains the
schematic version of the file. This looks like `schema 1`, where `1` is
the version number.

For version 1, the next line is the domain to retrieve data from. (i.e.
`roblox.com`). The lines afterward take on a tab-separated-values-like
format. Each line consists of a single record, which consist of fields,
each separated by a tab. Each record indicates a single Player build, and
contains the following fields, in order:

- `Timestamp`: A unix time stamp indicating when the Player build was
  created. Note that this number may not be reliable as a precise date.
- `PlayerHash`: The version hash of the Player build, taking the form of
  `version-<hash>`.
- `StudioHash`: The version hash of a Studio build, companion to the
  Player build. Necessary for generating certain data.
- `PlayerVersion`: The version number of the Player build, taking the form
  of `<int>.<int>.<int>.<int>`.
