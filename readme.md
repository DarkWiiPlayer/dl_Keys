dl_Keys
===

What is it?
---
dl_Keys is a simple webserver based on lapis that serves files. The catch is that to download a file one needs to provide a valid download key that applies to that file.

Each download key applies to a single directory and all it's subdirectories or to a single file. The user can specify at what date the key becomes active, when it expires and how many times it can be used.

The user can add as many keys as they like.

How does it work?
---
Whenever a user requests a file, the server searches for the provided key in a list, checks if that key is valid (not expired) and increases its click count by one before actually serving the file. If no key is provided, the key cannot be found, is invalid, or does nor apply to the requested file, the user gets a 403 error.

Is it safe? is it encrypted?
---
The server does not encrypt any of its stored date. The keys are stored in the same directory as the data, so if the key-file is compromised, so is the data anyway. The server is mostly intended for personal use. Before it could ever be used for commercial use it would need quite a lot of security and performance improvements.

Key storage
---
In the current implementation the server stores its keys in a local file. Access to the keys is handled by a separate .lua in the *keys* subdirectory. If needed, other implementations of the same interface can be added to this subdirectory to allow the server to store its keys in a database.

Extensibility
---
Lapis takes care of most of the complex stuff, which means the implementation has very few actual lines of code, making it easy to add features or change existing ones.
